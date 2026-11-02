#!/usr/bin/env bash
# Remove the app, or the whole cluster with --all.
source "$(dirname "$0")/common.sh"

if [[ "${1:-}" == "--all" ]]; then
  kind delete cluster --name "$CLUSTER"
else
  kubectl delete -f k8s/ --ignore-not-found
fi
