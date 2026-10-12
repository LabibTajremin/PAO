# syntax=docker/dockerfile:1.7
# One image, three entry points (/app/api, /app/worker, /app/migrate), so
# docker-compose.yml works by switching only the build context (ADR-0032).

FROM node:22-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
# An optional extra CA bundle (build secret "extra_ca") lets builds work behind a
# TLS-intercepting proxy; it never reaches the final image.
RUN --mount=type=secret,id=extra_ca,required=false \
    if [ -s /run/secrets/extra_ca ]; then \
      export NODE_EXTRA_CA_CERTS=/run/secrets/extra_ca npm_config_cafile=/run/secrets/extra_ca; \
    fi; \
    npm ci --no-audit --no-fund
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build && npm prune --omit=dev --no-audit --no-fund && npm cache clean --force

FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /src/package.json ./package.json
COPY --from=build /src/node_modules ./node_modules
COPY --from=build /src/dist ./dist
COPY migrations ./migrations
COPY seed ./seed
COPY src/platform/http/openapi.gen.yaml ./src/platform/http/openapi.gen.yaml
COPY --chmod=755 docker/api docker/worker docker/migrate ./
USER node
EXPOSE 8080 9090
ENTRYPOINT ["/app/api"]
