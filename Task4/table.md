| Роль  | Права роли | Группы пользователей |
| --- | --- | --- |
| `cluster-observer` | Только чтение (`get`, `list`, `watch`) для `pods`, `services`, `deployments`, `statefulsets`, `daemonsets`, `jobs`, `cronjobs`, `ingresses`, `configmaps`, `events`, `namespaces`. | Операционная команда (менеджеры): `User manager1`. |
| `cluster-operator` | Настройка кластера для прикладных сервисов: чтение и изменение (`get`, `list`, `watch`, `create`, `update`, `patch`, `delete`) для `pods`, `services`, `deployments`, `statefulsets`, `daemonsets`, `jobs`, `cronjobs`, `ingresses`, `configmaps`, `secrets`, `hpa`. | Функциональная команда (DevOps и инженеры эксплуатации): `User devops1`. |
| `secret-auditor` | Привилегированный аудит: чтение (`get`, `list`, `watch`) для `secrets`, `serviceaccounts`, `roles`, `rolebindings`, `clusterroles`, `clusterrolebindings`, `events`, `namespaces`. | Специалист по ИБ: `User secops1`. |
