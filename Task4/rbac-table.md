# Роли Kubernetes RBAC

## Организационная структура

| Роль | Уровень | Полномочия                                                                                          | Пользователи | Группа (organizational unit) |
|---|---|-----------------------------------------------------------------------------------------------------|---|---|
| **cluster-admin** | Кластер | Полный доступ ко всем ресурсам (включая Secrets, Nodes, ClusterRoles). Управление RBAC.             | `devops-oleg` | `platform-team` |
| **namespace-editor** | Namespace | CRUD подов, деплоев, сервисов, ингрессов, ConfigMap. Без Secrets и RBAC.                            | `dev-alice` | `developers` |
| **namespace-viewer** | Namespace | Только чтение (get/list/watch) подов, деплоев, сервисов, ингрессов. Без Secrets и логов выполнения. | `viewer-bob` | `qa-team` |

## Матрица доступа

| Ресурс | cluster-admin | namespace-editor | namespace-viewer |
|---|---|---|---|
| Pods | \* | get, list, watch, create, update, delete | get, list, watch |
| Deployments | \* | get, list, watch, create, update, delete | get, list, watch |
| Services | \* | get, list, watch, create, update, delete | get, list, watch |
| Ingresses | \* | get, list, watch, create, update, delete | get, list, watch |
| ConfigMaps | \* | get, list, watch, create, update, delete | get, list, watch |
| Secrets | \* | — | — |
| Nodes | \* | — | — |
| Namespaces | \* | — | — |
| Roles / RoleBindings | \* | — | — |
| Events | \* | get, list, watch | get, list, watch |
| Pod logs | \* | get | — |
