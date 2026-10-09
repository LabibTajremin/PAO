# syntax=docker/dockerfile:1.7
# Multi-stage build: the API and worker binaries in one distroless, non-root image.

FROM golang:1.27-bookworm AS build
WORKDIR /src
COPY go.mod go.sum* ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/ ./cmd/...

FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=build /out/ /app/
COPY migrations /app/migrations
COPY seed /app/seed
USER nonroot:nonroot
EXPOSE 8080 9090
ENTRYPOINT ["/app/api"]
