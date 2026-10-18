# syntax=docker/dockerfile:1.7
# One image, three entry points (/app/api, /app/worker, /app/migrate), like the NestJS image,
# so docker-compose.yml switches backends by changing only the build context (task 8).
# Build from backend-dotnet/: docker build -f docker/Dockerfile .

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY global.json Directory.Build.props Directory.Packages.props .editorconfig ./
COPY PAO.EF ./PAO.EF
COPY PAO.Lib ./PAO.Lib
COPY PAO.Infrastructure ./PAO.Infrastructure
COPY PAO.BackgroundJobs ./PAO.BackgroundJobs
COPY PAO.Core ./PAO.Core
COPY PAO.Worker ./PAO.Worker
COPY PAO.Migrator ./PAO.Migrator
# An optional extra CA bundle (build secret "extra_ca") lets restores work behind a
# TLS-intercepting proxy; it never reaches the final image.
RUN --mount=type=secret,id=extra_ca,required=false \
    if [ -s /run/secrets/extra_ca ]; then \
      cp /run/secrets/extra_ca /usr/local/share/ca-certificates/extra.crt && update-ca-certificates; \
    fi; \
    for p in PAO.Core PAO.Worker PAO.Migrator; do \
      dotnet publish "$p/$p.csproj" -c Release -o /out --no-self-contained -p:UseAppHost=false || exit 1; \
    done

FROM mcr.microsoft.com/dotnet/aspnet:10.0
ENV PAO_HOME=/app DOTNET_CLI_TELEMETRY_OPTOUT=1
WORKDIR /app
COPY --from=build /out ./
COPY Config ./Config
COPY ["DB Changes", "./DB Changes"]
COPY Seed ./Seed
COPY --chmod=755 docker/api docker/worker docker/migrate ./
RUN mkdir -p /app/Logs && chown app /app/Logs
USER app
EXPOSE 8080 9090
ENTRYPOINT ["/app/api"]
