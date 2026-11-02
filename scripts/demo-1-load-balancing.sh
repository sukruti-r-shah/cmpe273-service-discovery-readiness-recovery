#!/usr/bin/env bash
# Requirement 1: both Pods running, client uses the Service name, traffic reaches both replicas.
source "$(dirname "$0")/common.sh"

{
  section "Both Inventory Pods are running"
  run kubectl get deploy inventory
  run kubectl get pods -l app=inventory -o wide
}

{
  section "The Service and the Pod IPs behind it"
  run kubectl get svc inventory-service -o wide
  service_endpoints
  section "Client is configured with the Service name, not a Pod IP"
  run "kubectl get deploy client -o jsonpath='{.spec.template.spec.containers[0].env[0]}'; echo"
  section "DNS lookup of the Service name from inside the client Pod"
  run "kubectl exec deploy/client -- python -c \"import socket; print('inventory-service ->', socket.gethostbyname('inventory-service'))\""
}

echo "Letting the client send requests for 10s..."
sleep 10
{
  section "Client logs: responses come from more than one replica"
  run "kubectl logs deploy/client --since=10s | tail -20"
  tally 10s
}
