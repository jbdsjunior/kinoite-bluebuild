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
- **CPU & Memória:** `amd-pstate-epp` nativo; ZRAM `zstd` dimensionado como `min(ram / 2, 32 GB)` (`60-zram-policy.conf`) e `DefaultLimitMEMLOCK=infinity` para alocação direta de LLMs (`--mlock`).
- **GPU & Gráficos:** Mesa `radv` (Vulkan 1.4), VA-API no KWin/Wayland e contêineres ROCm/HIP via CDI (`/etc/cdi/amdgpu.yaml` com `HSA_OVERRIDE_GFX_VERSION=10.3.0`).
- **Armazenamento:** Btrfs com atributo NoCOW `+C` estrito via tmpfiles `h` em diretórios de VMs e contêineres (`60-io-tuning-system.conf` e `60-io-tuning-user.conf`).
- **Periféricos & Firmware:** Acesso direto de usuário via udev `uaccess` em `70-peripherals.rules`; modo UEFI puro com Secure Boot e fTPM 2.0 nativos.

---

## 4. Invariantes de Engenharia do Sistema

- **Boot & Kernel Arguments:**
  - Linha de boot limpa declarativa via Bootc ([`recipes/common-kargs.yml`](recipes/common-kargs.yml)): `initcall_blacklist=simpledrm_platform_driver_init`, blacklist de `nouveau` e `nvidia_drm` (no flavor dual). O módulo `akmods` injeta `/usr/lib/bootc/kargs.d/00-bluebuild-nvidia-kargs.toml` com `nvidia-drm.modeset=1`; como o módulo `kargs` do BlueBuild é append-only, esse arquivo é removido por script em [`recipes/common-drivers-nvidia.yml`](recipes/common-drivers-nvidia.yml) e o `modeset` é proibido no flavor dual. Proibido kargs redundantes (`preempt=full`, `nowatchdog`, `tsc=reliable`, `amd_iommu=on`, `iommu=pt`, `amd_pstate=active`).
