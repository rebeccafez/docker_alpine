# BUILD
FROM alpine:3.20.2 AS build
ENV MIMALLOC_VERSION="v2.1.7"

RUN set -ex; \
  apk add --update --no-cache \
    build-base \
    linux-headers \
    make \
    cmake \
    gcc \
    g++ \
    git; \
  git clone https://github.com/microsoft/mimalloc.git; \
  cd /mimalloc; \
  git checkout ${MIMALLOC_VERSION}; \
  mkdir build; \
  cd build; \
  cmake ..; \
  make -j$(nproc); \
  make install

## HEADER
FROM alpine:3.20.2
COPY --from=build /mimalloc/build/*.so.* /lib/
ENV LD_PRELOAD=/lib/libmimalloc.so

# RUN

USER root

## Update image
RUN set -ex; \
  apk add --update --no-cache \
    curl \
    tzdata \
    shadow; \
  apk --no-cache --update upgrade;

RUN set -ex; \
  ln -s /lib/libmimalloc.so.* /lib/libmimalloc.so || echo "libmimalloc.so already linked"

## create unprivileged user
RUN set -ex; \
  addgroup --gid 1000 -S docker; \
  adduser --uid 1000 -D -S -h / -s /sbin/nologin -G docker docker;

USER docker
