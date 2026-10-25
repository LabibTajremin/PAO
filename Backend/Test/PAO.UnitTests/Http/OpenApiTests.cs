using System.Text;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http.OpenApi;

namespace PAO.UnitTests.Http;

public sealed class OpenApiTests
{
    internal const string Yaml = """
        openapi: 3.1.0
        paths:
          /v1/things:
            post:
              operationId: createThing
              x-permission: thing:create
              parameters:
                - name: Idempotency-Key
                  in: header
                  required: true
                  schema: { type: string, maxLength: 64 }
                - $ref: '#/components/parameters/Limit'
                - name: tags
                  in: query
                  schema: { type: array, items: { type: integer } }
                - name: flag
                  in: query
                  schema: { type: boolean }
                - name: session
                  in: cookie
                  schema: { type: string }
              requestBody:
                required: true
                content:
                  application/json:
                    schema: { $ref: '#/components/schemas/Thing' }
            get:
              operationId: listThings
              x-permission: public
              security: []
              requestBody:
                content:
                  application/json:
                    schema: { type: object }
          /v1/things/{id}:
            parameters:
              - name: id
                in: path
                required: true
                schema: { type: string, format: uuid }
            get:
              x-permission: authenticated
            delete:
              requestBody:
                content:
                  text/plain: {}
          /v1/things/latest:
            get:
              operationId: latestThing
              x-permission: "public"
        components:
          parameters:
            Limit:
              name: limit
              in: query
              schema: { type: integer, minimum: 1, maximum: 100 }
          schemas:
            Thing:
              type: object
              required: [name]
              additionalProperties: false
              properties:
                name: { type: string, minLength: 2, maxLength: 5, pattern: '^[a-z]+$' }
                count: { type: [integer, "null"], minimum: 0 }
                price: { type: number, maximum: 9.5 }
                kind: { type: string, enum: [a, b] }
                when: { type: string, format: date-time }
                labels: { type: array, minItems: 1, maxItems: 2, items: { type: string } }
                extra: { type: object, additionalProperties: { type: integer } }
                note: ~
                quoted: 'true'
                big: 1.5e3
        """;

    internal static SpecDocument Document()
    {
        var path = Path.GetTempFileName();
        File.WriteAllText(path, Yaml);
        var doc = SpecDocument.Load(path);
        File.Delete(path);
        return doc;
    }

    [Fact]
    public void Loads_yaml_with_typed_scalars_and_resolves_refs()
    {
        var doc = Document();
        var thing = doc.Resolve(JsonNode.Parse("""{"$ref":"#/components/schemas/Thing"}"""))!;
        Assert.Equal(5, (int)thing["properties"]!["name"]!["maxLength"]!);
        Assert.Null(thing["properties"]!["note"]);
        Assert.Equal("true", (string)thing["properties"]!["quoted"]!);
        Assert.Equal(1500d, (double)thing["properties"]!["big"]!);
        Assert.Throws<InvalidDataException>(() => doc.Resolve(JsonNode.Parse("""{"$ref":"other.yaml#/x"}""")));
    }

    [Fact]
    public void Matches_literal_paths_before_templates_and_reports_misses()
    {
        var routes = new SpecRoutes(Document());
        Assert.Equal("latestThing", routes.Match("GET", "/v1/things/latest").Match!.Operation.Id);
        var byId = routes.Match("GET", "/v1/things/a%20b").Match!;
        Assert.Equal("a b", byId.PathParameters["id"]);
        Assert.Equal("get /v1/things/{id}", byId.Operation.Id);
        Assert.Equal("authenticated", byId.Operation.Permission);
        Assert.Equal(RouteMiss.MethodNotAllowed, routes.Match("PUT", "/v1/things").Miss);
        Assert.Equal(RouteMiss.NotFound, routes.Match("GET", "/v2/x").Miss);
        var create = routes.Match("POST", "/v1/things").Match!.Operation;
        Assert.True(create.Idempotent);
        Assert.False(create.Public);
        Assert.True(routes.Match("GET", "/v1/things").Match!.Operation.Public);
        Assert.Equal(5, routes.Operations.Count());
    }

    [Fact]
    public void Undeclared_path_parameters_break_the_spec()
    {
        var path = Path.GetTempFileName();
        File.WriteAllText(path, "paths:\n  /v1/x/{id}:\n    get: {}\n");
        var error = Assert.Throws<InvalidDataException>(() => new SpecRoutes(SpecDocument.Load(path)));
        Assert.Contains("path parameter id is not declared", error.Message, StringComparison.Ordinal);
        File.WriteAllText(path, "- a\n");
        Assert.Throws<InvalidDataException>(() => SpecDocument.Load(path));
        File.Delete(path);
    }

