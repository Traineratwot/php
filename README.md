# traineratwot/php

PHP 8.4 Alpine base image for Ay-tour (prod + dev).

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

## Build & publish

Images are built and pushed automatically by GitHub Actions on push to `main`:

```text
https://github.com/Traineratwot/php/actions
```

Platforms: `linux/amd64`, `linux/arm64`.

### Local build (optional)

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  --target prod \
  --tag traineratwot/php:prod \
  --tag traineratwot/php:latest \
  --push .

docker buildx build --platform linux/amd64,linux/arm64 \
  --target dev \
  --tag traineratwot/php:dev \
  --push .
```

## Required GitHub secrets

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
