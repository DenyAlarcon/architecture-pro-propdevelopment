# Task7: PodSecurity + Gatekeeper

## Что внутри

- `01-create-namespace.yaml` — namespace `audit-zone` с PodSecurity `restricted`.
- `insecure-manifests/` — 3 небезопасных pod-манифеста (privileged, hostPath, root UID 0).
- `secure-manifests/` — 3 исправленных pod-манифеста.
- `gatekeeper/constraint-templates/` и `gatekeeper/constraints/` — правила и ограничения OPA Gatekeeper.
- `verify/verify-admission.sh` — полный прогон проверки требований задания.
- `verify/validate-security.sh` — точечная проверка активных политик.
- `audit-policy.yaml` — политика аудита (дополнительный артефакт по шаблону задания).

## Быстрый запуск проверки

```bash
bash Task7/verify/verify-admission.sh
bash Task7/verify/validate-security.sh
```
