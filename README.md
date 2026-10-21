# traineratwot/php

PHP 8.4 Alpine base image for Ay-tour (prod + dev).

Base: `php:8.4.27-cli-alpine` — security release fixing CVE-2026-109618 / CVE-2026-109619 (unauthenticated RCE).

## Tags

| Tag | Target | Description |
|---|---|---|
| `traineratwot/php:prod` | `prod` | Production (opcache JIT) |
| `traineratwot/php:latest` | `prod` | Alias for `prod` |
| `traineratwot/php:dev` | `dev` | Dev tools + Xdebug |

## Extensions

Built-in: `pdo_pgsql`, `pgsql`, `pdo_mysql`, `mysqli`, `mbstring`, `exif`, `pcntl`, `bcmath`, `gd`, `opcache`, `zip`, `intl`, `xml`, `soap`, `sockets`

PECL: `redis`, `imagick`, `swoole`, `opentelemetry`, `protobuf` (+ `xdebug` in dev)

Composer 2 is available at `/usr/bin/composer`.

## Build version marker

Each image contains `/version` — UTC ISO-8601 build timestamp:

```bash
cat /version
# 2026-10-21T17:30:00Z
```

In child images use it to verify the base was rebuilt after a security fix:

```dockerfile
# fail the build if the base is older than the PHP security release 2026-10-21
RUN case "$(cat /version)" in \
      2026-10-2[1-9]*|2026-1[1-9]*|202[7-9]*|20[3-9]*) ;; \
      *) echo "base image too old: $(cat /version)" >&2; exit 1 ;; \
    esac
```

Build date is also exposed as OCI label `org.opencontainers.image.created`.

## Build & publish

Images are built and pushed automatically by GitHub Actions on push to `main`:

```text
https://github.com/Traineratwot/php/actions
```

Platforms: `linux/amd64`, `linux/arm64`.

### Local build (optional)

Always pass `BUILD_DATE` so `/version` is written and Docker cache is invalidated:

```bash
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg BUILD_DATE="$BUILD_DATE" \
  --target prod \
  --tag traineratwot/php:prod \
  --tag traineratwot/php:latest \
  --push .

docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg BUILD_DATE="$BUILD_DATE" \
  --target dev \
  --tag traineratwot/php:dev \
  --push .
```

## Required GitHub secrets

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
