#!/usr/bin/env bash
# Open two Terminal windows for watching the demo live (macOS):
#   1) Pod status (watch READY / STATUS / new names appear)
#   2) Client logs (which Pod served each request)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

osascript <<EOF
tell application "Terminal"
  activate
  do script "cd '$ROOT'; kubectl get pods -l app=inventory -o wide -w"
  do script "cd '$ROOT'; kubectl logs -f deploy/client --tail=5"
end tell
EOF
