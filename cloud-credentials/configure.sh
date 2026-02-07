set -e

# Load variables from .env if running locally
if [ -f "$(dirname "$0")/../.env" ]; then
  set -a
  source "$(dirname "$0")/../.env"
  set +a
fi

# Validate required variables
: "${GOOGLE_CLOUD_PROJECT:?GOOGLE_CLOUD_PROJECT is required}"
: "${PROJECT_NUMBER:?PROJECT_NUMBER is required}"
: "${POOL_ID:?POOL_ID is required}"
: "${OIDC_ENDPOINT:?OIDC_ENDPOINT is required}"
: "${OKTETO_SERVICE_ACCOUNT:?OKTETO_SERVICE_ACCOUNT is required}"
: "${AUDIENCE:?AUDIENCE is required}"

PRINCIPAL=iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/subject/${OKTETO_SERVICE_ACCOUNT}

gcloud iam workload-identity-pools describe ${POOL_ID} --location=global --project=${GOOGLE_CLOUD_PROJECT} &>/dev/null || \
  gcloud iam workload-identity-pools create ${POOL_ID} --location=global --project=${GOOGLE_CLOUD_PROJECT} --display-name="Okteto pool"

gcloud iam workload-identity-pools providers describe demo-okteto-dev --location=global --workload-identity-pool=${POOL_ID} --project=${GOOGLE_CLOUD_PROJECT} &>/dev/null || \
  gcloud iam workload-identity-pools providers create-oidc demo-okteto-dev \
    --location=global \
    --workload-identity-pool=${POOL_ID} \
    --project=${GOOGLE_CLOUD_PROJECT} \
    --display-name="Okteto Identity Provider" \
    --attribute-mapping="google.subject=assertion.sub" \
    --issuer-uri="${OIDC_ENDPOINT}" \
    --allowed-audiences=${AUDIENCE}

gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --role=roles/storage.admin --member=principal://${PRINCIPAL} --condition=None &>/dev/null
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --role=roles/iam.serviceAccountAdmin --member=principal://${PRINCIPAL} --condition=None &>/dev/null
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} --role=roles/resourcemanager.projectIamAdmin --member=principal://${PRINCIPAL} --condition=None &>/dev/null
