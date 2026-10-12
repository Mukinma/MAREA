#!/usr/bin/env bash
set -euo pipefail
# Run explicitly after configuring Secret Manager values. No credentials are
# accepted on the command line or committed; no public worker endpoint exists.
TOUR_PROJECT="${TOUR_PROJECT:-marea-f6a92}"
TOUR_REGION="${TOUR_REGION:-us-central1}"
TOUR_JOB="${TOUR_JOB:-marea-tour-stitch}"
TOUR_RUNTIME_SA="${TOUR_RUNTIME_SA:?Set the runtime service account email}"
TOUR_DISPATCH_SA="${TOUR_DISPATCH_SA:?Set the dispatcher service account email}"
TOUR_DIR="$(cd "$(dirname "$0")" && pwd)"
TOUR_SOURCE_HASH="$(cat "$TOUR_DIR/worker.py" "$TOUR_DIR/requirements.txt" "$TOUR_DIR/Dockerfile" | shasum -a 256 | cut -c1-12)"
if [[ -z "${TOUR_IMAGE:-}" ]]; then
 TOUR_IMAGE="$TOUR_REGION-docker.pkg.dev/$TOUR_PROJECT/marea/tour-stitch:$(git rev-parse --short HEAD)-$TOUR_SOURCE_HASH"
 gcloud builds submit "$TOUR_DIR" --project "$TOUR_PROJECT" --tag "$TOUR_IMAGE"
else
 # Use the very same amd64 image validated locally, uploaded after billing clears.
 [[ "$TOUR_IMAGE" == "$TOUR_REGION-docker.pkg.dev/$TOUR_PROJECT/marea/"* ]] || { echo 'Unexpected image registry.' >&2; exit 1; }
 gcloud artifacts docker images describe "$TOUR_IMAGE" --project "$TOUR_PROJECT" >/dev/null
fi
gcloud run jobs deploy "$TOUR_JOB" --project "$TOUR_PROJECT" --region "$TOUR_REGION" \
 --image "$TOUR_IMAGE" --service-account "$TOUR_RUNTIME_SA" --cpu 4 --memory 8Gi \
 --task-timeout 900s --max-retries 0 --tasks 1 --parallelism 1 \
 --set-secrets SUPABASE_URL=marea-supabase-url:latest,SUPABASE_SERVICE_ROLE_KEY=marea-supabase-service-role:latest,TOUR_WORKER_SECRET=marea-tour-worker-secret:latest
# Running with overrides needs run.jobs.runWithOverrides in addition to run.jobs.run.
gcloud run jobs add-iam-policy-binding "$TOUR_JOB" --project "$TOUR_PROJECT" --region "$TOUR_REGION" \
 --member "serviceAccount:$TOUR_DISPATCH_SA" --role roles/run.jobsExecutorWithOverrides
