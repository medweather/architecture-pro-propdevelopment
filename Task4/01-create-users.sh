#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="${SCRIPT_DIR}/certs"
mkdir -p "${CERTS_DIR}"

CA_CERT="$HOME/.minikube/ca.crt"
CA_KEY="$HOME/.minikube/ca.key"

if [ ! -f "$CA_CERT" ] || [ ! -f "$CA_KEY" ]; then
  echo "Ошибка: не найден CA сертификат minikube"
  exit 1
fi

USER_GROUPS=("devops-oleg:platform-team" "dev-alice:developers" "viewer-bob:qa-team")

for entry in "${USER_GROUPS[@]}"; do
  username="${entry%%:*}"
  group="${entry##*:}"

  KEY="${CERTS_DIR}/${username}.key"
  CSR="${CERTS_DIR}/${username}.csr"
  CERT="${CERTS_DIR}/${username}.crt"
  CONFIG="${CERTS_DIR}/${username}.kubeconfig"

  openssl genpkey -algorithm RSA -out "${KEY}" -pkeyopt rsa_keygen_bits:2048 2>/dev/null
  openssl req -new -key "${KEY}" -out "${CSR}" \
    -subj "/CN=${username}/O=${group}" 2>/dev/null
  openssl x509 -req -in "${CSR}" -CA "${CA_CERT}" -CAkey "${CA_KEY}" \
    -CAcreateserial -out "${CERT}" -days 3650 \
    -extfile <(printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth") 2>/dev/null

  CLUSTER_NAME="minikube"
  SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
  CLUSTER_CA=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.certificate-authority}')

  kubectl config set-cluster "${CLUSTER_NAME}" \
    --server="${SERVER}" \
    --certificate-authority="${CLUSTER_CA}" \
    --kubeconfig="${CONFIG}" --embed-certs >/dev/null 2>&1

  kubectl config set-credentials "${username}" \
    --client-certificate="${CERT}" \
    --client-key="${KEY}" \
    --kubeconfig="${CONFIG}" --embed-certs >/dev/null 2>&1

  kubectl config set-context "${username}-context" \
    --cluster="${CLUSTER_NAME}" \
    --user="${username}" \
    --kubeconfig="${CONFIG}" >/dev/null 2>&1

  kubectl config use-context "${username}-context" \
    --kubeconfig="${CONFIG}" >/dev/null 2>&1

  echo "  [+] ${username} (${group}) — ${CONFIG}"
done

echo ""
echo "Пользователи созданы."
echo ""
echo "Проверка аутентификации:"
for entry in "${USER_GROUPS[@]}"; do
  username="${entry%%:*}"
  CONFIG="${CERTS_DIR}/${username}.kubeconfig"
  echo "  $(kubectl --kubeconfig="${CONFIG}" auth whoami 2>&1 | head -2 | tail -1)"
done
