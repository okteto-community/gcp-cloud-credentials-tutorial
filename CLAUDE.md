# CLAUDE.md

## Project Overview

**Cloud Treasure Chest** — a demo Flask app that uploads text to a Google Cloud Storage bucket.
Deployed via Okteto with automatic GCP service account provisioning using Workload Identity.

## Repository Structure

```
app/main.py                    # Flask app (single route: GET/POST /)
app/templates/index.html       # Web UI (textarea → upload to GCS)
cloud-credentials/configure.sh # One-time Workload Identity Pool setup
Dockerfile                     # Python 3.11-slim + gunicorn
docker-compose.yml             # Local dev orchestration
okteto.yaml                    # Deploy/test/destroy lifecycle
requirements.txt               # Flask, google-cloud-storage, gunicorn
.env                           # Local config values (git-ignored)
.gitignore                     # Ignores .env and gcp-key.json
```

## Key Configuration

All project-specific values come from environment variables. No project IDs are committed to the repo.

**Okteto Variables** (set via Okteto UI or CLI — used by deploy/test/destroy):

| Variable              | Description                          |
|-----------------------|--------------------------------------|
| `GOOGLE_CLOUD_PROJECT`| GCP project for resources (SA, buckets) |
| `GKE_PROJECT`         | GCP project where the GKE cluster runs |
| `GCS_BUCKET`          | Target GCS bucket name               |

**configure.sh Variables** (loaded from `.env` or exported in the shell):

| Variable              | Description                          |
|-----------------------|--------------------------------------|
| `GOOGLE_CLOUD_PROJECT`| Same as above                        |
| `PROJECT_NUMBER`      | GCP project number (numeric)         |
| `POOL_ID`             | Workload Identity Pool ID            |
| `OIDC_ENDPOINT`       | GKE cluster OIDC issuer URL          |
| `OKTETO_SERVICE_ACCOUNT`| Kubernetes SA for Okteto           |
| `AUDIENCE`            | Workload Identity audience           |

## How It Works

### Local Development
```bash
export GCS_BUCKET=my-bucket
docker-compose up --build
# Requires Application Default Credentials or GOOGLE_APPLICATION_CREDENTIALS
```

### Okteto Deployment (okteto.yaml lifecycle)
1. **Deploy**: Creates GCP service account → binds `storage.objectAdmin` role → sets up Workload Identity → creates GCS bucket → deploys via docker-compose
2. **Test**: Verifies the bucket exists in the GCP project
3. **Destroy**: Deletes the service account and bucket (including objects)

### GCP Authentication
- **Local**: Application Default Credentials (ADC) or a service account key
- **Okteto/GKE**: Workload Identity Federation — the Kubernetes `default` service account is annotated with the GCP service account email, so pods get credentials automatically
- **configure.sh**: Sets up the Workload Identity Pool, OIDC provider, and IAM bindings (run once per cluster). Loads values from `.env` automatically.

## Required GCP Roles

The Okteto deploy identity needs:
- `roles/storage.admin` — create/delete buckets
- `roles/iam.serviceAccountAdmin` — create/delete service accounts, manage their IAM policies
- `roles/resourcemanager.projectIamAdmin` — bind IAM roles at the project level

The per-namespace service account gets:
- `roles/storage.objectAdmin` — read/write objects in the bucket
- `roles/iam.workloadIdentityUser` — allow Kubernetes SA to impersonate GCP SA

## Cross-Project Setup

The GKE cluster and the GCP resources may live in different projects. This means:
- Workload Identity pool domain uses `$GKE_PROJECT.svc.id.goog` (cluster project)
- Service accounts and IAM bindings target `$GOOGLE_CLOUD_PROJECT` (resources project)
- The `CLOUDSDK_AUTH_ACCESS_TOKEN` is a federated token (won't work with `oauth2.googleapis.com/tokeninfo`)

## Known Issues / Gotchas

- GCP service account creation has eventual consistency — a `sleep 10` is needed before referencing a newly created SA in IAM bindings
- The `gcloud iam service-accounts create` command uses `|| true` to handle ALREADY_EXISTS; this also swallows real errors

## Commands

```bash
# Validate the Okteto manifest
okteto validate

# Deploy to Okteto
okteto deploy

# Run tests
okteto test

# View endpoints
okteto endpoints

# Local development
docker-compose up --build
```
