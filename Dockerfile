FROM postgres:11-alpine
MAINTAINER Volodymyr Tartynskyi "fon.vosi@gmail.com"

ENV POSTGIS_VERSION 2.5.0
ENV POSTGIS_SHA256 35169b7eb733262ae557097e3a68dc9d5b35484e875c37b4fd3372fcc80c39b9

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    && apk add --no-cache --virtual .build-deps \   
        autoconf \
        automake \
        g++ \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
    # add libcrypto from (edge:main) for gdal-2.3.0  
    && apk add --no-cache --virtual .crypto-rundeps \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        libressl2.7-libcrypto \    
    && apk add --no-cache --virtual .build-deps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        gdal-dev \
        geos-dev \
        proj4-dev \
        protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        geos \
        gdal \
        proj4 \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-testing

RUN sed -i -e "s/#fsync\s*=\s*on/fsync = off/g" /usr/local/share/postgresql/postgresql.conf.sample
RUN sed -i -e "s/#synchronous_commit\s*=\s*on/synchronous_commit = off/g" /usr/local/share/postgresql/postgresql.conf.sample
RUN sed -i -e "s/#full_page_writes\s*=\s*on/full_page_writes = off/g" /usr/local/share/postgresql/postgresql.conf.sample

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-hstore.sh /docker-entrypoint-initdb.d/hstore.sh
COPY ./update-postgis.sh /usr/local/bin
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
