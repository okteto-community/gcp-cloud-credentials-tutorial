# Cloud Treasure Chest

A demo Flask application that uploads text messages to a Google Cloud Storage bucket. Designed to showcase Okteto's cloud credentials integration with GCP Workload Identity.

## Architecture

```
User → Flask (gunicorn:8080) → Google Cloud Storage bucket
                 ↑
        Workload Identity (Okteto/GKE)
```

The app exposes a single page where users type a message, submit it, and it gets stored as a `.txt` object in GCS with a unique timestamped filename.

## Prerequisites

- [Okteto CLI](https://www.okteto.com/docs/get-started/install-okteto-cli/)
- A GCP project with the Cloud Storage API enabled

## Okteto Variables

Before deploying, configure the following variables in your Okteto instance. Go to **Settings > Variables** in the Okteto UI:

```bash
GOOGLE_CLOUD_PROJECT=<your-gcp-project-id>
GKE_PROJECT=<your-gke-cluster-project-id>
```

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_CLOUD_PROJECT` | GCP project where resources (service accounts, buckets) are created | `my-resources-project` |
| `GKE_PROJECT` | GCP project where the GKE cluster runs (may differ from above) | `my-cluster-project` |

These variables are used by the `deploy`, `test`, and `destroy` phases in `okteto.yaml`.

## Deploy

The [okteto.yaml](okteto.yaml) manifest automates the full lifecycle:

```bash
okteto deploy
```

This will:
1. Create a GCP service account (`<namespace>-treasure-hunt-app`)
2. Grant it `storage.objectAdmin` on the project
3. Bind it to the Kubernetes `default` service account via Workload Identity
4. Create the GCS bucket if it doesn't exist
5. Deploy the app using docker-compose

## Development

```bash
okteto up
```

This starts a remote development environment syncing your local files to the cluster. Changes to the code are reflected immediately.

## Test

```bash
okteto test
```

Verifies the GCS bucket exists in the target project.

## Destroy

```bash
okteto destroy
```

Cleans up the GCP service account and bucket (including all objects).

## GCP Setup (One-Time)

Before deploying, your Okteto admin needs to configure Cloud Credentials for GCP. Follow the [Configure access to your GCP account using Workload Identity](https://www.okteto.com/docs/admin/cloud-credentials/gcp-cloud-credentials/) guide to set up Workload Identity Federation between your Okteto instance and GCP.

The deploy phase requires the following IAM roles on the target GCP project:
- `roles/storage.admin`
- `roles/iam.serviceAccountAdmin`
- `roles/resourcemanager.projectIamAdmin`

## Project Structure

| Path | Description |
|------|-------------|
| `app/main.py` | Flask application — single route handling GET/POST |
| `app/templates/index.html` | Web UI with textarea and upload form |
| `cloud-credentials/configure.sh` | Workload Identity Pool and IAM setup script |
| `Dockerfile` | Python 3.11-slim image with gunicorn |
| `docker-compose.yml` | Compose file used by Okteto to deploy the app |
| `okteto.yaml` | Okteto deploy/test/destroy manifest |
| `requirements.txt` | Python dependencies |
| `.env` | Local environment variables for configure.sh (git-ignored) |
