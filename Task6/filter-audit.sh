#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="Task6/audit.log"
OUT_FILE="Task6/audit-extract.json"

jq -cs '
  def is_monitoring:
    .user.username == "system:serviceaccount:secure-ops:monitoring"
    or .impersonatedUser.username == "system:serviceaccount:secure-ops:monitoring";

  def ns:
    .requestObject.metadata.namespace // .objectRef.namespace // "";

  def pod_name:
    .requestObject.metadata.name // .objectRef.name // "";

  def is_privileged_pod:
    .objectRef.resource == "pods"
    and .verb == "create"
    and (.objectRef.subresource == null)
    and (
      pod_name == "privileged-pod"
      or (
        ns == "secure-ops"
        and any(.requestObject.spec.containers[]?; .securityContext.privileged == true)
      )
    );

  def is_suspicious:
    (
      .objectRef.resource == "secrets"
      and (.verb == "get" or .verb == "list")
      and is_monitoring
    )
    or is_privileged_pod
    or (.objectRef.subresource == "exec" and .objectRef.namespace == "kube-system")
    or (
      .objectRef.resource == "rolebindings"
      and .verb == "create"
      and (
        .objectRef.namespace == "secure-ops"
        or (.requestObject.roleRef.name // "") == "cluster-admin"
      )
    )
    or (
      .verb == "delete"
      and (
        (.requestURI // "" | test("audit-policy"; "i"))
        or ((.objectRef.name // "") | test("audit-policy"; "i"))
      )
    );

  [
    .[]
    | select(.stage == "ResponseComplete")
    | select(is_suspicious)
  ]
  | unique_by(.auditID)
' "$LOG_FILE" > "$OUT_FILE"
