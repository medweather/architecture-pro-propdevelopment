# Task 7: Аудит и обеспечение соответствия политике безопасности контейнеров

## Цель

Выявить и заблокировать поды, нарушающие требования безопасной конфигурации — через **PodSecurity Admission** и **OPA Gatekeeper**.

## Порядок развёртывания

```bash
# 1. Создать namespace с PodSecurity restricted
kubectl apply -f 01-create-namespace.yaml

# 2. Установить OPA Gatekeeper (если не установлен)
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# 3. Применить constraint templates
kubectl apply -f gatekeeper/constraint-templates/

# 4. Применить constraints
kubectl apply -f gatekeeper/constraints/

# 5. Проверить, что небезопасные поды отклоняются
kubectl apply -f insecure-manifests/    # → должно быть DENIED

# 6. Проверить, что безопасные поды проходят
kubectl apply -f secure-manifests/      # → должно быть ALLOWED
```

## Политики безопасности

| Политика | PSA PodSecurity | Gatekeeper |
|----------|-----------------|------------|
| `privileged: true` | Restricted-level запрещает | K8sPSPPrivilegedContainer |
| `hostPath` | Restricted-level запрещает | K8sPSPHostPath |
| `runAsUser: 0` | Restricted-level: `MustRunAsNonRoot` | K8sPSPRunAsNonRoot |
| `readOnlyRootFilesystem` | Нет встроенной проверки | K8sPSPRunAsNonRoot |
| `runAsNonRoot: true` | Restricted-level требует | K8sPSPRunAsNonRoot |

## Проверка

```bash
# Быстрая проверка admission
./verify/verify-admission.sh

# Статическая валидация всех файлов
./verify/validate-security.sh
```
