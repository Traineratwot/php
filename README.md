# traineratwot/php

PHP Alpine base images for Ay-tour (prod + dev).

Security baseline: CVE-2026-109618 / CVE-2026-109619 (unauthenticated RCE) fixed in all builds.

| PHP | Base image | Status |
|---|---|---|
| 8.2 | `php:8.2.35-cli-alpine` | supported (EOL 2026-12-31) |
| 8.4 | `php:8.4.27-cli-alpine` | default |
| 8.5 | `php:8.5.12-cli-alpine` | current |

## Tags

| Tag | PHP | Target | Description |
|---|---|---|---|
| `traineratwot/php:latest` | **8.4** | `prod` | Alias for `prod` (default) |
| `traineratwot/php:prod` | **8.4** | `prod` | Production (opcache JIT) |
| `traineratwot/php:dev` | **8.4** | `dev` | Dev tools + Xdebug |
| `traineratwot/php:8.4` / `8.4-prod` | 8.4 | `prod` | Same as `prod` |
| `traineratwot/php:8.4-dev` | 8.4 | `dev` | Same as `dev` |
| `traineratwot/php:8.2` / `8.2-prod` | 8.2 | `prod` | Production |
| `traineratwot/php:8.2-dev` | 8.2 | `dev` | Dev tools + Xdebug |
| `traineratwot/php:8.5` / `8.5-prod` | 8.5 | `prod` | Production |
| `traineratwot/php:8.5-dev` | 8.5 | `dev` | Dev tools + Xdebug |

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

Always pass `BUILD_DATE` so `/version` is written and Docker cache is invalidated.
Pass `PHP_VERSION` to pick the line (default is 8.4.27):

```bash
BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 8.4 (default, produces prod/latest/dev)
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg BUILD_DATE="$BUILD_DATE" \
  --target prod --tag traineratwot/php:prod --tag traineratwot/php:latest \
  --push .

docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg BUILD_DATE="$BUILD_DATE" \
  --target dev --tag traineratwot/php:dev \
  --push .

# 8.2
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg PHP_VERSION=8.2.35 --build-arg BUILD_DATE="$BUILD_DATE" \
  --target prod --tag traineratwot/php:8.2-prod --tag traineratwot/php:8.2 \
  --push .

docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg PHP_VERSION=8.2.35 --build-arg BUILD_DATE="$BUILD_DATE" \
  --target dev --tag traineratwot/php:8.2-dev \
  --push .

# 8.5
docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg PHP_VERSION=8.5.12 --build-arg BUILD_DATE="$BUILD_DATE" \
  --target prod --tag traineratwot/php:8.5-prod --tag traineratwot/php:8.5 \
  --push .

docker buildx build --platform linux/amd64,linux/arm64 \
  --build-arg PHP_VERSION=8.5.12 --build-arg BUILD_DATE="$BUILD_DATE" \
  --target dev --tag traineratwot/php:8.5-dev \
  --push .
```

## Required GitHub secrets

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
