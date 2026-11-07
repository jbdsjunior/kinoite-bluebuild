# Diretrizes e Invariantes do Sistema (`AGENTS.md`)

Fonte canônica única (*Single Source of Truth*) para agentes que operam no repositório `kinoite-bluebuild`.

---

## 1. Versionamento Git & Qualidade

- **Conventional Commits:** `<type>(<scope>): <descrição no presente>` (`feat`, `fix`, `docs`, `refactor`, `chore`, `perf`) com corpo em bullets detalhando decisões e impacto. Escopo alfanumérico único sem vírgulas.
- **Staging Estrito & Árvore Limpa:** Adicionar arquivos explicitamente (`git add <arq1> <arq2>`); nunca usar `git add .` cego. Auditar `git status` e `git diff --cached` antes do commit; finalizar sempre com `git push origin <branch>` e working tree limpa.
- **Hook Ativo:** Garantir `.githooks` configurado (`git config core.hooksPath .githooks`).

---

## 2. Princípios de Execução & Economia de Tokens

- **Prioridade:** Segurança > Performance > Conveniência. Zero redundância com defaults do Fedora, systemd ou kernel. Proibido downgrade de pacotes e configs mortas (KISS/DRY).
- **Modos de Execução:**
  - **Fast-Path (Padrão para Tarefas Diárias):** Pacotes, flags de browser, sysctl pontual, scripts CLI, ajustes de doc e fixes: diagnosticar, implementar cirurgicamente, validar sintaxe/integridade, commit, push e resposta concisa. Sem criar artefatos de plano.
  - **Full-Plan (Sob Demanda com `/plan` ou Mudança Estrutural Crítica):** Reservado estritamente para quando o usuário solicitar explicitamente `/plan` ou para alterações de alto risco (bootargs, initramfs, LUKS). Criar plano técnico e aguardar aprovação.
- **Lean Output:** Respostas diretas e telegráficas. Sem preâmbulos ou despedidas. Relatório final conciso com arquivos alterados, status dos testes e hash do commit.
- **Higiene de Ferramentas:** Proibido ler arquivos grandes inteiros com `read_file`; usar filtros (`grep`, `head`, `tail`) ou delimitar `StartLine`/`EndLine`. Comandos ruidosos devem ser filtrados ou redirecionados.

---

## 3. Hardware Baseline

- **Estação Homologada:** AMD Ryzen 9 5950X (16C/32T, Zen 3), AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23 / RDNA2), Gigabyte X570 AORUS PRO WIFI, 64 GB DDR4, NVMe 1 TB PCIe Gen4 (Btrfs), Fedora Kinoite (`bootc:latest`, Wayland, KDE Plasma 6, Kernel 7.2+).
- **CPU & Memória:** `amd-pstate-epp` nativo; 32 GB ZRAM `zstd` (`60-zram-policy.conf`) e `DefaultLimitMEMLOCK=infinity` para alocação direta de LLMs (`--mlock`).
- **GPU & Gráficos:** Mesa `radv` (Vulkan 1.4), VA-API no KWin/Wayland e contêineres ROCm/HIP via CDI (`/etc/cdi/amdgpu.yaml` com `HSA_OVERRIDE_GFX_VERSION=10.3.0`).
- **Armazenamento:** Btrfs com atributo NoCOW `+C` estrito via tmpfiles `h` em diretórios de VMs e contêineres (`60-io-tuning-system.conf` e `60-io-tuning-user.conf`).
- **Periféricos & Firmware:** Acesso direto de usuário via udev `uaccess` em `70-peripherals.rules`; modo UEFI puro com Secure Boot e fTPM 2.0 nativos.

---

## 4. Invariantes de Engenharia do Sistema

- **Boot & Kernel Arguments:**
  - Linha de boot limpa declarativa via Bootc ([`recipes/common-kargs.yml`](recipes/common-kargs.yml)): `initcall_blacklist=simpledrm_platform_driver_init`, blacklist de `nouveau` e `nvidia-drm` (no flavor dual). Proibido kargs redundantes (`preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`).
