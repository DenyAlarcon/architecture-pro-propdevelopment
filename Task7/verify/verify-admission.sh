#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/6] Apply namespace with PodSecurity restricted"
kubectl apply -f "$ROOT_DIR/01-create-namespace.yaml"

echo "[2/6] Install Gatekeeper (if missing)"
if ! kubectl get ns gatekeeper-system >/dev/null 2>&1; then
  kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.20/deploy/gatekeeper.yaml
fi

echo "[3/6] Wait Gatekeeper controller"
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-controller-manager --timeout=240s

echo "[4/6] Apply templates and constraints"
kubectl apply -f "$ROOT_DIR/gatekeeper/constraint-templates"

for crd in \
  k8sdenyprivileged.constraints.gatekeeper.sh \
  k8sdenyhostpath.constraints.gatekeeper.sh \
  k8srequirenonrootreadonly.constraints.gatekeeper.sh
do
  echo "Waiting for CRD: $crd"
  kubectl wait --for=condition=Established "crd/$crd" --timeout=120s >/dev/null
done

kubectl apply -f "$ROOT_DIR/gatekeeper/constraints"

echo "[5/6] Insecure manifests must be rejected"
for f in "$ROOT_DIR"/insecure-manifests/*.yaml; do
  if kubectl apply --dry-run=server -f "$f" >/dev/null 2>&1; then
    echo "FAIL: $(basename "$f") was accepted"
    exit 1
  fi
  echo "OK rejected: $(basename "$f")"
done

echo "[6/6] Secure manifests must be accepted"
for f in "$ROOT_DIR"/secure-manifests/*.yaml; do
  kubectl apply --dry-run=server -f "$f" >/dev/null
  echo "OK accepted: $(basename "$f")"
done

echo "All checks passed"
