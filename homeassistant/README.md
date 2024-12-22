# Home assistant

## Containers

Run Home Assistant in a Docker container, with additional containers (Cloudflare, Traefik) to enable remote access.

```bash
docker network create proxy
docker compose up -d
```

## Theme

```
https://github.com/catppuccin/home-assistant
```

## Networking

In the current setup, I have a Ziggo Connect Box and TP Link Deco. These routers are connected in series and both perform their own network address translation (NAT). To resolve double NAT, port forwarding rules are required on both Ziggo Connect Box and TP Link Deco. Everything should be forwarded from and to 80 and 443, so traefik can resolve traffic to homeassistant.

### cloudflare

Use a subdomain of danielsteman.com to securely connect to Home Assistant from the public internet.

### traefik

```bash
docker network create proxy
```

