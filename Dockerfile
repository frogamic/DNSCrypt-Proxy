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
LABEL Maintainer="Dominic Shelton" \
      Author="Dominic Shelton" \
      Version=${VERSION} \
      Description="DNSCrypt v2/DoH client using jedisct1/dnscrypt-proxy."
