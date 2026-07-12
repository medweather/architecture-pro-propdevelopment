#!/usr/bin/env python3
"""audit-filter.py — фильтр Kubernetes Audit Log для выявления подозрительных событий

Использование:
  python3 audit-filter.py audit.log > audit-extract.json
  cat audit.log | python3 audit-filter.py
"""
import json
import sys


def is_suspicious(event):
    """Определяет, является ли событие подозрительным."""
    obj = event.get("objectRef", {}) or {}
    resource = obj.get("resource", "")
    verb = event.get("verb", "")
    subresource = obj.get("subresource", "")
    name = obj.get("name", "")
    username = event.get("user", {}).get("username", "")

    # 1. Доступ к secrets (кроме системных service account'ов)
    if resource == "secrets" and verb in ("get", "list") and username != "system:apiserver":
        return True, "secrets_access"

    # 2. Создание привилегированных подов
    if resource == "pods" and verb == "create":
        req = event.get("requestObject") or {}
        containers = req.get("spec", {}).get("containers", [])
        for c in containers:
            sc = c.get("securityContext") or {}
            if sc.get("privileged") is True:
                return True, "privileged_pod"

    # 3. kubectl exec в поды
    if subresource == "exec":
        return True, "exec_into_pod"

    # 4. Создание RoleBinding
    if resource == "rolebindings" and verb == "create":
        req = event.get("requestObject") or {}
        role_ref = req.get("roleRef", {}) or {}
        if role_ref.get("name") == "cluster-admin":
            return True, "clusteradmin_rolebinding"
        return True, "rolebinding_create"

    # 5. SelfSubjectAccessReview (проверка прав)
    if resource and "selfsubjectaccessreview" in resource.lower():
        return True, "auth_check"

    # 6. Удаление ресурсов
    if verb == "delete":
        return True, "resource_deletion"

    return False, None


def format_event(event, event_type):
    """Форматирует событие для вывода."""
    obj = event.get("objectRef") or {}
    user = event.get("user") or {}
    resp = event.get("responseStatus") or {}

    return {
        "event_type": event_type,
        "auditID": event.get("auditID"),
        "stage": event.get("stage"),
        "timestamp": event.get("requestReceivedTimestamp"),
        "user": {
            "username": user.get("username"),
            "groups": user.get("groups"),
        },
        "sourceIPs": event.get("sourceIPs"),
        "userAgent": event.get("userAgent"),
        "objectRef": {
            "resource": obj.get("resource"),
            "subresource": obj.get("subresource"),
            "name": obj.get("name"),
            "namespace": obj.get("namespace"),
            "apiVersion": obj.get("apiVersion"),
        },
        "verb": event.get("verb"),
        "requestURI": event.get("requestURI"),
        "responseCode": resp.get("code"),
    }


def main():
    audit_log = sys.argv[1] if len(sys.argv) > 1 else "/dev/stdin"

    suspicious = []
    with open(audit_log, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
                is_sus, event_type = is_suspicious(event)
                if is_sus:
                    suspicious.append(format_event(event, event_type))
            except json.JSONDecodeError:
                continue

    output = {"suspicious_events": suspicious}
    print(json.dumps(output, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
