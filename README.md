# DNSCrypt/DoH Proxy

A ready-to-run DNS proxy with support for DNSCrypt v2 and DNS-over-HTTPS, using [dnscrypt-proxy](https://github.com/jedisct1/dnscrypt-proxy) by [jedisct1](https://github.com/jedisct1).

## Run it in Docker now

This command will create a DNS server in docker with the default settings.

```sh
docker run -p 53:53/udp -p 53:53/tcp frogamic/dnscrypt-proxy
```

Assuming the docker host is your local machine, you can confirm it worked by running `nslookup google.com 127.0.0.1`

By default it will fetch a list of upstream DNS servers on startup and sort by fastest, it will then use the top 2 fastest servers to service queries. Configuration should be mounted to `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` to override the defaults. Configuration guidelines can be found [in the dnscrypt-proxy project](https://github.com/jedisct1/dnscrypt-proxy/wiki/Configuration)

## Other ways to use it

### With docker-compose

```YAML
services:
  dnscrypt-proxy:
    image: frogamic/dnscrypt-proxy
    ports:
      - 53:53/udp
      - 53:53/tcp
    volumes:
      - /path/to/config.toml:/etc/dnscrypt-proxy/dnscrypt-proxy.toml
```

### Run it with Pi-hole

The following compose file will create a Pi-hole server using dnscrypt-proxy as the only upstream DNS.

```YAML
version: "3.7"

networks:
  default:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.53.0/24

services:
  dnscrypt-proxy:
    image: frogamic/dnscrypt-proxy
    volumes:
      - /path/to/config.toml:/etc/dnscrypt-proxy/dnscrypt-proxy.toml
    networks:
      default:
        ipv4_address: 192.168.53.53
    restart: always

  pi-hole:
    image: pihole/pihole
    ports:
      - 53:53/udp
      - 53:53/tcp
      - 80:80/tcp
    networks:
      default:
    environment:
      DNS1: 192.168.53.53
      DNS2: '0.0.0.0'
    dns:
      - 127.0.0.1
    restart: always
    depends_on:
      - dnscrypt-proxy
```

You may need to tweak the subnet to suit your network environment. A static IP is required for dnscrypt-proxy so that Pi-hole can talk to it. This is a minimal configuration, [refer to the Pi-hole documentation for more detail](https://github.com/pi-hole/docker-pi-hole).
