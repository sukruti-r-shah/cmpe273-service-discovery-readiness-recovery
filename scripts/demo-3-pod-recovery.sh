#!/usr/bin/env bash
# Requirement 3: delete a Pod, Kubernetes replaces it, Service name unchanged, client keeps working.
source "$(dirname "$0")/common.sh"

read -r POD_A POD_B <<<"$(inventory_pods)"
SVC_BEFORE="$(kubectl get svc inventory-service -o jsonpath='{.metadata.name} {.spec.clusterIP} {.metadata.uid}')"
START=$(date +%s)

{
  section "BEFORE: current Pods and Service"
  run kubectl get pods -l app=inventory -o wide
  run kubectl get svc inventory-service
}

{
  section "Delete Pod $POD_A"
  run kubectl delete pod "$POD_A"
  run kubectl rollout status deployment/inventory --timeout=120s
  run kubectl wait --for=condition=Ready pod -l app=inventory --timeout=60s

  section "AFTER: Deployment created a replacement Pod with a new name"
  run kubectl get pods -l app=inventory -o wide
  NEW_POD="$(kubectl get pods -l app=inventory -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -vx "$POD_B")"
  echo
  echo "Deleted Pod:     $POD_A"
  echo "Replacement Pod: $NEW_POD"
  echo "Untouched Pod:   $POD_B"

  section "ReplicaSet events: replacement created"
  run "kubectl get events --field-selector reason=SuccessfulCreate --sort-by=.lastTimestamp | tail -3"
}

{
  section "Service is unchanged (same name, ClusterIP, and UID)"
  SVC_AFTER="$(kubectl get svc inventory-service -o jsonpath='{.metadata.name} {.spec.clusterIP} {.metadata.uid}')"
  echo "before: $SVC_BEFORE"
  echo "after:  $SVC_AFTER"
  [[ "$SVC_BEFORE" == "$SVC_AFTER" ]] && echo "RESULT: identical" || echo "RESULT: CHANGED"
  service_endpoints
}

sleep 8
{
  ELAPSED=$(( $(date +%s) - START + 2 ))
  section "Client logs during and after the deletion (last ${ELAPSED}s)"
  run "kubectl logs deploy/client --since=${ELAPSED}s"
  tally "${ELAPSED}s"
}
