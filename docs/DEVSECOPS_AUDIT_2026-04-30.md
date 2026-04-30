# DevSecOps Audit — rpm-ostree daemon, container orchestration, post-install, and CI/CD signals

## 1) rpm-ostree daemon policy
- Current policy in image payload:
  - `AutomaticUpdatePolicy=stage`
  - `IdleExitTimeout=300`
- Assessment: good immutable-desktop baseline; staging reduces disruptive live transitions.
- Improvement path:
  - Keep staging policy.
  - Add periodic runtime validation (`postinstall-healthcheck.sh`).

## 2) Container orchestration evolution (multi-project support)
- Added rootless Podman network baseline under `containers.conf.d` with Netavark + dedicated subnet pools.
- Benefit: lowers collision probability when multiple compose/podman projects run concurrently.
- Follow-up recommendations:
  - Add `podman system connection` profiles per project domain.
  - Add per-project `.env` templates for explicit network names.

## 3) Post-install script review
- Added non-destructive `postinstall-healthcheck.sh` to validate:
  - rpm-ostreed staged policy file
  - topgrade timer visibility/enabled
  - podman binary + info
- Script is idempotent and read-only.

## 4) CI/CD execution data analysis
- Current workflows lack a dedicated metrics export path.
- Recommendation:
  - Add a scheduled workflow that queries run durations/failures via `gh api` and stores JSON artifacts for trend analysis.
  - Track at minimum: p50/p95 duration, failure rate per workflow, retry frequency.

## Rollback
```bash
sudo bootc rollback
sudo systemctl reboot
```
