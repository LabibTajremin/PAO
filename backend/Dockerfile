# syntax=docker/dockerfile:1.7
# Multi-stage build: the API and worker binaries in one distroless, non-root image.

FROM golang:1.27-bookworm AS build
WORKDIR /src
COPY go.mod go.sum* ./
# An optional extra CA bundle (build secret "extra_ca") lets builds work behind a
# TLS-intercepting proxy; it never reaches the final image.
RUN --mount=type=secret,id=extra_ca,required=false --mount=type=cache,target=/go/pkg/mod \
    if [ -s /run/secrets/extra_ca ]; then export SSL_CERT_FILE=/run/secrets/extra_ca; fi; go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/ ./cmd/api ./cmd/worker ./cmd/migrate

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=build /out/ /app/
COPY migrations /app/migrations
COPY seed /app/seed
USER nonroot:nonroot
EXPOSE 8080 9090
ENTRYPOINT ["/app/api"]
