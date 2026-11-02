#!/usr/bin/env bash
# Create the kind cluster, build both images, and load them into the cluster.
source "$(dirname "$0")/common.sh"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "kind cluster '$CLUSTER' already exists"
else
  kind create cluster --name "$CLUSTER"
fi
kubectl config use-context "kind-$CLUSTER"

docker build -t inventory:1.0 inventory/
docker build -t inventory-client:1.0 client/

kind load docker-image inventory:1.0 inventory-client:1.0 --name "$CLUSTER"
echo "Setup complete."
