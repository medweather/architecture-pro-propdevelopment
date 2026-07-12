#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local desc="$1"
    local result="$2"
    if [ "$result" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $desc"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}✗${NC} $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=========================================="
echo " Валидация безопасности Task7"
echo "=========================================="

echo -e "\n${YELLOW}[Insecure manifests] Проверка наличия нарушений${NC}"

# Проверка 01-privileged-pod.yaml
if grep -q "privileged: true" "$BASE_DIR/insecure-manifests/01-privileged-pod.yaml"; then
    check "01-privileged-pod.yaml содержит privileged: true" 0
else
    check "01-privileged-pod.yaml содержит privileged: true" 1
fi

# Проверка 02-hostpath-pod.yaml
if grep -q "hostPath:" "$BASE_DIR/insecure-manifests/02-hostpath-pod.yaml"; then
    check "02-hostpath-pod.yaml содержит hostPath" 0
else
    check "02-hostpath-pod.yaml содержит hostPath" 1
fi

# Проверка 03-root-user-pod.yaml
if grep -q "runAsUser: 0" "$BASE_DIR/insecure-manifests/03-root-user-pod.yaml"; then
    check "03-root-user-pod.yaml содержит runAsUser: 0" 0
else
    check "03-root-user-pod.yaml содержит runAsUser: 0" 1
fi

echo -e "\n${YELLOW}[Secure manifests] Проверка исправлений${NC}"

check_secure() {
    local file="$1" label="$2"

    # Нет privileged
    if grep -q "privileged: true" "$file"; then
        check "$label: нет privileged: true" 1
    else
        check "$label: нет privileged: true" 0
    fi

    # Есть runAsNonRoot
    if grep -q "runAsNonRoot: true" "$file"; then
        check "$label: есть runAsNonRoot: true" 0
    else
        check "$label: есть runAsNonRoot: true" 1
    fi

    # Есть readOnlyRootFilesystem
    if grep -q "readOnlyRootFilesystem: true" "$file"; then
        check "$label: есть readOnlyRootFilesystem: true" 0
    else
        check "$label: есть readOnlyRootFilesystem: true" 1
    fi

    # Есть allowPrivilegeEscalation: false
    if grep -q "allowPrivilegeEscalation: false" "$file"; then
        check "$label: есть allowPrivilegeEscalation: false" 0
    else
        check "$label: есть allowPrivilegeEscalation: false" 1
    fi

    # Есть seccompProfile RuntimeDefault
    if grep -q "RuntimeDefault" "$file"; then
        check "$label: есть seccompProfile RuntimeDefault" 0
    else
        check "$label: есть seccompProfile RuntimeDefault" 1
    fi

    # Есть capabilities drop ALL
    if grep -A2 "capabilities:" "$file" | grep -q "ALL"; then
        check "$label: есть capabilities drop ALL" 0
    else
        check "$label: есть capabilities drop ALL" 1
    fi
}

check_secure "$BASE_DIR/secure-manifests/01-secure.yaml" "01-secure.yaml"

# Проверка 02-secure.yaml — ещё и нет hostPath
if grep -q "hostPath:" "$BASE_DIR/secure-manifests/02-secure.yaml"; then
    check "02-secure.yaml: нет hostPath" 1
else
    check "02-secure.yaml: нет hostPath" 0
fi
check_secure "$BASE_DIR/secure-manifests/02-secure.yaml" "02-secure.yaml"

# Проверка 03-secure.yaml — ещё и runAsUser не 0
if grep -q "runAsUser: 0" "$BASE_DIR/secure-manifests/03-secure.yaml"; then
    check "03-secure.yaml: runAsUser не 0" 1
else
    check "03-secure.yaml: runAsUser не 0" 0
fi
check_secure "$BASE_DIR/secure-manifests/03-secure.yaml" "03-secure.yaml"

echo -e "\n${YELLOW}[Gatekeeper] Проверка шаблонов и ограничений${NC}"

GK_TEMPLATES=("privileged.yaml" "hostpath.yaml" "runasnonroot.yaml")
for tmpl in "${GK_TEMPLATES[@]}"; do
    if [ -f "$BASE_DIR/gatekeeper/constraint-templates/$tmpl" ]; then
        CRD=$(grep "kind:" "$BASE_DIR/gatekeeper/constraint-templates/$tmpl" | head -1 | awk '{print $2}')
        check "Constraint template: $CRD" 0
    else
        check "Constraint template $tmpl существует" 1
    fi
done

GK_CONSTRAINTS=("privileged.yaml" "hostpath.yaml" "runasnonroot.yaml")
for constr in "${GK_CONSTRAINTS[@]}"; do
    if [ -f "$BASE_DIR/gatekeeper/constraints/$constr" ]; then
        KIND=$(grep "kind:" "$BASE_DIR/gatekeeper/constraints/$constr" | head -1 | awk '{print $2}')
        check "Constraint: $KIND" 0
    else
        check "Constraint $constr существует" 1
    fi
done

echo -e "\n${YELLOW}[Namespace] Проверка конфигурации${NC}"

if grep -q "restricted" "$BASE_DIR/01-create-namespace.yaml"; then
    check "Namespace audit-zone с PodSecurity restricted" 0
else
    check "Namespace audit-zone с PodSecurity restricted" 1
fi

echo ""
echo "=========================================="
echo -e " Результат: ${GREEN}$PASS пройдено${NC}, ${RED}$FAIL не пройдено${NC}"
echo "=========================================="
exit $FAIL
