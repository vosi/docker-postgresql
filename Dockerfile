FROM postgres:12-alpine
MAINTAINER Volodymyr Tartynskyi "fon.vosi@gmail.com"

ENV POSTGIS_VERSION 3.0.1
ENV POSTGIS_SHA256 5451a34c0b9d65580b3ae44e01fefc9e1f437f3329bde6de8fefde66d025e228

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        file \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        clang-dev \
        g++ \
        gcc \
        gdal-dev \
        geos-dev \
        llvm10-dev \
        proj-dev \
        protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make -j$(nproc) \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
        geos \
        gdal \
        proj \
        libstdc++ \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps

RUN sed -i -e "s/#fsync\s*=\s*on/fsync = off/g" /usr/local/share/postgresql/postgresql.conf.sample
RUN sed -i -e "s/#synchronous_commit\s*=\s*on/synchronous_commit = off/g" /usr/local/share/postgresql/postgresql.conf.sample
RUN sed -i -e "s/#full_page_writes\s*=\s*on/full_page_writes = off/g" /usr/local/share/postgresql/postgresql.conf.sample

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./update-postgis.sh /usr/local/bin
COPY ./initdb-hstore.sh  /docker-entrypoint-initdb.d/20_hstore.sh
