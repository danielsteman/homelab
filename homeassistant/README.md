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

### Common Issues

**522 Error (Cloudflare timeout):**

1. **Docker API version mismatch**: Traefik v3.2 doesn't support Docker v29+. Upgrade to `traefik:v3.6` or later.

2. **Cloudflare API token issues**:
   - Verify token format (no newlines, quotes, or spaces)
   - Token should be 40+ characters, alphanumeric
   - Ensure token has DNS:Edit permissions for the zone
   - Test token: `curl -H "Authorization: Bearer $TOKEN" https://api.cloudflare.com/client/v4/zones?name=danielsteman.com`

3. **Certificate generation**: Delete `acme.json` to force regeneration if certificate is invalid/expired.

**Port forwarding not working:**

1. **Check iptables rules**:
   ```bash
   iptables -t nat -L DOCKER -n -v | grep 443
   ```

2. **Kubernetes/CNI conflicts**: If k3s was previously installed, remove CNI iptables rules:
   ```bash
   # Remove CNI rules interfering with Docker
   iptables -t nat -F CNI-HOSTPORT-DNAT
   iptables -t nat -D PREROUTING -j CNI-HOSTPORT-DNAT
   iptables -t nat -X CNI-HOSTPORT-DNAT
   ```

3. **Network configuration**: Ensure Traefik is only on `proxy` network (not `default`). Check:
   ```bash
   docker inspect traefik | jq '.[0].NetworkSettings.Networks'
   ```

4. **Monitor connections**:
   ```bash
   tcpdump -i any -n port 443 and host SOURCE_IP -c 10
   ```

**Traefik not discovering containers:**

- Check Docker API compatibility (upgrade Traefik)
- Verify containers have `traefik.enable=true` labels
- Check Traefik logs: `docker logs traefik --tail 50`

### Quick Diagnostic Commands

```bash
# Check Traefik status
docker ps | grep traefik
docker logs traefik --tail 30

# Verify ports are listening
ss -tlnp | grep -E ':(80|443)'

# Check iptables port forwarding
iptables -t nat -L DOCKER -n -v | grep 443
iptables -t nat -L PREROUTING -n -v | grep DOCKER

# Test local connection
curl -vk https://localhost:443 -H "Host: homelab.danielsteman.com"
```
