#!/usr/bin/env bash
# Requirement 2: one Pod fails readiness, stays Running, stops getting traffic, then recovers.
source "$(dirname "$0")/common.sh"

read -r POD_A POD_B <<<"$(inventory_pods)"
echo "Pod to make unready: $POD_A   (other ready Pod: $POD_B)"

{
  section "BEFORE: both Pods ready and serving"
  run kubectl get pods -l app=inventory -o wide
  service_endpoints
  tally 5s
}

{
  section "Make $POD_A fail readiness (create /tmp/unready inside it)"
  run kubectl exec "$POD_A" -- touch /tmp/unready
  run kubectl wait --for=condition=Ready=false "pod/$POD_A" --timeout=30s
  # Clear the window so the tally only counts traffic after the Pod went unready
  sleep 10

  section "Pod is still Running (STATUS) but not Ready (READY 0/1), RESTARTS unchanged"
  run kubectl get pods -l app=inventory -o wide

  section "Service endpoints now list only the ready Pod"
  service_endpoints

  section "Kubernetes events show the readiness probe failing"
  run "kubectl get events --field-selector involvedObject.name=$POD_A,reason=Unhealthy | tail -3"

  section "Client logs: all traffic now goes to $POD_B"
  run "kubectl logs deploy/client --since=8s | tail -12"
  tally 8s

  section "Inventory logs from $POD_A: readiness failing, no /items requests"
  run "kubectl logs $POD_A --since=8s | tail -5"
}

{
  section "Restore readiness on $POD_A (remove /tmp/unready)"
  run kubectl exec "$POD_A" -- rm /tmp/unready
  run kubectl wait --for=condition=Ready "pod/$POD_A" --timeout=30s
  sleep 10

  section "Both Pods Ready again"
  run kubectl get pods -l app=inventory -o wide
  service_endpoints

  section "Client logs: $POD_A receives traffic again"
  run "kubectl logs deploy/client --since=8s | tail -12"
  tally 8s
}
