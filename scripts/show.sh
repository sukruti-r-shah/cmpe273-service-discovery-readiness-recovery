#!/usr/bin/env bash
# One-screen status view: Pods, Service, which Pods receive traffic, recent client requests.
# Usage: ./scripts/show.sh [log-window, default 8s]
source "$(dirname "$0")/common.sh"
WINDOW="${1:-8s}"

run kubectl get pods -l app=inventory -o wide
run kubectl get svc inventory-service
service_endpoints
echo
echo "[$(date '+%H:%M:%S')] \$ kubectl logs deploy/client --tail=8"
kubectl logs deploy/client --tail=8
tally "$WINDOW"