    [Fact]
    public void The_bundled_contract_loads_with_every_operation_permissioned()
    {
        var routes = new SpecRoutes(SpecDocument.Load(PaoPaths.Resolve(AppContext.BaseDirectory, null).Spec));
        Assert.Equal(129, routes.Operations.Count());
        Assert.All(routes.Operations, op => Assert.NotNull(op.Permission));
    }

    [Fact]
    public void Customer_answers_never_carry_verification_documents()
    {
        var doc = SpecDocument.Load(PaoPaths.Resolve(AppContext.BaseDirectory, null).Spec);
        var names = new HashSet<string>(StringComparer.Ordinal);
        var seen = new HashSet<JsonNode>(ReferenceEqualityComparer.Instance);
        var operations = doc.Root["paths"]!.AsObject()
            .Where(p => p.Key.StartsWith("/v1/customer", StringComparison.Ordinal))
            .SelectMany(p => p.Value!.AsObject().Select(o => o.Value).OfType<JsonObject>());
        foreach (var op in operations)
        {
            PropertyNames(doc, op["responses"], names, seen);
        }
        Assert.Contains("items", names);
        string[] banned = ["nid", "document", "documents", "selfie", "police", "clearance"];
        Assert.DoesNotContain(names, n => Regex.Split(n, "(?<=[a-z0-9])(?=[A-Z])|_").Any(w => banned.Contains(w.ToLowerInvariant())));
    }

    private static void PropertyNames(SpecDocument doc, JsonNode? node, HashSet<string> names, HashSet<JsonNode> seen)
    {
        var resolved = doc.Resolve(node);
        if (resolved is null || !seen.Add(resolved))
        {
            return;
        }
        if (resolved is JsonObject { } o && o["properties"] is JsonObject properties)
        {
            names.UnionWith(properties.Select(p => p.Key));
        }
        IEnumerable<JsonNode?> children = resolved switch
        {
            JsonObject obj => obj.Select(c => c.Value),
            JsonArray array => array,
            _ => [],
        };
        foreach (var child in children)
        {
            PropertyNames(doc, child, names, seen);
        }
    }

    [Theory]
    [InlineData("""{"name":"ab"}""", null)]
    [InlineData("""{"name":"ab","count":null,"price":9,"kind":"a","when":"2026-10-17T10:00:00Z","labels":["x"],"extra":{"n":1}}""", null)]
    [InlineData("""[]""", "body must be object")]
    [InlineData("""{}""", "body must have required property 'name'")]
    [InlineData("""{"name":"ab","zzz":1}""", "body must NOT have additional properties")]
    [InlineData("""{"name":"a"}""", "body/name must NOT have fewer than 2 characters")]
    [InlineData("""{"name":"abcdef"}""", "body/name must NOT have more than 5 characters")]
    [InlineData("""{"name":"AB"}""", "body/name must match pattern \"^[a-z]+$\"")]
    [InlineData("""{"name":"ab","count":1.5}""", "body/count must be integer,null")]
    [InlineData("""{"name":"ab","count":-1}""", "body/count must be >= 0")]
    [InlineData("""{"name":"ab","price":10}""", "body/price must be <= 9.5")]
    [InlineData("""{"name":"ab","price":true}""", "body/price must be number")]
    [InlineData("""{"name":"ab","kind":"c"}""", "body/kind must be equal to one of the allowed values")]
    [InlineData("""{"name":"ab","when":"2026-10-17"}""", "body/when must match format \"date-time\"")]
    [InlineData("""{"name":"ab","labels":[]}""", "body/labels must NOT have fewer than 1 items")]
    [InlineData("""{"name":"ab","labels":["a","b","c"]}""", "body/labels must NOT have more than 2 items")]
    [InlineData("""{"name":"ab","labels":[1]}""", "body/labels/0 must be string")]
    [InlineData("""{"name":"ab","extra":{"n":"x"}}""", "body/extra/n must be integer")]
    public void Validates_bodies_in_ajv_words(string json, string? error)
    {
        var doc = Document();
        var validator = new SchemaValidator(doc);
        Assert.Equal(error, validator.Validate(JsonNode.Parse(json), JsonNode.Parse("""{"$ref":"#/components/schemas/Thing"}"""), "body"));
        Assert.Null(validator.Validate(JsonNode.Parse(json), null, "body"));
    }

    [Fact]
    public void Names_json_kinds()
    {
        Assert.Equal("null", SchemaValidator.KindOf(null));
        Assert.Equal("null", SchemaValidator.KindOf(JsonNode.Parse("null")));
        Assert.Equal("boolean", SchemaValidator.KindOf(JsonNode.Parse("false")));
        Assert.Equal("object", SchemaValidator.KindOf(JsonNode.Parse("{}")));
    }

