# Analytics Service — Python FastAPI

Provides aggregate statistics, user growth data, and system health metrics.
Queries PostgreSQL for user counts and Prometheus for ECS runtime metrics
via Inter-Region VPC Peering.

Also exposes its own `/metrics` endpoint so Prometheus can scrape this service directly.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/stats/health` | Health check — returns `{"status":"ok"}` |
| GET | `/api/stats/summary` | Live metrics — polled every 30s by the frontend MetricsBar |
| GET | `/api/stats/users` | User growth breakdown (total, last 7 days, last 30 days) |
| GET | `/metrics` | Prometheus scrape endpoint (port 9100) |

---

## Summary Response

`GET /api/stats/summary` returns:

```json
{
  "total_users":     42,
  "ecs_cpu_pct":     18.3,
  "req_per_min":     120,
  "latency_ms":      45,
  "active_sessions": null
}
```

Fields are `null` when the underlying source (Prometheus / DynamoDB) is unreachable.
The frontend handles `null` gracefully by displaying `"—"`.

---

## How Prometheus Data Flows

The analytics service fetches ECS runtime metrics by firing PromQL queries
to the Prometheus instance in us-west-2. The traffic crosses the Inter-Region
VPC Peering connection — never the public internet.

```
lks-monitoring-vpc (10.1.0.0/16)            lks-vpc (10.0.0.0/16)
┌──────────────────────┐                    ┌──────────────────────┐
│  Prometheus :9090    │◄── scrapes :9100 ──│  Analytics /metrics  │
│                      │    via pcx-lks-2026│  API     /metrics    │
│  PromQL API          │                    └──────────────────────┘
└──────────┬───────────┘
           │  GET /api/v1/query (private IP, pcx-lks-2026)
           ▼
┌──────────────────────┐
│  Analytics           │
│  /api/stats/summary  │◄── polled by frontend every 30s
└──────────────────────┘
```

---

## Module Structure

```
analytics/
├── src/
│   └── main.py         FastAPI app — all routes + Prometheus metrics
├── requirements.txt    fastapi, uvicorn, psycopg2-binary, requests, prometheus-client
├── Dockerfile          Multi-stage Python 3.13 slim
└── .env.example        Environment variable template
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `5000` | HTTP port |
| `DB_HOST` | `localhost` | RDS PostgreSQL endpoint (same DB as API service) |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `lksdb` | Database name |
| `DB_USER` | `lksadmin` | Database user |
| `DB_PASSWORD` | — | Database password — from SSM in production |
| `AWS_REGION` | `us-east-1` | AWS region |
| `PROMETHEUS_URL` | — | Prometheus private IP, e.g. `http://10.1.1.x:9090` |

> `PROMETHEUS_URL` is a private IP address — not a hostname — because DNS resolution
> does not work over inter-region VPC peering. Leave it blank in local development;
> summary fields that depend on it will return `null`.

---

## Prometheus Metrics (port 9100)

The service exposes its own metrics at `/metrics` on port `9100`, scraped by Prometheus
alongside the API service.

Metrics exposed:
- `lks_analytics_requests_total` — counter
- `lks_analytics_errors_total` — counter
- `lks_analytics_uptime_seconds` — gauge

> Security Group `lks-sg-ecs` must allow TCP `9100` inbound from `10.1.0.0/16`.

---

## Local Development

```bash
cd analytics
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env    # Leave PROMETHEUS_URL blank for local dev
python src/main.py      # http://localhost:5000
```

Or from project root:
```bash
docker compose up -d
```

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `summary` returns `null` for CPU / latency fields | `PROMETHEUS_URL` not set or Prometheus unreachable |
| `summary` returns `null` for `total_users` | Cannot connect to RDS — check `DB_HOST` and SG rules |
| Prometheus shows analytics target as `DOWN` | TCP 9100 blocked by SG or wrong scrape IP |
| `/api/stats/health` returns `503` | DB connection failed — check env vars and RDS status |
