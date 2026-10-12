#!/usr/bin/env bash
set -euo pipefail
# Explicit FUTURE operation after billing verification. No cron activation.
TOUR_PROJECT="${TOUR_PROJECT:-marea-f6a92}"
TOUR_REGION="${TOUR_REGION:-us-central1}"
TOUR_LOCAL_IMAGE="${TOUR_LOCAL_IMAGE:-marea/tour-stitch:local-pilot}"
TOUR_PILOT_RECORD="${TOUR_PILOT_RECORD:-$(dirname "$0")/pilot-image.json}"
TOUR_PYTHON="${TOUR_PYTHON:-python3}"
TOUR_DIGEST="$(docker image inspect "$TOUR_LOCAL_IMAGE" --format '{{.Id}}')"
TOUR_VALIDATED_DIGEST="$("$TOUR_PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))["image"])' "$TOUR_PILOT_RECORD")"
[[ "$TOUR_DIGEST" == "$TOUR_VALIDATED_DIGEST" ]] || { echo 'Local image differs from the validated pilot image; verify and record it first.' >&2; exit 1; }
command -v gcloud >/dev/null
[[ "$(gcloud billing projects describe "$TOUR_PROJECT" --format='value(billingEnabled)')" == "True" ]] || { echo 'Active billing is required.' >&2; exit 1; }
[[ "$(docker image inspect "$TOUR_LOCAL_IMAGE" --format '{{.Architecture}}')" == amd64 ]] || { echo 'The validated amd64 image is required.' >&2; exit 1; }
[[ -z "$(docker ps --filter 'name=marea-tour-' --format '{{.Names}}')" ]] || { echo 'Stop the local runner and its active executions first.' >&2; exit 1; }
TOUR_TAG="${TOUR_DIGEST#sha256:}"
TOUR_IMAGE="$TOUR_REGION-docker.pkg.dev/$TOUR_PROJECT/marea/tour-stitch:pilot-$TOUR_TAG"
gcloud auth configure-docker "$TOUR_REGION-docker.pkg.dev" --quiet
docker tag "$TOUR_LOCAL_IMAGE" "$TOUR_IMAGE"
docker push "$TOUR_IMAGE"
printf 'Validated local image uploaded: %s\n' "$TOUR_IMAGE"