    [Theory]
    [InlineData("uuid", "0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c", true)]
    [InlineData("uuid", "nope", false)]
    [InlineData("date", "2026-02-28", true)]
    [InlineData("date", "2026-02-30", false)]
    [InlineData("date-time", "2026-10-17T10:00:00.123+06:00", true)]
    [InlineData("date-time", "2026-10-17 10:00:00z", true)]
    [InlineData("date-time", "2026-10-17T24:00:00Z", false)]
    [InlineData("date-time", "2026-10-17T10:60:00Z", false)]
    [InlineData("date-time", "2026-10-17T10:00:61Z", false)]
    [InlineData("date-time", "2026-10-17T10:00:00", false)]
    [InlineData("date-time", "2026-13-17T10:00:00Z", false)]
    [InlineData("email", "ops@pao.test", true)]
    [InlineData("email", "ops@", false)]
    [InlineData("int64", "anything", true)]
    public void Checks_string_formats_like_ajv_formats(string format, string text, bool valid)
    {
        Assert.Equal(valid, Formats.IsValid(format, text));
    }

    private static RequestParts Parts(
        string? body = """{"name":"ab"}""", string contentType = "application/json", Dictionary<string, string[]>? query = null,
        Dictionary<string, string[]>? headers = null, string? bodyError = null) => new()
        {
            Path = new Dictionary<string, string>(),
            Query = query ?? new Dictionary<string, string[]>(),
            Headers = headers ?? new Dictionary<string, string[]> { ["idempotency-key"] = ["k"] },
            Cookies = new Dictionary<string, string[]> { ["session"] = ["s"], ["other"] = ["o"] },
            ContentType = contentType,
            RawBody = body is null ? null : Encoding.UTF8.GetBytes(body),
            BodyError = bodyError,
            Body = body is null ? null : JsonNode.Parse(body),
        };

    [Fact]
    public void Validates_parameters_after_coercing_them()
    {
        var doc = Document();
        var validator = new RequestValidator(doc);
        var routes = new SpecRoutes(doc);
        var create = routes.Match("POST", "/v1/things").Match!.Operation;
        Assert.Null(validator.Check(create, Parts(query: new() { ["limit"] = ["5"], ["tags"] = ["1", "2"], ["flag"] = ["true"], ["unknown"] = ["x"] })));
        Assert.Null(validator.Check(create, Parts()));
        Assert.Equal("query/limit must be <= 100", validator.Check(create, Parts(query: new() { ["limit"] = ["500"] })));
        Assert.Equal("query/limit must be integer", validator.Check(create, Parts(query: new() { ["limit"] = ["x"] })));
        Assert.Equal("query/limit must be integer", validator.Check(create, Parts(query: new() { ["limit"] = ["1", "2"] })));
        Assert.Equal("query/tags/0 must be integer", validator.Check(create, Parts(query: new() { ["tags"] = ["a"] })));
        Assert.Equal("query/flag must be boolean", validator.Check(create, Parts(query: new() { ["flag"] = ["yes"] })));
        Assert.Equal("headers must have required property 'idempotency-key'", validator.Check(create, Parts(headers: [])));
        var byId = routes.Match("GET", "/v1/things/x").Match!;
        Assert.Equal("path/id must match format \"uuid\"", validator.Check(byId.Operation, Parts() with { Path = byId.PathParameters }));
    }

    [Fact]
    public void Validates_bodies_with_the_contract_reasons()
    {
        var doc = Document();
        var validator = new RequestValidator(doc);
        var routes = new SpecRoutes(doc);
        var create = routes.Match("POST", "/v1/things").Match!.Operation;
        var list = routes.Match("GET", "/v1/things").Match!.Operation;
        Assert.Equal("request body has an error: request body too large", validator.Check(create, Parts(bodyError: "request body too large")));
        Assert.Equal("request body has an error: value is required but missing", validator.Check(create, Parts(body: null)));
        Assert.Null(validator.Check(list, Parts(body: null)));
        Assert.Equal("header Content-Type has unexpected value: \"text/plain\"", validator.Check(create, Parts(contentType: "text/plain")));
        Assert.Equal("header Content-Type has unexpected value: \"\"", validator.Check(create, Parts() with { ContentType = null }));
        Assert.Equal("body must have required property 'name'", validator.Check(create, Parts(body: "{}")));
        Assert.Null(validator.Check(routes.Match("DELETE", "/v1/things/0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c").Match!.Operation, Parts() with { Path = new Dictionary<string, string> { ["id"] = "0190a5b2-7c1d-7e3f-8a9b-0c1d2e3f4a5c" } }));
    }
}
