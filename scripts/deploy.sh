#!/usr/bin/env bash
# Apply all Kubernetes manifests and wait until everything is ready.
source "$(dirname "$0")/common.sh"

kubectl apply -f k8s/
kubectl rollout status deployment/inventory --timeout=120s
kubectl rollout status deployment/client --timeout=120s
kubectl get deploy,pods,svc -o wide
