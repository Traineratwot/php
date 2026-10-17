# ============================================================
# STAGE: base — общая база для prod и dev
# ============================================================
FROM php:8.4-cli-alpine AS base

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
    && docker-php-ext-install -j"$(nproc)" \
        pdo_pgsql \
        pgsql \
        pdo_mysql \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        opcache \
        zip \
        intl \
        xml \
        soap \
        sockets \
    && MAKEFLAGS="-j$(nproc)" pecl install redis \
    && MAKEFLAGS="-j$(nproc)" pecl install imagick \
    && MAKEFLAGS="-j$(nproc)" pecl install swoole \
    && MAKEFLAGS="-j$(nproc)" pecl install opentelemetry \
    && MAKEFLAGS="-j$(nproc)" pecl install protobuf \
    && docker-php-ext-enable redis imagick swoole opentelemetry protobuf \
    && apk del .build-deps \
    && rm -rf /tmp/pear /var/cache/apk/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# ============================================================
# STAGE: prod
# ============================================================
FROM base AS prod

LABEL description="PHP 8.4 Alpine — production base image"

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

LABEL description="PHP 8.4 Alpine — development base image with Xdebug & tools"

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
    && pecl install xdebug \
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
