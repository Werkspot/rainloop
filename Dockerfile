FROM alpine:3.9

LABEL description="Rainloop is a simple, modern & fast web-based client" \
      maintainer="Werkspot <technology@werkspot.com>"

ARG RAINLOOP_VERSION="1.14.0"
ARG RAINLOOP_GPG_KEYS="ED7C49D987DA4591"

RUN apk add --no-cache --virtual .build-dependencies \
        gnupg \
        openssl \
        curl \

    && curl -fSL https://github.com/RainLoop/rainloop-webmail/releases/download/v${RAINLOOP_VERSION}/rainloop-community-${RAINLOOP_VERSION}.zip -o rainloop-community.zip \
    && curl -fSL https://github.com/RainLoop/rainloop-webmail/releases/download/v${RAINLOOP_VERSION}/rainloop-community-${RAINLOOP_VERSION}.zip.asc -o rainloop-community.zip.asc \

    && found=''; \
        for server in \
            ha.pool.sks-keyservers.net \
            hkp://keyserver.ubuntu.com:80 \
            hkp://p80.pool.sks-keyservers.net:80 \
            pgp.mit.edu \
        ; do \
            echo "Fetching GPG key ${RAINLOOP_GPG_KEYS} from ${server}"; \
            gpg --keyserver "${server}" --keyserver-options timeout=10 --recv-keys "${RAINLOOP_GPG_KEYS}" && found=yes && break; \
        done; \
        test -z "$found" && echo >&2 "error: failed to fetch GPG key ${RAINLOOP_GPG_KEYS}" && exit 1; \
        gpg --batch --verify rainloop-community.zip.asc rainloop-community.zip \

    && mkdir /rainloop \
    && unzip rainloop-community.zip -d /rainloop \
    && find /rainloop -type d -exec chmod 755 {} \; \
    && find /rainloop -type f -exec chmod 644 {} \; \
    && rm /rainloop/data/* \
    && chmod 0777 /rainloop/data

FROM php:7.3-fpm-alpine

COPY --from=0 /rainloop /var/www/html

USER nobody
