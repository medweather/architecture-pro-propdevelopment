#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RBAC_DIR="${SCRIPT_DIR}/rbac"
NAMESPACES=("production" "staging" "development")

for ns in "${NAMESPACES[@]}"; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
  echo "  [+] namespace ${ns}"
done

for ns in "${NAMESPACES[@]}"; do
  kubectl apply -n "${ns}" -f "${RBAC_DIR}/namespace-editor-role.yaml" >/dev/null
  kubectl apply -n "${ns}" -f "${RBAC_DIR}/namespace-viewer-role.yaml" >/dev/null
  echo "  [+] namespace-editor, namespace-viewer → ${ns}"
done

echo ""
echo "Готово."
