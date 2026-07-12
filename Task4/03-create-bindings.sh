#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RBAC_DIR="${SCRIPT_DIR}/rbac"

kubectl apply -f "${RBAC_DIR}/cluster-admin-binding.yaml" >/dev/null
echo "  [+] cluster-admin ← devops-oleg [cluster-wide]"

for env in production staging development; do
  kubectl apply -f "${RBAC_DIR}/role-bindings-${env}.yaml" >/dev/null
  echo "  [+] dev-alice, viewer-bob → ${env}"
done

echo ""
echo "Готово."
