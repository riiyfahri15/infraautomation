# Frontend Service — Python Flask + Jinja2

Web UI for the LKS 2026 User Management application.
Renders HTML server-side via Jinja2 templates and injects the API URL at runtime,
so no build step or environment baking is needed — the same Docker image works in
any environment by simply changing the `API_URL` environment variable.

---

## How It Works

The frontend is a **thin Python Flask server** — it does not do any API calls itself.
It serves an HTML template that receives the API URL as a template variable and
makes all REST calls directly from the browser using JavaScript.

```
Browser
  └── GET /
        └── Flask renders index.html
              └── api_url = os.getenv("API_URL")  ← injected into <script> tag
                    └── JS calls api_url + "/api/users"  ← direct browser requests
```

This means:
- `API_URL` must be the **publicly reachable ALB DNS name**, not an internal hostname.
- If `API_URL` is wrong or empty, all API calls will silently fail in the browser.

---

## Endpoints

| Path | Description |
|---|---|
| `GET /` | Main user management page |
| `GET /users` | Alias for `/` (same view) |
| `GET /health` | Health check — returns `200 OK` (used by ALB health check) |

---

## Module Structure

```
frontend/
├── app.py              Flask app — reads env vars, renders templates
├── templates/
│   └── index.html      Single-page HTML + vanilla JS UI
├── Dockerfile          Multi-stage Python 3.13 slim — no npm/Node required
├── requirements.txt    flask, python-dotenv
└── .env.example        Template for local development
```

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `API_URL` | **Yes** | ALB DNS name — e.g. `http://lks-alb-xxx.us-east-1.elb.amazonaws.com` |
| `GRAFANA_URL` | No | Grafana private IP — passed to template for monitoring link |
| `PROMETHEUS_URL` | No | Prometheus private IP — passed to template for monitoring link |
| `PORT` | No (default: 3000) | HTTP port the Flask server listens on |

> **In production (ECS):** `API_URL` is set as an environment variable in the ECS Task Definition.
> The value is the ALB DNS name from `terraform output alb_dns_name`.

---

## ALB Routing

The ALB routes traffic based on path pattern. The frontend receives all requests
that don't match `/api/*` — the ALB handles the split, not the frontend itself.

| Request | ALB routes to |
|---|---|
| `/*` | `lks-fe-service` (port 3000) — this service |
| `/api/*` | `lks-api-service` (port 8080) |
| `/api/stats/*` | `lks-analytics-service` (port 5000) |

> Listener Rule priority matters: `api/stats/*` (Priority 1) must be evaluated
> before `/api/*` (Priority 2), otherwise analytics requests are swallowed by the API rule.

---

## Local Development

```bash
cd frontend
cp .env.example .env
# Set API_URL=http://localhost:8080 for local API
pip install -r requirements.txt
python app.py    # http://localhost:3000
```

Or from project root:
```bash
docker compose up -d frontend
```

---

## Production Deployment (ECS via CodeDeploy)

The frontend container is deployed to ECS Fargate as `lks-fe-service`.
CodeDeploy manages Blue/Green deployments — a new task set is launched with the
new image, traffic shifts only after the health check at `/health` returns `200`.

For ECS task definition, the minimum environment to set:
```json
{
  "name": "API_URL",
  "value": "http://<alb-dns-name>"
}
```

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Page loads but shows no users | The env var key read by the app may not match what you set — inspect the source code carefully |
| Users API calls fail silently | Wrong env var name used in `app.py` — compare what the code reads vs what the container env provides |
| `404` on all API calls from browser | `API_URL` points to wrong host or missing `/api` prefix |
| ALB health check fails | `/health` endpoint not returning `200` — check if Flask started correctly |
| Container exits immediately | Missing env var or Python import error — check CloudWatch Logs |
