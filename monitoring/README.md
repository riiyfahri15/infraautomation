# Monitoring Stack — Full Observability (us-west-2 Oregon)

The monitoring stack runs entirely in **us-west-2 (Oregon)** inside `lks-monitoring-vpc`.
It communicates with application services in **us-east-1 (Virginia)** through **Inter-Region VPC Peering**.

---

## Stack Components

| Service | Port | Role |
|---|---|---|
| **Prometheus** | `9090` | Scrapes metrics from ECS tasks via VPC Peering |
| **Grafana** | `3000` | Visualizes metrics (Prometheus) and logs (Loki) |
| **Loki** | `3100` | Aggregates logs from application containers |
| **Alertmanager** | `9093` | Routes alerts from Prometheus to email / SNS |

All four services must be deployed as ECS Fargate tasks in `lks-monitoring-cluster` (us-west-2).

---

## Files

```
monitoring/
├── prometheus/
│   ├── prometheus.yml          Scrape config — targets ECS private IPs via peering
│   └── rules/
│       └── alerts.yml          Alert rules for service down detection
├── grafana/
│   └── provisioning/           Auto-provisioned datasources and dashboards
├── loki/
│   └── loki.yml               Storage config, schema v13, 7-day retention
├── alertmanager/
│   └── alertmanager.yml       Route config, receivers, and inhibition rules
└── Dockerfile                 Builds the monitoring image with configs baked in
```

---

## Why Inter-Region Peering?

Prometheus running in us-west-2 scraping metrics from ECS containers in us-east-1
proves that the Inter-Region VPC Peering connection is fully working.

> **Important constraint:** DNS resolution is **not supported** across inter-region VPC Peering.
> All monitoring components must communicate with application services using **private IP addresses only**, not hostnames.

If Prometheus Targets tab shows ECS tasks as **UP**, it confirms:
- VPC Peering `pcx-lks-2026` is `active`
- Route tables in both regions are correctly configured
- Security group `lks-sg-ecs` allows TCP `9100` ingress from `10.1.0.0/16`

---

## Deployment

All monitoring services are deployed as ECS Fargate tasks in `lks-monitoring-cluster` (us-west-2). Create them manually via the AWS Console after the application services in us-east-1 are running.

### Step 1 — Get ECS task private IPs (us-east-1)

```bash
aws ecs describe-tasks \
  --cluster lks-ecs-cluster \
  --region us-east-1 \
  --tasks $(aws ecs list-tasks \
    --cluster lks-ecs-cluster \
    --region us-east-1 \
    --output text --query 'taskArns[]') \
  --query 'tasks[].attachments[].details[?name==`privateIPv4Address`].value[]' \
  --output text
```

### Step 2 — Update Prometheus scrape targets

Edit `prometheus/prometheus.yml` — replace the placeholder IPs (`10.0.3.10`, `10.0.3.11`) with the actual private IPs of your ECS tasks.

### Step 3 — Push to GitHub

```bash
git add monitoring/
git commit -m "Update Prometheus targets with actual ECS task IPs"
git push origin main
```

The CI/CD pipeline will rebuild the monitoring image and push it to ECR us-west-2.

### Step 4 — Deploy / update monitoring ECS services

In the AWS Console (us-west-2), update or redeploy:
- `lks-prometheus` — port 9090
- `lks-grafana` — port 3000
- `lks-loki` — port 3100
- `lks-alertmanager` — port 9093

---

## Grafana Setup

1. Access Grafana at `http://<grafana-private-ip>:3000`
2. Default credentials: `admin / admin` (change on first login)
3. Add data sources:
   - **Prometheus** → `http://<prometheus-private-ip>:9090` (private IP, not hostname)
   - **Loki** → `http://<loki-private-ip>:3100` (private IP, not hostname)
4. Create or import dashboards for ECS service metrics and application logs

---

## Alertmanager Setup

`alertmanager/alertmanager.yml` is pre-configured with route groups and inhibition rules.
You need to replace the webhook URL placeholder with your actual SNS endpoint or Lambda webhook URL.

Alerts are routed by severity:
- `critical` — immediate notification, 10s group wait, repeats every 1h
- others — 30s group wait, repeats every 4h

---

## Verification Commands

```bash
# Prometheus — check active targets
curl http://<prometheus-private-ip>:9090/api/v1/targets \
  | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Loki — query recent logs
curl -G http://<loki-private-ip>:3100/loki/api/v1/query \
  --data-urlencode 'query={job="lks-api-service"}' \
  | jq '.data.result[0].values[0][1]'

# Alertmanager — check active alerts
curl http://<alertmanager-private-ip>:9093/api/v2/alerts
```

Expected Prometheus output:
```json
{"job": "lks-api-service",       "health": "up"}
{"job": "lks-analytics-service", "health": "up"}
{"job": "prometheus",            "health": "up"}
```
