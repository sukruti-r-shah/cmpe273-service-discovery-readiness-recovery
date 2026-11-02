#!/usr/bin/env bash
# macOS only: run each scenario visibly in a new Terminal window and screenshot it
# into evidence/. Requires Screen Recording permission for your terminal app.
source "$(dirname "$0")/common.sh"
SHOTS="$ROOT/evidence"
mkdir -p "$SHOTS"

# Open a dedicated Terminal window and remember its tab + window id
WID=$(osascript <<EOF
tell application "Terminal"
  activate
  set t to do script "cd '$ROOT'; clear"
  delay 1
  repeat with w in windows
    if selected tab of w is t then
      set bounds of w to {40, 40, 1500, 1060}
      set index of w to 1
      return id of w
    end if
  end repeat
end tell
EOF
)
echo "Capturing Terminal window id $WID"

# type a command into the window
in_window() {
  local cmd="${1//\\/\\\\}"; cmd="${cmd//\"/\\\"}"
  osascript -e "tell application \"Terminal\" to do script \"$cmd\" in (selected tab of (first window whose id is $WID))" >/dev/null
}

# bring the window to the front and capture it
shot() {
  osascript -e "tell application \"Terminal\" to set index of (first window whose id is $WID) to 1" >/dev/null
  sleep 1
  screencapture -x -o -l "$WID" "$SHOTS/$1"
  echo "saved evidence/$1"
}

read -r POD_A POD_B <<<"$(inventory_pods)"

# 1. Both replicas receive requests
in_window "clear; echo '\$ kubectl get deploy client -o jsonpath=<INVENTORY_URL env>'; kubectl get deploy client -o jsonpath='{.spec.template.spec.containers[0].env[0]}'; echo; echo; echo '\$ DNS lookup of the Service name from inside the client Pod'; kubectl exec deploy/client -- python -c \"import socket; print('inventory-service ->', socket.gethostbyname('inventory-service'))\"; ./scripts/show.sh 10s"
sleep 8; shot "1-both-replicas.png"

# 2a. Readiness failure
in_window "clear; kubectl exec $POD_A -- touch /tmp/unready && kubectl wait --for=condition=Ready=false pod/$POD_A && sleep 10 && ./scripts/show.sh 8s && kubectl get events --field-selector involvedObject.name=$POD_A,reason=Unhealthy | tail -2"
sleep 22; shot "2-readiness-failure.png"

# 2b. Readiness recovery
in_window "clear; kubectl exec $POD_A -- rm /tmp/unready && kubectl wait --for=condition=Ready pod/$POD_A && sleep 10 && ./scripts/show.sh 8s"
sleep 22; shot "2-readiness-recovery.png"

# 3a. Pod deletion and replacement (Service unchanged)
in_window "clear; kubectl get pods -l app=inventory && kubectl get svc inventory-service && kubectl delete pod $POD_A && kubectl rollout status deploy/inventory && kubectl wait --for=condition=Ready pod -l app=inventory && kubectl get pods -l app=inventory && kubectl get svc inventory-service"
sleep 15; shot "3-pod-deleted-replaced.png"

# 3b. Client keeps working through the Service
in_window "clear; sleep 5; ./scripts/show.sh 25s"
sleep 12; shot "3-client-continues.png"

echo "Done. Screenshots are in evidence/"
