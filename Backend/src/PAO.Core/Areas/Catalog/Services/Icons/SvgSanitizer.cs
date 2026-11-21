using System.Text;
using System.Xml;
using System.Xml.Linq;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services.Icons;

/// <summary>
/// Keeps only the drawing parts of an uploaded SVG (ADR-0039): an allow-list of shape,
/// grouping and gradient elements and their presentation attributes. Scripts, event handlers,
/// `foreignObject`, images, external references and CSS `url()` to anything but a local
/// fragment are dropped, as is everything in an editor's own namespace.
/// </summary>
public static class SvgSanitizer
{
    private static readonly XNamespace Svg = "http://www.w3.org/2000/svg";
    private static readonly XNamespace XLink = "http://www.w3.org/1999/xlink";

    private static readonly HashSet<string> Elements =
    [
        "svg", "g", "defs", "title", "desc", "symbol", "use", "path", "circle", "ellipse", "line",
        "polyline", "polygon", "rect", "linearGradient", "radialGradient", "stop", "clipPath", "mask",
    ];

    private static readonly HashSet<string> Attributes =
    [
        "id", "class", "d", "x", "y", "x1", "y1", "x2", "y2", "cx", "cy", "r", "rx", "ry", "width", "height",
        "points", "viewBox", "preserveAspectRatio", "transform", "fill", "fill-rule", "fill-opacity", "stroke",
        "stroke-width", "stroke-linecap", "stroke-linejoin", "stroke-miterlimit", "stroke-dasharray",
        "stroke-dashoffset", "stroke-opacity", "opacity", "clip-path", "clip-rule", "mask", "style", "offset",
        "stop-color", "stop-opacity", "gradientUnits", "gradientTransform", "fx", "fy", "href", "version",
    ];

    /// <summary>The sanitised SVG as UTF-8; throws `catalog.icon_unreadable` for anything but a well-formed SVG.</summary>
    public static byte[] Clean(byte[] file)
    {
        var root = Parse(file).Root;
        if (root is null || root.Name != Svg + "svg")
        {
            throw new DomainException(CatalogReasons.IconUnreadable);
        }
        CleanElement(root);
        var output = new StringBuilder();
        using (var writer = XmlWriter.Create(output, new XmlWriterSettings { OmitXmlDeclaration = true }))
        {
            root.WriteTo(writer);
        }
        return Encoding.UTF8.GetBytes(output.ToString());
    }

    private static XDocument Parse(byte[] file)
    {
        // No DTDs and no resolver: entity expansion and external fetches are impossible.
        var settings = new XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null, IgnoreComments = true, IgnoreProcessingInstructions = true };
        try
        {
            using var reader = XmlReader.Create(new MemoryStream(file), settings);
            return XDocument.Load(reader);
        }
        catch (XmlException error)
        {
            throw new DomainException(CatalogReasons.IconUnreadable, error);
        }
    }

    private static void CleanElement(XElement element)
    {
        element.Elements().Where(e => e.Name.Namespace != Svg || !Elements.Contains(e.Name.LocalName)).Remove();
        element.Attributes().Where(a => !Keep(a)).Remove();
        foreach (var child in element.Elements())
        {
            CleanElement(child);
        }
    }

    private static bool Keep(XAttribute attribute)
    {
        if (attribute.IsNamespaceDeclaration)
        {
            return attribute.Value == Svg.NamespaceName || attribute.Value == XLink.NamespaceName;
        }
        var name = attribute.Name;
        var known = (name.Namespace == XNamespace.None && Attributes.Contains(name.LocalName))
            || name == XLink + "href";
        return known && SafeValue(name.LocalName, attribute.Value);
    }

    private static bool SafeValue(string name, string value)
    {
        if (name == "href")
        {
            return value.StartsWith('#');
        }
        var lower = value.ToLowerInvariant();
        if (lower.Contains("javascript:") || lower.Contains("expression(") || lower.Contains("@import"))
        {
            return false;
        }
        // Only references to a gradient or clip path inside the file; never a network fetch.
        return !lower.Replace(" ", string.Empty).Split("url(").Skip(1).Any(rest => !rest.StartsWith('#') && !rest.StartsWith("'#") && !rest.StartsWith("\"#"));
    }
}
