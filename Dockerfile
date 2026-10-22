# ============================================================
# STAGE: base — общая база для prod и dev
# ============================================================
# PHP_VERSION пиннится на security-релизы:
#   8.2.35 / 8.4.27 / 8.5.12 — fix CVE-2026-109618, CVE-2026-109619
ARG PHP_VERSION=8.4.27
FROM php:${PHP_VERSION}-cli-alpine AS base
ARG PHP_VERSION

LABEL maintainer="Traineratwot <traineratwot@yandex.ru>"
LABEL org.opencontainers.image.source="https://github.com/Traineratwot/php"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
        curl \
        git \
        zip \
        unzip \
        icu-libs \
        libpng \
        libjpeg-turbo \
        freetype \
        libwebp \
        libzip \
        libpq \
        libxml2 \
        oniguruma \
        imagemagick \
        imagemagick-libs \
        libstdc++ \
        openssl \
        bash \
        linux-headers \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libwebp-dev \
        libzip-dev \
        postgresql-dev \
        libxml2-dev \
        oniguruma-dev \
        imagemagick-dev \
        openssl-dev \
        curl-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && for e in \
         pdo_pgsql pgsql pdo_mysql mysqli mbstring exif pcntl bcmath \
         gd opcache zip intl xml soap sockets; do \
         # PHP 8.5+: opcache собран статически и не ставится как shared
         if [ "$e" = "opcache" ] && php -n -m | grep -qi '^Zend OPcache$'; then \
             echo "skip $e (compiled into PHP)"; \
             continue; \
         fi; \
         docker-php-ext-install -j"$(nproc)" "$e"; \
     done \
    && install_pecl() { \
        name="$1"; \
        for i in 1 2 3 4 5 6 7 8; do \
            echo "pecl ${name}: attempt ${i}"; \
            rm -rf "/tmp/pecl-${name}"; \
            if curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
                    -o "/tmp/${name}.tgz" "https://pecl.php.net/get/${name}" \
                && mkdir -p "/tmp/pecl-${name}" \
                && tar -xzf "/tmp/${name}.tgz" -C "/tmp/pecl-${name}" --strip-components=1 \
                && (cd "/tmp/pecl-${name}" \
                    && phpize \
                    && ./configure \
                    && make -j"$(nproc)" \
                    && ls modules/ \
                    && MAKEFLAGS= make -j1 install); then \
                rm -rf "/tmp/pecl-${name}" "/tmp/${name}.tgz"; \
                return 0; \
            fi; \
            echo "pecl ${name}: failed (attempt ${i}), retrying..." >&2; \
            rm -rf "/tmp/pecl-${name}" "/tmp/${name}.tgz" /tmp/pear; \
            sleep $((i * 5)); \
        done; \
        echo "pecl ${name}: all attempts failed" >&2; \
        return 1; \
    } \
    && install_pecl redis \
    && install_pecl imagick \
    && install_pecl swoole \
    && install_pecl opentelemetry \
    && install_pecl protobuf \
    && docker-php-ext-enable redis imagick swoole opentelemetry protobuf \
    && apk del .build-deps \
    && rm -rf /tmp/pear /var/cache/apk/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# BUILD_DATE передаётся из CI. Объявляется и используется только здесь,
# чтобы смена даты не сбивала cache тяжёлых слоёв выше.
# cat /version — UTC ISO-8601; дата >= 2026-10-21 = security-фикс PHP.
ARG BUILD_DATE=unknown
RUN printf '%s\n' "${BUILD_DATE}" > /version
LABEL org.opencontainers.image.created="${BUILD_DATE}"

WORKDIR /app

# ============================================================
# STAGE: prod
# ============================================================
FROM base AS prod
ARG PHP_VERSION

LABEL description="PHP ${PHP_VERSION} Alpine — production base image (CVE-2026-109618/CVE-2026-109619 fixed)"

RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.memory_consumption=256'; \
        echo 'opcache.interned_strings_buffer=64'; \
        echo 'opcache.max_accelerated_files=30000'; \
        echo 'opcache.validate_timestamps=0'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.jit=1255'; \
        echo 'opcache.jit_buffer_size=128M'; \
    } > /usr/local/etc/php/conf.d/opcache-prod.ini

RUN php -m

CMD ["php", "-a"]

# ============================================================
# STAGE: dev
# ============================================================
FROM base AS dev
ARG PHP_VERSION

LABEL description="PHP ${PHP_VERSION} Alpine — development base image with Xdebug & tools (CVE-2026-109618/CVE-2026-109619 fixed)"

RUN apk add --no-cache \
        procps \
        htop \
        btop \
        mc \
        nano \
        wget \
        net-tools \
        bind-tools \
        strace \
        lsof \
        busybox-extras

RUN apk add --no-cache --virtual .xdebug-build-deps $PHPIZE_DEPS linux-headers \
    && for i in 1 2 3 4 5 6 7 8; do \
         echo "pecl xdebug: attempt ${i}"; \
         rm -rf /tmp/pecl-xdebug; \
         if curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 \
                 -o /tmp/xdebug.tgz https://pecl.php.net/get/xdebug \
             && mkdir -p /tmp/pecl-xdebug \
             && tar -xzf /tmp/xdebug.tgz -C /tmp/pecl-xdebug --strip-components=1 \
             && (cd /tmp/pecl-xdebug \
                 && phpize \
                 && ./configure \
                 && make -j"$(nproc)" \
                 && ls modules/ \
                 && MAKEFLAGS= make -j1 install); then \
             rm -rf /tmp/pecl-xdebug /tmp/xdebug.tgz; \
             break; \
         fi; \
         echo "pecl xdebug: failed (attempt ${i}), retrying..." >&2; \
         rm -rf /tmp/pecl-xdebug /tmp/xdebug.tgz /tmp/pear; \
         [ "$i" -eq 8 ] && exit 1; \
         sleep $((i * 5)); \
       done \
    && docker-php-ext-enable xdebug \
    && apk del .xdebug-build-deps \
    && rm -rf /tmp/pear /var/cache/apk/*

RUN { \
        echo 'xdebug.mode=debug,develop,coverage'; \
        echo 'xdebug.start_with_request=trigger'; \
        echo 'xdebug.discover_client_host=1'; \
        echo 'xdebug.client_port=9003'; \
        echo 'xdebug.idekey=PHPSTORM'; \
        echo 'xdebug.log_level=0'; \
    } > /usr/local/etc/php/conf.d/xdebug.ini

RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.memory_consumption=256'; \
        echo 'opcache.interned_strings_buffer=64'; \
        echo 'opcache.max_accelerated_files=30000'; \
        echo 'opcache.validate_timestamps=1'; \
        echo 'opcache.revalidate_freq=0'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.jit=disable'; \
    } > /usr/local/etc/php/conf.d/opcache-dev.ini

RUN php -m

CMD ["php", "-a"]