- **Segurança Física (Padrão Zero Unauthenticated Recovery):**
  - Proibido bypass de autenticação em consoles de emergência (`sulogin` obrigatório; proibido `SYSTEMD_SULOGIN_FORCE=1`).
  - Desbloqueio TPM2 em dois fatores: fTPM + PIN vinculado a PCR 7 + 14 via [`kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm).
  - Bloqueio de bootloader via `grub2-setpassword` documentado em [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).
- **Sysctl, ZRAM & Blindagem TuneD:**
  - `90-kernel-tuning.conf`, `90-memory-fs-tuning.conf`, `90-network-tuning.conf`: REISUB habilitado (`sysrq=1`), panic window 20s, TCP BBR + `fq`, ZRAM zstd `min(ram / 2, 32 GB)` com `vm.swappiness=150`, sem `ip_forward` global.
  - Symlinks em `/etc/sysctl.d/` para `/usr/lib/sysctl.d/` via `60-sysctl-protection.conf` blindam os sysctls contra sobrescrita do `tuned-ppd`.
- **Systemd, Resiliência de Logs & Timers:**
  - Journald com `SyncIntervalSec=60s` em NVMe Gen4 reduzindo perda de logs pré-queda. Boot silencioso com `ShowStatus=error` e GRUB Auto-Hide zero-touch via `kinoite-boot-init.service`.
  - Timers de atualização e manutenção com monotonicidade limpa e prioridade idle (`Nice=19`, `CPUSchedulingPolicy=idle`).
- **Armazenamento Btrfs NoCOW:**
  - Atributo `+C` estritamente via diretiva não-recursiva `h` em tmpfiles de sistema e usuário para pastas de VMs, contêineres e caches FUSE.
- **Rclone FUSE:**
  - Unidade `rclone@.service` montando em `/run/user/$UID/cloud/`, isolado do Baloo, cache VFS 10 GB persistente em NoCOW, tolerância a encerramento limpo (`SuccessExitStatus=143`).
- **Áudio PipeWire:**
  - Stack 100% nativa upstream do Fedora Kinoite (PipeWire/WirePlumber). Negociação automática de taxas e quantum dinâmico no grafo nativo.
- **GPU IA, Dual Flavor & Isolamento NVIDIA:**
  - Flavor AMD (`recipe-amd.yml`): puramente Mesa RADV/RadeonSI upstream, 100% livre de binários ou drivers NVIDIA.
  - Flavor Dual (`recipe-dual.yml`): aceleração display na RX 6600 XT; GPU NVIDIA opera exclusivamente como aceleradora headless de IA/CUDA via CDI (`nvidia-cdi-refresh.service`). Módulo `nvidia-drm` desativado no modprobe e dracut para impedir conflitos no Libvirt/QEMU e GNOME Boxes. Certificado MOK versionado em `files/nvidia/`.
  - LLMs locais com `DefaultLimitMEMLOCK=infinity` e browsers Flatpak com Wayland nativo e VA-API via overrides centralizados.
- **Supply Chain & Assinatura de Imagem:**
  - Transição em duas etapas: bootstrap inicial provisiona chaves Cosign (`/etc/pki/containers/`); switch pós-boot ativa imposição estrita (`--enforce-container-sigpolicy` em `ostree-image-signed`).

---

## 5. CI/CD & Governança

- **Pipelines GitHub Actions:** `check-updates.yml` (cron cada 6h) verifica upstream digest e despacha a matriz `flavor: [amd, dual]` de `build.yml`; `validate.yml` roda yamllint/shellcheck em PRs e `cleanup.yml` gerencia o ciclo de vida do GHCR (15 builds retidos).
- **Framework de Auditoria Canônica (7 Pilares):** Executado via `kinoite-optimize --audit` (ou `sys-optimize` para manutenção + auditoria) cobrindo Supply Chain/Cosign, Deriva Upstream, Btrfs NoCOW/ZRAM, Grafo PipeWire, GPU/CDI, Resiliência de Boot e Governança de Timers.

---

## 6. Rastreabilidade de Arquivos

Mapa por diretório — o conteúdo de cada árvore é a fonte de verdade; decisões e pendências ficam em [`docs/SIMPLIFICATION.md`](docs/SIMPLIFICATION.md).

| Subsistema | Diretório / Arquivo raiz |
| :--- | :--- |
| **Receitas OCI & Repositórios** | [`recipes/`](recipes/) (`recipe-amd.yml`, `recipe-dual.yml`, `common-*.yml`), [`files/dnf/`](files/dnf/) |
| **Sistema & Hardware (host overlay)** | [`files/system/`](files/system/) — `usr/lib/{sysctl.d,systemd,tmpfiles.d,udev,modprobe.d,modules-load.d}`, `usr/bin/`, `usr/share/`, `etc/` |
| **Flavor Dual (NVIDIA headless)** | [`files/nvidia/`](files/nvidia/), [`recipes/common-drivers-nvidia.yml`](recipes/common-drivers-nvidia.yml) |
| **CI/CD & Governança** | [`.github/workflows/`](.github/workflows/), [`.github/dependabot.yml`](.github/dependabot.yml), [`.githooks/`](.githooks/) |
| **Documentação** | [`README.md`](README.md), [`SECURITY.md`](SECURITY.md), [`AGENTS.md`](AGENTS.md), [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), [`docs/SIMPLIFICATION.md`](docs/SIMPLIFICATION.md) |

---

## 7. Documentação, Idioma & Anti-Deriva

- **Política de Idioma:** [`README.md`](README.md) e [`SECURITY.md`](SECURITY.md) em inglês (público); `AGENTS.md`, [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) e [`docs/SIMPLIFICATION.md`](docs/SIMPLIFICATION.md) em pt-BR (operação local).
- **Fonte Canônica Única:** `AGENTS.md` permanece monolítico como autoridade absoluta para agentes. Toda mudança de invariante exige atualização simultânea em `AGENTS.md` no mesmo commit. Decisões de simplificação e pendências ficam em [`docs/SIMPLIFICATION.md`](docs/SIMPLIFICATION.md), sem duplicar a matriz de diretórios.
- **Versionamento Flutuante:** `image-version: latest` é intencional (rolling). A reprodutibilidade é garantida pelo hash do digest upstream resolvido a cada 6h via CI.
