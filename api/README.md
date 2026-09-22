# API Service — Python Flask + PostgreSQL + SQS

Primary backend REST API. Handles all CRUD operations for the `users` resource,
publishes events to SQS, and exposes a Prometheus `/metrics` endpoint scraped
by the monitoring stack in us-west-2 via Inter-Region VPC Peering.

---

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/health` | Health check — returns `{"status":"ok","db":"connected"}` |
| GET | `/api/status` | Checks connectivity to Prometheus and Grafana (proxied server-side) |
| GET | `/api/users` | List all users |
| GET | `/api/users/:id` | Get a single user by ID |
| POST | `/api/users` | Create a new user |
| PUT | `/api/users/:id` | Update an existing user |
| DELETE | `/api/users/:id` | Delete a user |
| GET | `/metrics` | Prometheus metrics (port 9100) |

---

## Request / Response Format

**POST / PUT body:**
```json
{
  "name":        "Budi Santoso",
  "email":       "budi@example.com",
  "institution": "SMK Negeri 1 Purwokerto",
  "position":    "Student",
  "phone":       "08123456789"
}
```

**Successful create (201):**
```json
{
  "id":          1,
  "name":        "Budi Santoso",
  "email":       "budi@example.com",
  "institution": "SMK Negeri 1 Purwokerto",
  "position":    "Student",
  "phone":       "08123456789",
  "created_at":  "2026-01-01T00:00:00.000Z"
}
```

**Error codes:**
| Code | Meaning |
|---|---|
| 400 | Missing required fields (`name` or `email`) |
| 404 | User not found |
| 409 | Email already exists (unique constraint) |
| 503 | Database not yet ready (retry in a moment) |

---

## Module Structure

```
api/
├── app.py           Flask app factory — registers blueprints, starts metrics thread
├── db.py            PostgreSQL connection pool with retry backoff
├── sqs.py           SQS event publisher (silently skipped if QUEUE_URL not set)
├── metrics.py       Prometheus metrics — separate Flask app on port 9100
├── routes/
│   └── users.py     CRUD routes for /api/users
├── Dockerfile       Multi-stage build — Python 3.13 slim
└── requirements.txt flask, flask-cors, psycopg2-binary, boto3, python-dotenv
```

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | Main HTTP port |
| `METRICS_PORT` | `9100` | Prometheus metrics port |
| `DB_HOST` | `localhost` | RDS PostgreSQL endpoint |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `lksdb` | Database name |
| `DB_USER` | `lksadmin` | Database user |
| `DB_PASSWORD` | — | Database password — read from SSM in production |
| `AWS_REGION` | `us-east-1` | Region for SQS and other AWS clients |
| `SQS_QUEUE_URL` | — | SQS queue URL (events silently skipped if not set) |
| `CORS_ORIGIN` | `*` | Set to ALB DNS in production to restrict CORS |
| `PROMETHEUS_URL` | — | Used by `/api/status` proxy check |
| `GRAFANA_URL` | — | Used by `/api/status` proxy check |

> **In production (ECS):** Environment variables are injected from SSM Parameter Store
> via the ECS Task Definition `secrets` section — never hardcoded.

---

## Database

On first startup the API automatically creates the `users` table if it does not exist.
No migration tool needed.

```sql
CREATE TABLE users (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  email       VARCHAR(255) NOT NULL UNIQUE,
  institution VARCHAR(255),
  position    VARCHAR(255),
  phone       VARCHAR(50),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

> The database module stores the RDS endpoint in SSM at `/lks/app/db_host`.
> The ECS task reads it at startup.

---

## SQS Events

Every successful create, update, or delete publishes a JSON message to `lks-event-queue`:

```json
{
  "eventType": "user.created",
  "payload":   { "userId": 1, "email": "budi@example.com" },
  "timestamp": "2026-01-01T00:00:00.000Z",
  "source":    "lks-api"
}
```

If `SQS_QUEUE_URL` is not set, the publish step is silently skipped — useful in local dev.

---

## Prometheus Metrics

The API runs a **second Flask app on port 9100** exposing `/metrics` in Prometheus text format.
Prometheus in us-west-2 scrapes this port via Inter-Region VPC Peering.

Metrics exposed:
- `lks_api_requests_total` — counter, total HTTP requests received
- `lks_api_errors_total` — counter, total 5xx responses
- `lks_api_uptime_seconds` — gauge, seconds since service started

> Security Group `lks-sg-ecs` must allow TCP `9100` inbound from `10.1.0.0/16`
> for Prometheus to reach this endpoint.

---

## Local Development

```bash
cd api
cp .env.example .env   # Fill in DB credentials
pip install -r requirements.txt
python app.py          # API on :8080, metrics on :9100
```

Or from the project root with Docker Compose:
```bash
docker compose up -d api
```

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `503 Database not ready` on startup | RDS not reachable — check SG rules and `DB_HOST` value |
| SQS events not appearing in queue | `SQS_QUEUE_URL` env var not set or wrong name |
| Prometheus shows target as `DOWN` | Port 9100 blocked by SG, or metrics server binding to wrong port — check the env var name the code actually reads |
| DELETE returns `204` but record still exists | Missing `conn.commit()` in delete handler |
| API cannot connect to RDS in production | Check `sslmode` setting in `db.py` — RDS requires SSL |
