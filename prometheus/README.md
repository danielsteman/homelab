# Prometheus Monitoring Stack

Prometheus monitoring and alerting toolkit for the homelab, including node-exporter for Proxmox host metrics.

## Components

### Prometheus

- Scrapes metrics from exporters (node-exporter, pve-exporter, etc.)
- Stores time-series data with 30-day retention
- Provides PromQL query interface
- Exposes metrics via HTTP API

### Node Exporter

- Exposes hardware and OS metrics from the Proxmox host
- CPU, memory, disk I/O, network stats, filesystem metrics
- Runs with host networking to access host-level metrics

## Setup

**This runs on the Proxmox host** (node-exporter requires host access).

1. Ensure the `proxy` network exists (created by Traefik):

   ```bash
   docker network create proxy
   ```

2. Update `prometheus.yml` with your Proxmox host IP:

   ```yaml
   - job_name: "node-exporter"
     static_configs:
       - targets: ["192.168.1.100:9100"] # Replace with your Proxmox IP
   ```

   If Prometheus and node-exporter run on the same host, you can use `localhost:9100` or the host's IP.

3. Start both services:

   ```bash
   docker compose up -d
   ```

4. Verify node-exporter is working:

   ```bash
   curl http://localhost:9100/metrics
   ```

5. Access Prometheus UI:
   - Direct: http://localhost:9090
   - Via Traefik: http://prometheus.cluster.fuck

## Configuration

Edit `prometheus.yml` to add new scrape targets:

```yaml
scrape_configs:
  - job_name: "my-exporter"
    static_configs:
      - targets: ["exporter-host:port"]
```

After editing, reload config without restarting:

```bash
curl -X POST http://localhost:9090/-/reload
```

Or restart the container:

```bash
docker compose restart prometheus
```

## Data Persistence

Metrics are stored in the `prometheus_data` volume. To backup:

```bash
docker run --rm -v prometheus_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz /data
```

## Retention

Currently set to 30 days. Adjust in `compose.yml`:

```yaml
command:
  - "--storage.tsdb.retention.time=30d" # Change to 90d, 1y, etc.
```