- **Segurança Física (Padrão Zero Unauthenticated Recovery):**
  - Proibido bypass de autenticação em consoles de emergência (`sulogin` obrigatório; proibido `SYSTEMD_SULOGIN_FORCE=1`).
  - Desbloqueio TPM2 em dois fatores: fTPM + PIN vinculado a PCR 7 + 14 via [`kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm).
  - Bloqueio de bootloader via `grub2-setpassword` documentado em [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).
- **Sysctl, ZRAM & Blindagem TuneD:**
  - `90-kernel-tuning.conf`, `90-memory-fs-tuning.conf`, `90-network-tuning.conf`: REISUB habilitado (`sysrq=1`), panic window 20s, TCP BBR + `fq`, ZRAM zstd 32 GB com `vm.swappiness=150`, sem `ip_forward` global.
  - Symlinks em `/etc/sysctl.d/` para `/usr/lib/sysctl.d/` via `60-sysctl-protection.conf` blindam os sysctls contra sobrescrita do `tuned-ppd`.
- **Systemd, Resiliência de Logs & Timers:**
  - Journald com `SyncIntervalSec=30s` em NVMe Gen4 eliminando perda de logs pré-queda. Boot silencioso com `ShowStatus=error` e GRUB Auto-Hide zero-touch via `kinoite-boot-init.service`.
  - Timers de atualização e manutenção com monotonicidade limpa e prioridade idle (`Nice=19`, `CPUSchedulingPolicy=idle`).
- **Armazenamento Btrfs NoCOW:**
  - Atributo `+C` estritamente via diretiva não-recursiva `h` em tmpfiles de sistema e usuário para pastas de VMs, contêineres e caches FUSE.
- **Rclone FUSE:**
  - Unidade `rclone@.service` montando em `/run/user/$UID/cloud/`, isolado do Baloo, cache VFS 15 GB persistente em NoCOW, tolerância a encerramento limpo (`SuccessExitStatus=143`).
- **GPU IA, Dual Flavor & Isolamento NVIDIA:**
  - Flavor AMD (`recipe-amd.yml`): puramente Mesa RADV/RadeonSI upstream, 100% livre de binários ou drivers NVIDIA.
  - Flavor Dual (`recipe-dual.yml`): aceleração display na RX 6600 XT; GPU NVIDIA opera exclusivamente como aceleradora headless de IA/CUDA via CDI (`nvidia-cdi-refresh.service`). Módulo `nvidia-drm` desativado no modprobe e dracut para impedir conflitos no Libvirt/QEMU e GNOME Boxes. Certificado MOK versionado em `files/nvidia/`.
  - LLMs locais com `DefaultLimitMEMLOCK=infinity` e browsers Flatpak com Wayland nativo e VA-API via overrides centralizados.
- **Supply Chain & Assinatura de Imagem:**
  - Transição em duas etapas: bootstrap inicial provisiona chaves Cosign (`/etc/pki/containers/`); switch pós-boot ativa imposição estrita (`--enforce-container-sigpolicy` em `ostree-image-signed`).

---

## 5. CI/CD & Governança

- **Pipelines GitHub Actions:** `check-updates.yml` (cron cada 2h) verifica upstream digest e despacha matriz autônoma `build-amd.yml` e `build-dual.yml`. `cleanup.yml` gerencia ciclo de vida do GHCR (15 builds retidos).
- **Framework de Auditoria Canônica (6 Pilares):** Executado via `sys-optimize` ou `kinoite-optimize --audit` cobrindo Supply Chain/Cosign, Deriva Upstream, Btrfs NoCOW/ZRAM, GPU/CDI, Resiliência de Boot e Governança de Timers.

---

## 6. Rastreabilidade de Arquivos

| Subsistema | Arquivos de Implementação |
| :--- | :--- |
| **Receitas & Repositórios** | [`recipes/recipe-amd.yml`](recipes/recipe-amd.yml), [`recipes/recipe-dual.yml`](recipes/recipe-dual.yml), [`recipes/common-kargs.yml`](recipes/common-kargs.yml), [`recipes/common-*.yml`](recipes/), [`files/dnf/terra.repo`](files/dnf/terra.repo), [`files/dnf/tailscale.repo`](files/dnf/tailscale.repo) |
| **Sysctl, ZRAM & TuneD** | [`files/system/usr/lib/sysctl.d/90-*.conf`](files/system/usr/lib/sysctl.d/), [`files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`](files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf), [`files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf`](files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf), [`files/system/usr/lib/modules-load.d/60-bbr.conf`](files/system/usr/lib/modules-load.d/60-bbr.conf) |
| **Systemd, Boot & Timers** | [`files/system/usr/lib/systemd/system/`](files/system/usr/lib/systemd/system/), [`files/system/usr/lib/systemd/user/`](files/system/usr/lib/systemd/user/), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf), [`files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf`](files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf) |
| **Btrfs NoCOW & Flatpak** | [`files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`](files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf), [`files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`](files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf), [`files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`](files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf), [`files/system/usr/share/flatpak/overrides/`](files/system/usr/share/flatpak/overrides/) |
| **Rclone FUSE & KDE** | [`files/system/usr/lib/systemd/user/rclone@.service`](files/system/usr/lib/systemd/user/rclone@.service), [`files/system/usr/share/rclone/env/`](files/system/usr/share/rclone/env/), [`files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf`](files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf), [`files/system/etc/xdg/`](files/system/etc/xdg/) |
| **GPU IA, Limites & Browsers** | [`files/system/etc/cdi/amdgpu.yaml`](files/system/etc/cdi/amdgpu.yaml), [`files/nvidia/etc/pki/akmods/certs/akmods-ublue.der`](files/nvidia/etc/pki/akmods/certs/akmods-ublue.der), [`files/nvidia/etc/modprobe.d/blacklist-nouveau.conf`](files/nvidia/etc/modprobe.d/blacklist-nouveau.conf), [`files/nvidia/etc/modprobe.d/60-nvidia-headless.conf`](files/nvidia/etc/modprobe.d/60-nvidia-headless.conf), [`files/nvidia/etc/dracut.conf.d/99-nvidia-headless.conf`](files/nvidia/etc/dracut.conf.d/99-nvidia-headless.conf), [`recipes/common-drivers-nvidia.yml`](recipes/common-drivers-nvidia.yml), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf), [`files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/user.conf.d/60-kinoite-limits.conf), [`files/system/etc/security/limits.d/60-kinoite-limits.conf`](files/system/etc/security/limits.d/60-kinoite-limits.conf), [`files/system/usr/share/browser-configs/chromium-flags.conf`](files/system/usr/share/browser-configs/chromium-flags.conf), [`files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf`](files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf) |
| **Sessão, CLI & Manutenção** | [`files/system/usr/lib/environment.d/60-kinoite-environment.conf`](files/system/usr/lib/environment.d/60-kinoite-environment.conf), [`files/system/etc/fonts/conf.d/64-font-rendering.conf`](files/system/etc/fonts/conf.d/64-font-rendering.conf), [`files/system/etc/profile.d/`](files/system/etc/profile.d/), [`files/system/usr/share/konsole/`](files/system/usr/share/konsole/), [`files/system/usr/share/starship/starship.toml`](files/system/usr/share/starship/starship.toml), [`files/system/usr/bin/kinoite-optimize`](files/system/usr/bin/kinoite-optimize), [`files/system/usr/bin/kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm), [`files/system/etc/containers/nodocker`](files/system/etc/containers/nodocker) |
| **Segurança, Polkit & Udev** | [`files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`](files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf), [`files/system/usr/lib/modprobe.d/60-security-blacklist.conf`](files/system/usr/lib/modprobe.d/60-security-blacklist.conf), [`files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`](files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf), [`files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`](files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules), [`files/system/usr/lib/udev/rules.d/70-peripherals.rules`](files/system/usr/lib/udev/rules.d/70-peripherals.rules), [`files/system/usr/lib/firewalld/zones/tailscale.xml`](files/system/usr/lib/firewalld/zones/tailscale.xml) |
| **Documentação & CI/CD** | [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), [`README.md`](README.md), [`SECURITY.md`](SECURITY.md), [`.github/workflows/`](.github/workflows/), [`.github/dependabot.yml`](.github/dependabot.yml), [`.githooks/commit-msg`](.githooks/commit-msg) |

---

## 7. Documentação, Idioma & Anti-Deriva

- **Política de Idioma:** [`README.md`](README.md) e [`SECURITY.md`](SECURITY.md) em inglês (público); `AGENTS.md` e [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) em pt-BR (operação local).
- **Fonte Canônica Única:** `AGENTS.md` permanece monolítico como autoridade absoluta para agentes. Toda mudança de invariante exige atualização simultânea em `AGENTS.md` no mesmo commit.
- **Versionamento Flutuante:** `image-version: latest` é intencional (rolling). A reprodutibilidade é garantida pelo hash do digest upstream resolvido a cada 2h via CI.
