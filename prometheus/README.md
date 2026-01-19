# Prometheus Monitoring Stack

Prometheus monitoring and alerting toolkit for the homelab, including node-exporter for Proxmox host metrics.

## Components

### Prometheus

- Scrapes metrics from exporters (node-exporter, pve-exporter, etc.)
- Stores time-series data with 30-day retention
- Provides PromQL query interface
- Exposes metrics via HTTP API

### Node Exporter

- **Host-level metrics** - Linux system metrics from the Proxmox host OS
- CPU, memory, disk I/O, network stats, filesystem metrics
- Hardware-level monitoring (what the physical host is doing)
- Runs with host networking to access host-level metrics
- **Use this for**: Host CPU usage, host RAM, host disk I/O, host network

### PVE Exporter

- **Virtualization-layer metrics** - Proxmox VE-specific metrics
- VM status, CPU, memory, disk usage **per VM**
- Storage pool metrics (usage, I/O)
- Cluster health and quorum status
- **Use this for**: Individual VM resources, storage pools, cluster status
- Requires Proxmox API credentials
- Official exporter: [prometheus-pve/prometheus-pve-exporter](https://github.com/prometheus-pve/prometheus-pve-exporter)

**They work together**: Node-exporter shows what the host is doing, pve-exporter shows what your VMs are doing.

## Setup

**This runs on the Proxmox host** (node-exporter requires host access).

1. Ensure the `proxy` network exists (created by Traefik):

   ```bash
   docker network create proxy
   ```

2. **Configure PVE Exporter credentials:**

   Create a `.env` file (or use environment variables):

   ```bash
   cp env.example .env
   # Edit .env with your Proxmox credentials
   ```

   **Option A: Use API Token (Recommended)**

   - Create Prometheus user and token on Proxmox host:
     ```bash
     pveum user add prometheus@pve --comment "Prometheus monitoring user"
     pveum user modify prometheus@pve -group PVEAuditor
     pveum user token add prometheus@pve prometheus --privsep 0
     ```
   - Get token secret: `pveum user token list prometheus@pve | grep prometheus | awk '{print $NF}'`
   - Set in `.env`:
     ```bash
     PVE_USER=prometheus@pve
     PVE_TOKEN_NAME=prometheus
     PVE_TOKEN_VALUE=<paste-secret-here>
     ```

   **Option B: Use Username/Password**

   - Set `PVE_USER` and `PVE_PASSWORD` in `.env`
   - Less secure, but simpler for testing

3. Start all services:

   ```bash
   docker compose up -d
   ```

4. Verify exporters are working:

   ```bash
   # Node exporter (system metrics)
   curl http://localhost:9100/metrics

   # PVE exporter (Proxmox metrics)
   curl http://localhost:9221/pve?module=default&cluster=1&node=1
   ```

5. Access Prometheus UI:
   - Direct: http://localhost:9090
   - Via Traefik: http://prometheus.cluster.fuck

## Querying Metrics

### Host-Level Metrics (Node Exporter)

```promql
# Host CPU usage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Host memory usage
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Host disk I/O
rate(node_disk_read_bytes_total[5m])
rate(node_disk_written_bytes_total[5m])

# Host network traffic
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Proxmox-Specific Metrics (PVE Exporter)

```promql
# VM CPU usage percentage (per VM)
pve_vm_cpu_usage_ratio * 100

# VM memory usage (bytes) - per VM
pve_vm_memory_bytes

# VM disk usage (bytes) - per VM
pve_vm_disk_size_bytes

# Storage pool usage
pve_storage_size_bytes
pve_storage_used_bytes

# Cluster quorum status (1 = healthy, 0 = unhealthy)
pve_cluster_quorum

# Node status (1 = online, 0 = offline)
pve_node_status

# VM status (1 = running, 0 = stopped)
pve_vm_status
```

**Example queries:**

Find all VMs using more than 80% CPU:

```promql
pve_vm_cpu_usage_ratio > 0.8
```

Compare host CPU vs sum of all VM CPUs:

```promql
# Host CPU (from node-exporter)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Sum of all VM CPUs (from pve-exporter)
sum(pve_vm_cpu_usage_ratio) * 100
```

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
