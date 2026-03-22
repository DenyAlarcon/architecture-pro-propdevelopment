#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="${SCRIPT_DIR}/users-certs"
mkdir -p "${CERT_DIR}"

create_user() {
  local user="$1"
  local key_file="${CERT_DIR}/${user}.key"
  local csr_file="${CERT_DIR}/${user}.csr"
  local crt_file="${CERT_DIR}/${user}.crt"
  local csr_name="${user}-csr"
  local request_b64=""
  local cert_b64=""

  openssl genrsa -out "${key_file}" 2048 >/dev/null 2>&1
  openssl req -new -key "${key_file}" -out "${csr_file}" -subj "/CN=${user}" >/dev/null 2>&1

  request_b64="$(base64 < "${csr_file}" | tr -d '\n')"

  kubectl delete csr "${csr_name}" --ignore-not-found >/dev/null 2>&1 || true
  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${csr_name}
spec:
  request: ${request_b64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
    - client auth
EOF

  kubectl certificate approve "${csr_name}" >/dev/null

  for _ in {1..20}; do
    cert_b64="$(kubectl get csr "${csr_name}" -o jsonpath='{.status.certificate}')"
    if [[ -n "${cert_b64}" ]]; then
      break
    fi
    sleep 1
  done

  if [[ -z "${cert_b64}" ]]; then
    echo "Не удалось выпустить сертификат для ${user}" >&2
    exit 1
  fi

  echo "${cert_b64}" | base64 --decode > "${crt_file}"
  echo "Создан пользователь ${user} (cert: ${crt_file}, key: ${key_file})"
}

create_user "manager1"
create_user "devops1"
create_user "secops1"

echo "Готово. Пользователи созданы через CSR, файлы лежат в ${CERT_DIR}."
