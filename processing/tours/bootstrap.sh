#!/usr/bin/env bash
set -euo pipefail
# Explicitly invoked provisioning; never run by Flutter or a migration.
TOUR_PROJECT="${TOUR_PROJECT:-marea-f6a92}"
TOUR_REGION="${TOUR_REGION:-us-central1}"
command -v gcloud >/dev/null
[[ "$(gcloud billing projects describe "$TOUR_PROJECT" --format='value(billingEnabled)')" == "True" ]] || { echo 'Active billing is required.' >&2; exit 1; }
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com monitoring.googleapis.com --project "$TOUR_PROJECT"
if ! gcloud artifacts repositories describe marea --location "$TOUR_REGION" --project "$TOUR_PROJECT" >/dev/null 2>&1; then
 gcloud artifacts repositories create marea --repository-format docker --location "$TOUR_REGION" --project "$TOUR_PROJECT"
fi
for TOUR_ACCOUNT in marea-tour-runtime marea-tour-dispatch; do
 if ! gcloud iam service-accounts describe "$TOUR_ACCOUNT@$TOUR_PROJECT.iam.gserviceaccount.com" --project "$TOUR_PROJECT" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$TOUR_ACCOUNT" --project "$TOUR_PROJECT"
 fi
done
for TOUR_SECRET in marea-supabase-url marea-supabase-service-role marea-tour-worker-secret; do
 # Values must already exist; provisioning never prints or synthesizes secrets.
 gcloud secrets versions describe latest --secret "$TOUR_SECRET" --project "$TOUR_PROJECT" >/dev/null
 gcloud secrets add-iam-policy-binding "$TOUR_SECRET" --project "$TOUR_PROJECT" --member "serviceAccount:marea-tour-runtime@$TOUR_PROJECT.iam.gserviceaccount.com" --role roles/secretmanager.secretAccessor >/dev/null
done
echo 'Provisioning ready. Set TOUR_RUNTIME_SA/TOUR_DISPATCH_SA to the created accounts and run deploy.sh explicitly.'
