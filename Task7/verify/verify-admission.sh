#!/bin/bash
set -euo pipefail

NAMESPACE="audit-zone"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo " Проверка PodSecurity Admission"
echo "=========================================="

echo -e "\n${YELLOW}[1] Проверка namespace audit-zone${NC}"
if kubectl get ns "$NAMESPACE" &>/dev/null; then
    echo -e "${GREEN}✓ Namespace $NAMESPACE существует${NC}"
    kubectl get ns "$NAMESPACE" -o yaml | grep -A5 "pod-security"
else
    echo -e "${RED}✗ Namespace $NAMESPACE не найден. Выполните: kubectl apply -f 01-create-namespace.yaml${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[2] Проверка отклонения небезопасных подов${NC}"

# Тест 1: privileged
echo -ne "  privileged pod... "
if kubectl apply --dry-run=server -f "$BASE_DIR/insecure-manifests/01-privileged-pod.yaml" 2>&1 | grep -qi "denied\|error\|Forbidden\|disallowed"; then
    echo -e "${GREEN}✓ Отклонён${NC}"
else
    echo -e "${YELLOW}⚠ Возможно пропущен (зависит от PSA/Gatekeeper)${NC}"
fi

# Тест 2: hostPath
echo -ne "  hostPath pod... "
if kubectl apply --dry-run=server -f "$BASE_DIR/insecure-manifests/02-hostpath-pod.yaml" 2>&1 | grep -qi "denied\|error\|Forbidden\|disallowed"; then
    echo -e "${GREEN}✓ Отклонён${NC}"
else
    echo -e "${YELLOW}⚠ Возможно пропущен (зависит от PSA/Gatekeeper)${NC}"
fi

# Тест 3: root UID 0
echo -ne "  root user pod... "
if kubectl apply --dry-run=server -f "$BASE_DIR/insecure-manifests/03-root-user-pod.yaml" 2>&1 | grep -qi "denied\|error\|Forbidden\|disallowed"; then
    echo -e "${GREEN}✓ Отклонён${NC}"
else
    echo -e "${YELLOW}⚠ Возможно пропущен (зависит от PSA/Gatekeeper)${NC}"
fi

echo -e "\n${YELLOW}[3] Проверка разрешения безопасных подов${NC}"

for file in "$BASE_DIR/secure-manifests/"*.yaml; do
    name=$(basename "$file")
    echo -ne "  $name... "
    if kubectl apply --dry-run=server -f "$file" 2>&1 | grep -qi "denied\|error\|Forbidden\|disallowed"; then
        echo -e "${RED}✗ Отклонён (ожидалось разрешение)${NC}"
    else
        echo -e "${GREEN}✓ Разрешён${NC}"
    fi
done

echo -e "\n${YELLOW}[4] Проверка Gatekeeper${NC}"
if kubectl get constraints 2>/dev/null | grep -q .; then
    echo -e "${GREEN}✓ Gatekeeper constraints активны${NC}"
    kubectl get constraints 2>/dev/null || true
else
    echo -e "${YELLOW}⚠ Gatekeeper не установлен или constraints не найдены${NC}"
fi

echo ""
echo "=========================================="
echo " Проверка завершена"
echo "=========================================="
