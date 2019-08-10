FROM golang:alpine AS build

ARG VERSION=master
ARG ARCH=amd64
ARG LDFLAGS="-s -w"

ENV GOPATH=/dnscrypt-proxy-${VERSION}/dnscrypt-proxy
ENV GOARCH ${ARCH}

WORKDIR /

RUN apk --no-cache add git
RUN if [ "${VERSION}" = "master" ]; then \
      wget -qO- https://github.com/jedisct1/dnscrypt-proxy/archive/master.tar.gz | tar xzf - ;\
    else \
      wget -qO- https://github.com/jedisct1/dnscrypt-proxy/archive/${VERSION}.tar.gz | tar xzf - ;\
    fi

RUN cd $GOPATH && go clean \
               && go build -ldflags="${LDFLAGS}" -o /output/dnscrypt-proxy \
               && sed -e '/^\s*#.*/d' \
                      -e '/^\s*$/d' \
                      -e "s/^listen_addresses\s*=.*$/listen_addresses = ['0.0.0.0:53']/" \
                      example-dnscrypt-proxy.toml > /output/dnscrypt-proxy.toml

FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /etc/dnscrypt-proxy

COPY --from=build /output/dnscrypt-proxy /usr/bin/dnscrypt-proxy
COPY --from=build /output/dnscrypt-proxy.toml ./dnscrypt-proxy.toml

EXPOSE 53/udp
EXPOSE 53/tcp

HEALTHCHECK CMD nslookup gstatic.com 127.0.0.1
ENTRYPOINT /usr/bin/dnscrypt-proxy

ARG VERSION
LABEL org.opencontainers.image.authors="Dominic Shelton" \
      org.opencontainers.image.title="DNSCrypt/DoH Proxy" \
      org.opencontainers.image.description="DNSCrypt/DoH proxy server using jedisct1/dnscrypt-proxy." \
      org.opencontainers.image.url="https://hub.docker.com/r/frogamic/dnscrypt-proxy" \
      org.opencontainers.image.source="https://github.com/frogamic/dnscrypt-proxy" \
      org.opencontainers.image.version=${VERSION} \
      org.opencontainers.image.licenses="GPL-3.0"
