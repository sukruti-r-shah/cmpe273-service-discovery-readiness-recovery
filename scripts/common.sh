# Shared helpers for demo scripts. Source this file, don't run it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER="sd-lab"
cd "$ROOT"

# Print a section header
section() {
  echo
  echo "================================================================"
  echo "== $*"
  echo "================================================================"
}

# Print a command with a timestamp, then run it
run() {
  echo
  echo "[$(date '+%H:%M:%S')] \$ $*"
  eval "$@"
}

# Count how many requests each Pod served in the client's recent logs
tally() {
  local since="$1"
  echo
  echo "[$(date '+%H:%M:%S')] Requests per Pod in the last ${since} of client logs:"
  kubectl logs deploy/client --since="$since" \
    | grep -oE 'served_by=[^ ]+|ERROR' | sed 's/served_by=//' | sort | uniq -c
}

inventory_pods() {
  kubectl get pods -l app=inventory -o jsonpath='{.items[*].metadata.name}'
}

# Show each Pod behind the Service and whether the Service will route to it
service_endpoints() {
  echo
  echo "[$(date '+%H:%M:%S')] \$ kubectl get endpointslices -l kubernetes.io/service-name=inventory-service  (per-endpoint ready flag)"
  printf "%-28s %-14s %s\n" "POD" "IP" "READY (receives traffic?)"
  kubectl get endpointslices -l kubernetes.io/service-name=inventory-service \
    -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{" "}{.addresses[0]}{" "}{.conditions.ready}{"\n"}{end}' \
    | while read -r name ip ready; do printf "%-28s %-14s %s\n" "$name" "$ip" "$ready"; done
}
