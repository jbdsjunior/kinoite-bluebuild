# Security Audit Log — kinoite-bluebuild

**Last Audit:** April 2026 (Cycle 2)
**Kernel Baseline:** 6.19 (Fedora 43)
**Scan Result:** CLEAN — no prohibited configurations detected

> **Canonical baseline:** [`docs/SECURITY_AUDIT.md`](../../docs/SECURITY_AUDIT.md)
> **Security rules:** [`agent/rules/SECURITY.md`](../rules/SECURITY.md)

---

## Change Log

| Date       | Cycle   | Changes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| April 2026 | Cycle 1 | Added 10 sysctl params; 3 kernel boot args (`init_on_alloc=1`, `init_on_free=1`, `slab_nomerge`); `tcp_timestamps=0` → **forbidden** per Red Hat RHEL 10                                                                                                                                                                                                                                                                                                                                                                                                                        |
| April 2026 | Cycle 2 | **FINDING-03:** FallbackDNS rejected — user network only supports Cloudflare DoT; **FINDING-08:** Separate topgrade lock files (`topgrade-system.lock`, `topgrade-flatpak.lock`, `topgrade-boot.lock`); **FINDING-13:** yq via `dcarbone/install-yq-action` (supply chain); **FINDING-15:** Mattraks pinned by SHA `b301838`; **FINDING-17:** `amd_iommu=on` → `common-base.yml`, `kvm_amd.*` + `iommu=pt` → `common-kvm.yml`; **INFO-01:** Audit clarity notes for kernel-default sysctls; **FINDING-06:** N/A (already HTTPS)                                                 |
| April 2026 | Cycle 4 | **KISS:** Merged standalone kargs from `common-base.yml` into `common-kargs.yml` (one file for all non-KVM kargs). Scan: **CLEAN**.                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| April 2026 | Cycle 5 | **FINDING-01:** `mikefarah/yq@master` → pinned to `@v4.52.5` (supply chain security); **FINDING-02:** `prepare-root.conf` missing explicit `fs-verity=force` — added; **FINDING-03:** `rclone/global-exclude.txt` — added sensitive file exclusions (`.env`, `*.key`, `*.pem`, `id_rsa`, `*.secret`); **FINDING-04:** `build_chunked_oci: false` → `true` (GHCR/quay.io support mature, ~40% update size reduction); **FINDING-05:** `mitigations=auto` — validated per LWN.net 2025, no change needed (auto = all mitigations active); Scan: **CLEAN** — 0 prohibited configs. |

---

## Rejected Changes

| Date       | Finding                     | Rationale                                                                 |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| April 2026 | FINDING-03 (FallbackDNS)    | User network only supports Cloudflare DoT; other providers non-functional |
| April 2026 | FINDING-06 (HTTPS GPG keys) | N/A — all repo URLs already use HTTPS                                     |
