#!/usr/bin/env bash
set -euo pipefail

NS="audit-zone"

echo "Check PodSecurity label"
ENFORCE=$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')
if [[ "$ENFORCE" != "restricted" ]]; then
  echo "FAIL: $NS enforce label is '$ENFORCE'"
  exit 1
fi

echo "Check Gatekeeper templates"
kubectl get constrainttemplates.templates.gatekeeper.sh k8sdenyprivileged k8sdenyhostpath k8srequirenonrootreadonly >/dev/null

echo "Check Gatekeeper constraints"
kubectl get k8sdenyprivileged.constraints.gatekeeper.sh deny-privileged >/dev/null
kubectl get k8sdenyhostpath.constraints.gatekeeper.sh deny-hostpath >/dev/null
kubectl get k8srequirenonrootreadonly.constraints.gatekeeper.sh require-nonroot-readonly >/dev/null

echo "Check Gatekeeper actively blocks missing readOnlyRootFilesystem"
if kubectl apply --dry-run=server -f - >/dev/null 2>&1 <<'MANIFEST'; then
apiVersion: v1
kind: Pod
metadata:
  name: gatekeeper-negative-check
  namespace: audit-zone
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        allowPrivilegeEscalation: false
        runAsNonRoot: true
        runAsUser: 1000
        capabilities:
          drop: ["ALL"]
MANIFEST
  echo "FAIL: Gatekeeper negative check was accepted"
  exit 1
fi

echo "Check valid secure pod passes"
kubectl apply --dry-run=server -f - >/dev/null <<'MANIFEST'
apiVersion: v1
kind: Pod
metadata:
  name: gatekeeper-positive-check
  namespace: audit-zone
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        allowPrivilegeEscalation: false
        runAsNonRoot: true
        runAsUser: 1000
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
MANIFEST

echo "Validation complete"
