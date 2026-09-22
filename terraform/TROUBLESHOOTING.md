# Task 2 — Application Bug Fixing

The application services (`api/`, `frontend/`, `analytics/`) contain deliberate bugs.
Find and fix all of them before building Docker images and running the CI/CD pipeline.

## How to Approach This

1. Read each service's `README.md` to understand how it is supposed to work.
2. Run the services locally with Docker Compose to observe failure behaviour:
   ```bash
   docker compose up -d
   docker compose logs -f api
   docker compose logs -f frontend
   ```
3. Trace the bug back to its source file and fix it.
4. Restart the container and confirm the fix works.

## Area to Investigate

- Environment variable names read by each service
- Database connection configuration
- Missing transaction operations
- Metrics server configuration
- Pipeline CI/CD job configuration (`.github/workflows/lks-cicd.yml`)

> There are bugs in both the Python source files and the GitHub Actions workflow.
> Fix all of them before proceeding to Task 3 (ECR push).

## Verification

After all fixes:

```bash
# API health check
curl http://localhost:8080/api/health
# Expected: {"status":"ok","db":"connected","service":"lks-api",...}

# Metrics endpoint
curl http://localhost:9100/metrics
# Expected: Prometheus text format with lks_api_* metrics

# Create a user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com"}'
# Expected: 201 with user JSON

# Delete the user (verify it is actually removed on next GET)
curl -X DELETE http://localhost:8080/api/users/1
curl http://localhost:8080/api/users
# Expected: empty array
```
