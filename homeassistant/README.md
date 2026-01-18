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

## Debug

### Prompts

@homeassistant/README.md:1-31 this is the network setup for home assistant. I'm getting a 522 on homelab.danielsteman.com.

when i login to my modem on http://192.168.178.1/  I can see an active port forwarding rule to 192.168.178.165 on port 443 and port 80 (https and http).

I checked in the tp link deco app and the ip address of router is 192.168.178.165. The router has a port forwarding rule to 192.168.68.251 on port 80 and 443. That's the intel nuc where a traefik container runs with port 80 and 443 exposed. Traefik sends the traffic to home assistant (http://192.168.68.251:8123/).
