# Repository Setup Guide — LKS 2026

Two AWS regions are used in this project:
- **us-east-1 (N. Virginia)** — Application VPC, ECS cluster, RDS, ALB, CodeDeploy
- **us-west-2 (Oregon)** — Monitoring VPC, Prometheus, Grafana, Loki, Alertmanager

---

## How to Get This Repository

Fork this repository to your own GitHub account:

1. Go to the provided repository URL
2. Click **Fork** → Create fork (keep it public)
3. Clone your fork:

```bash
git clone https://github.com/<YOUR_USERNAME>/infraautomation.git
cd infraautomation
```

---

## Step 1 — Configure GitHub Secrets

In your repository: **Settings → Secrets and Variables → Actions → New repository secret**

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | From AWS Academy → AWS Details |
| `AWS_SECRET_ACCESS_KEY` | From AWS Academy → AWS Details |
| `AWS_SESSION_TOKEN` | From AWS Academy — **must be updated every session** |
| `AWS_REGION` | `us-east-1` |
| `MONITORING_REGION` | `us-west-2` |
| `AWS_ACCOUNT_ID` | Your 12-digit account ID |
| `ECR_REGISTRY` | `<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REGISTRY_MONITORING` | `<ACCOUNT_ID>.dkr.ecr.us-west-2.amazonaws.com` |
| `TF_STATE_BUCKET` | `lks-tfstate-<yourname>-<last8-of-account-id>` |
| `STUDENT_NAME` | Your name — lowercase, no spaces |
| `CODEDEPLOY_APP_NAME` | CodeDeploy application name (set after Task 5) |
| `CODEDEPLOY_DG_FRONTEND` | CodeDeploy deployment group for `lks-fe-service` |
| `CODEDEPLOY_DG_API` | CodeDeploy deployment group for `lks-api-service` |
| `CODEDEPLOY_DG_ANALYTICS` | CodeDeploy deployment group for `lks-analytics-service` |

> **AWS Academy users:** Session tokens expire when your lab session ends.
> You must update `AWS_SESSION_TOKEN` (and `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
> at the start of every lab session — the pipeline will fail with `InvalidClientTokenId` otherwise.

---

## Step 2 — Write Terraform Modules and Apply

See Task 1 in the root `README.md`.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in aws_account_id and student_name

terraform init
terraform validate
terraform plan
terraform apply -auto-approve

# Save outputs — you need these for ECS and CodeDeploy setup
terraform output
```

---

## Step 3 — Fix Application Bugs

See Task 2 and `terraform/TROUBLESHOOTING.md`.

---

## Step 4 — Create ECR Repositories

Before triggering the pipeline, ECR repositories must exist in both regions:

```bash
# us-east-1 — application services
aws ecr create-repository --repository-name lks-fe-app       --region us-east-1
aws ecr create-repository --repository-name lks-api-app      --region us-east-1
aws ecr create-repository --repository-name lks-analytics-app --region us-east-1

# us-west-2 — monitoring services
aws ecr create-repository --repository-name lks-prometheus    --region us-west-2
aws ecr create-repository --repository-name lks-grafana       --region us-west-2
aws ecr create-repository --repository-name lks-loki          --region us-west-2
aws ecr create-repository --repository-name lks-alertmanager  --region us-west-2
```

---

## Step 5 — Fix and Trigger CI/CD Pipeline

There are deliberate bugs in `.github/workflows/lks-cicd.yml`. Find and fix them,
then push to `main` to trigger the pipeline:

```bash
git add .
git commit -m "Fix bugs and trigger pipeline"
git push origin main
```

All pipeline jobs must go green before proceeding.

---

## Step 6 — Set Up CodeDeploy

See Task 5 in the root `README.md`. After creating the CodeDeploy application and
deployment groups, update the `CODEDEPLOY_APP_NAME` and `CODEDEPLOY_DEPLOYMENT_GROUP`
secrets, then add the deploy job to the pipeline.

---

## Step 7 — Deploy Monitoring Stack

See Task 6 in the root `README.md` and `monitoring/README.md`.

---

## Verification

```bash
# VPC Peering status
aws ec2 describe-vpc-peering-connections \
  --filters Name=tag:Name,Values=pcx-lks-2026 \
  --region us-east-1 \
  --query 'VpcPeeringConnections[0].Status.Code'
# Expected: "active"

# Application health
curl http://$(cd terraform && terraform output -raw alb_dns_name)/api/health
# Expected: {"status":"ok","db":"connected"}

# Analytics
curl http://$(cd terraform && terraform output -raw alb_dns_name)/api/stats/health
# Expected: {"status":"ok"}
```
