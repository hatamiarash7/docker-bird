FROM debian:bookworm-slim AS builder

ARG BIRD_VERSION
ARG BIRD_URL="https://bird.network.cz/download/bird-${BIRD_VERSION}.tar.gz"
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux \
    && apt-get update -qyy \
    && apt-get install -qyy --no-install-recommends --no-install-suggests \
    ca-certificates \
    wget \
    build-essential \
    flex \
    bison \
    libncurses-dev \
    libreadline-dev \
    libssh-dev \
    && rm -rf /var/lib/apt/lists/* /var/log/*
RUN wget -O bird.tar.gz ${BIRD_URL} \
    && tar -xzvf bird.tar.gz -C /usr/src/ \
    && rm -rf bird.tar.gz

RUN set -eux \
    && cd /usr/src/bird-${BIRD_VERSION}/ \
    && ./configure \
    --prefix=/usr/ \
    --sysconfdir=/etc/bird/ \
    --localstatedir=/var/ \
    --enable-libssh \
    && make -j $(nproc) \
    && make install \
    && { find /usr/sbin/bird* -type f -executable -exec strip --strip-all "{}" +; }

FROM debian:bookworm-slim

ARG BIRD_VERSION
ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="bird" \
    org.opencontainers.image.description="The BIRD Internet Routing Daemon" \
    org.opencontainers.image.url="https://github.com/hatamiarash7/docker-bird" \
    org.opencontainers.image.source="https://github.com/hatamiarash7/docker-bird" \
    org.opencontainers.image.vendor="hatamiarash7" \
    org.opencontainers.image.author="hatamiarash7" \
    org.opencontainers.version="$BIRD_VERSION" \
    org.opencontainers.image.created="$(date --iso-8601=seconds)" \
    org.opencontainers.image.licenses="MIT"

COPY --from=builder /usr/sbin/bird* /usr/sbin/
COPY --from=builder /etc/bird/ /etc/bird/

RUN set -eux \
    && apt-get update -qyy \
    && apt-get install -qyy --no-install-recommends --no-install-suggests \
    iproute2 \
    libtinfo6 \
    libreadline8 \
    libssh-4 \
    telnet \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/* /var/log/*

EXPOSE 179/tcp

CMD ["bird", "-f", "-R"]