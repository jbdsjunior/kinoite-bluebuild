# Plano de Simplificação e Auditoria (`kinoite-bluebuild`)

Documento de referência da auditoria de simplificação do projeto. Registra **o que foi enxugado**,
**por que** e **o que permanece em aberto**, sempre alinhado à filosofia do Fedora Kinoite:
imagem atômica enxuta, apps GUI em Flatpak, ferramentas CLI/desenvolvimento em Distrobox ou
container, e configuração declarativa (bootc/kargs/tmpfiles/systemd) em vez de mutação em runtime.

> Última auditoria: novembro/2026 — Fedora Kinoite 45, imagem com 2162 pacotes.
> Método: leitura das receitas + inspeção da imagem em execução (`/run/host`: rpmdb, `/usr/lib/bootc/kargs.d`,
> units, udev) + comparação com o manifesto oficial do base (`fedora-atomic-desktops-devel`).

---

## 1. Modelo de decisão adotado

| Camada | O que pertence | Exemplos |
| :--- | :--- | :--- |
| **Imagem (`recipes/` + `files/system/`)** | SO, firmware, integração de hardware, systemd, sysctl, udev, security, ferramentas que precisam de privilégio/host | `tailscale`, `distrobox`, `rclone` (FUSE), `swtpm`, `kf6-kimageformats` |
| **Flatpak** | Qualquer aplicativo com GUI | navegadores, VS Code, OnlyOffice, Obsidian |
| **Distrobox / container** | CLIs de desenvolvimento, diagnósticos, stacks GPU (OpenCL/ROCm), linguagens | `clinfo`, `mesa-libOpenCL`, `docker-compose`, toolchains |
| **Nunca** | Duplicar o que o upstream já entrega, ou mutar o sistema em runtime | units idênticas às do Fedora, `rpm-ostree kargs` em script |

Regra de bolso: **se remove a versão "free" do Fedora para colocar a "freeworld", é hardware; se é
utilitário de terminal, é container; se tem janela, é Flatpak.**

---

## 2. O que foi simplificado nesta rodada

### 2.1 Dead code / duplicação com o upstream

| Item | Ação | Motivo |
| :--- | :--- | :--- |
| `files/system/usr/lib/systemd/{system,user}/flatpak-*-update.{service,timer}` (4 arquivos) | **removidos** | Byte-idênticos aos units do pacote `flatpak` do Fedora 45. As units continuam habilitadas via `recipes/common-systemd.yml`. |
| `vulkan-tools`, `ksshaskpass`, `kio-admin` em `recipes/*.yml` | **removidos** | Já fazem parte do base Kinoite (`kinoite-shared.yaml` / `packages/kinoite.yaml`). |
| `replace: ocl-icd ← OpenCL-ICD-Loader` | **removido** | Só existia por causa de `mesa-libOpenCL`/`clinfo`, que saíram da imagem. |
| `mesa-libOpenCL` (43,8 MB) + `clinfo` (0,2 MB) | **removidos** | OpenCL de host é nicho; a stack ROCm/OpenCL vive no container. Economia ≈ 44 MB. |
| `git` (completo) | **removido** | O base instala `git-core` **de propósito** para não puxar Perl. A camada adicionava `perl-Git`/`perl-libs` (~17 MB) sem função. |
| Mascaramento de `systemd-remount-fs.service` | **removido** | Workaround legado de Silverblue/rpm-ostree; em bootc+composefs o `/` é somente leitura e o mask podia impedir remontagem de `/boot` conforme o fstab. |

### 2.2 Kernel arguments (flavor dual)

- O módulo `akmods` do BlueBuild injeta `00-bluebuild-nvidia-kargs.toml` com `nvidia-drm.modeset=1`,
  contradizendo a operação **headless** da GPU NVIDIA.
- O módulo `kargs` é *append-only* (o schema não tem `remove`), portanto a correção é um módulo
  `script` em `recipes/common-drivers-nvidia.yml` que apaga o arquivo injetado e deixa os blacklists
  canônicos em `common-kargs.yml`.
- Efeito: `nvidia-drm.modeset=1` deixa de aparecer na linha de boot do `kinoite-dual`.

### 2.3 Systemd, timers e limites

| Arquivo | Antes | Depois | Motivo |
| :--- | :--- | :--- | :--- |
| `journald.conf.d/60-journald-resilience.conf` | `SyncIntervalSec=30s` | `60s` | 30s multiplicava metadados de escrita no NVMe sem ganho real; 60s ainda é 5× mais resiliente que o default (5m). |
| `bootc-fetch-apply-updates.timer.d/override.conf` | checagem a cada 45 min | `OnBootSec=1h` / `OnUnitInactiveSec=8h` | Alinhado ao upstream, evita pull de imagem completa em todo boot e mantém cadência previsível. |

### 2.4 Configurações de sistema

| Item | Antes | Depois |
| :--- | :--- | :--- |
| `usr/lib/tmpfiles.d/60-flatpak-overrides.conf` | `C+` (sobrescreve todo boot) | `C` (só cria se ausente) — preserva customização do usuário |
| `usr/share/user-tmpfiles.d/70-rclone-env.conf` | `C+` | `C` |
| `resolved.conf.d/60-dns-overrides.conf` | DNS fixo (Control D) + `DNSOverTLS=yes` + `DNSSEC=no` | Apenas `MulticastDNS=resolve` / `LLMNR=no`; DoT privado virou receita opt-in no `POST_INSTALL.md` |
| `udev/rules.d/70-peripherals.rules` | periféricos + `kfd`/`renderD*` + symlink PCI hardcoded + scheduler NVMe | apenas periféricos (hidraw). `kfd`/`renderD*` já são `0666 group render` no upstream e NVMe já usa `none` |
| `etc/fonts/conf.d/64-font-rendering.conf` | ~200 linhas de aliases Apple/Microsoft | ~70 linhas: rendering + aliases genéricos + monospace/serif |
| `etc/xdg/kdeglobals` | look-and-feel, accent, single-click (política global) | apenas defaults de diálogo/preview; preferências pessoais movidas para `etc/skel/.config/kdeglobals` |
| `etc/xdg/kiorc` | `ConfirmTrash=false` + `ConfirmDelete=true` (contraditório) | `ConfirmTrash=true` |
| `profile.d/50-shell-env-overrides.sh` | rodava `fastfetch` em todo terminal | prompt + zoxide + fzf apenas |
| `environment.d/60-kinoite-environment.conf` | `HSA_OVERRIDE_GFX_VERSION` e `ELECTRON_OZONE_PLATFORM_HINT` | **Preservados:** `HSA_OVERRIDE_GFX_VERSION=10.3.0` é indispensável para ROCm/PyTorch na RX 6600 XT (gfx1032 não tem binários upstream no ROCm) e `ELECTRON_OZONE_PLATFORM_HINT=auto` previne texto borrado em apps Electron sob Wayland |
| `usr/share/browser-configs/chromium-flags.conf` | ~14 flags | 8 flags essenciais (Wayland, VA-API, `--ignore-gpu-blocklist` e `--enable-gpu-rasterization` para prevenir fallback para software, mais redução de telemetria) |
| `usr/lib/systemd/user/rclone@.service` | `MemoryMax=4G`, cache 15G, min-free 15G | sem `MemoryMax`, cache 10G, min-free 5G |

### 2.5 Scripts operacionais

**`kinoite-optimize`** (reescrito, ~250 linhas):

- Mantém: sysctl, tmpfiles/NoCOW, GRUB auto-hide, `fstrim`, retenção de journal, prune de Flatpak/Podman, `rpm-ostree cleanup -m`.
- **Removeu** operações destrutivas/surpresa:
  - `rclone dedupe` na nuvem (podia apagar arquivos do Google Drive);
  - `btrfs balance start` em toda execução (I/O pesado; agora é instrução manual);
  - defrag automático de imagens de VM (agora só relatório);
  - mutação de kargs via `rpm-ostree kargs` em runtime (duplicava/brigava com os kargs declarativos do bootc).
- Auditoria dos 7 pilares agora é **dinâmica**: detecta render nodes via `/sys/class/drm`, em vez de
  IDs PCI hardcoded (`pci-0000:0c:00.0`, `pci-0000:09:00.0`).

**`kinoite-setup-tpm`**:

- Corrigido o bug de initramfs: em bootc/rpm-ostree o `dracut --force /boot/initramfs-<kver>.img`
  escrevia no symlink do deployment ativo. Agora usa `rpm-ostree initramfs --enable` (regeneração
  por deployment) e só cai para `dracut` fora de sistemas ostree.
- Corrigido o `sed` do `/etc/crypttab`: appendava `,tpm2-device=auto` no campo de **senha**.
  Agora o campo de opções é editado corretamente via `awk` (idempotente).

### 2.6 CI/CD

| Antes | Depois |
| :--- | :--- |
| `build-amd.yml` + `build-dual.yml` (95% idênticos) | `build.yml` com matrix `flavor: [amd, dual]` e input `flavor` |
| `check-updates.yml` a cada 2h | a cada 6h (o base Kinoite rebuilda ~1×/dia) |
| duplicidade de trigger mitigada por `gh run list` | cache key `upstream-<flavor>-<digest>` + concurrency group por flavor |
| nenhuma validação em PR | `validate.yml`: yamllint + shellcheck + `bash -n` |

---

## 3. Auditoria das Pendências (Impacto no Uso Diário)

Avaliação de cada item pendente sob a ótica de usabilidade, estabilidade e melhores práticas:

| Pacote / item | Tamanho | Veredito de Usabilidade | Justificativa técnica e impacto no uso |
| :--- | ---: | :--- | :--- |
| `rclone` + `rclone@.service` + envs + NoCOW | **115 MB** | **MANTER (Invariante)** | **Remover quebra o uso:** provê a montagem FUSE em `/run/user/$UID/cloud/` integrada ao Dolphin (AGENTS.md §4). O `kio-gdrive` não cobre OneDrive/Proton nem permite caminhos POSIX transparentes para ferramentas CLI. |
| `docker-compose` + `podman-docker` + `/etc/containers/nodocker` | 30 MB | **MANTER** | **Remover quebra o uso:** diversos scripts, IDEs e agentes esperam o binário `docker`. `podman-docker` fornece compatibilidade transparente sem exigir daemon raiz. |
| `topgrade` (+ `files/dnf/terra.repo`) | 14 MB | **MANTER** | **Remover quebra o uso:** provê o comando unificado `update` (alias configurado no shell) que atualiza bootc, flatpaks, distroboxes e firmware em um passo só. |
| `starship` | 12 MB | **MANTER** | **Remover quebra o uso:** é o prompt canônico customizado do shell interativo. O custo em disco é ínfimo. |
| `gnome-boxes` + entradas NoCOW | ~15 MB | **MANTER (Opcional)** | Seguro de remover se quiser economizar 15 MB, pois `virt-manager` cobre tudo; manter não causa nenhum conflito. |
| `elisa-player` (mantendo `haruna`) | 6,6 MB | **MANTER (Opcional)** | Seguro de remover pois `haruna` toca áudio e vídeo via MPV/Wayland; manter preserva player de biblioteca musical dedicado. |
| `@virtualization` (81 pacotes) | — | **MANTER** | **Remover arriscado:** o grupo `@virtualization` traz firmwares OVMF (UEFI para VMs), QEMU e virt-manager com dependências resolvidas; desmembrar manualmente arrisca quebrar VMs. |
| `toolbox` (base) vs `distrobox` (camada) | — | **MANTER AMBOS** | `toolbox` já vem embutido na imagem base do Kinoite (custo zero na camada); `distrobox` é essencial para execução de ferramentas de IA (OpenCode, agentes). |
| 21 Flatpaks padrão | — | **MANTER** | Workstation provisionada "out-of-the-box" pronta para uso com navegadores e utilitários. |
| `60-sysctl-protection.conf` (3 symlinks `/etc` → `/usr`) | — | **MANTER** | Protege os sysctls otimizados de kernel/memória contra sobrescrita de perfis de energia do `tuned-ppd`. |
| Debloat com 22 entradas | — | **MANTER** | Garante que pacotes legados indesejados não entrem na imagem base. |
| `files/system/etc/cdi/amdgpu.yaml` com PCI `0000:0c:00.0` | — | **MANTER** | Corresponde exatamente à GPU física RX 6600 XT no slot PCIe principal da máquina homologada (Zen 3 + X570, AGENTS.md §3). Evita falha do CDI em build-time. |
| `tesseract-langpack-por` órfão | — | **MANTER (Neutro)** | Pacote residual leve que não causa conflito algum. |

> **Conclusão sobre as Pendências:** Nenhuma das remoções agressivas sugeridas nas pendências deve ser aplicada de forma cega, pois comprometeria recursos essenciais do seu ambiente de trabalho (rclone FUSE, comando `update`, prompt starship, compatibilidade `docker`, e aceleração de VMs). O sistema permanece no equilíbrio ideal entre imagem atômica enxuta e estação de trabalho completa.

---

## 4. Documentação

- `AGENTS.md §6`: matriz de rastreabilidade (10 linhas gigantes, alto custo de manutenção) substituída por
  mapa de **diretórios** por subsistema. Detalhe fino fica nos próprios diretórios e neste documento.
- `README.md`: corrigidos badges (`build.yml`), contagem de fases de manutenção e fórmula do ZRAM.
- `docs/POST_INSTALL.md`: removida a duplicação do Quick Start (link para o README), adicionada a receita
  opt-in de DNS privado e nota sobre initramfs/PCR 14 no TPM.
- `SECURITY.md`: cadência real de build (6h) e verificação Cosign.
- `docs/SIMPLIFICATION.md`: este documento (decisões, pendências e validação).

---

## 5. Validação antes do deploy

```bash
# 1) Sintaxe e lint (roda também no CI em validate.yml)
yamllint -d '{extends: relaxed, rules: {line-length: disable}}' recipes .github/workflows
shellcheck -S warning files/system/usr/bin/* files/system/etc/profile.d/*.sh
for f in files/system/usr/bin/* files/system/etc/profile.d/*.sh; do bash -n "$f"; done

# 2) Build local (opcional)
bluebuild build recipes/recipe-amd.yml

# 3) Transição e auditoria no host
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
sudo bootc status
kinoite-optimize --audit

# 4) Confirmar kargs limpos no flavor dual
cat /proc/cmdline | tr ' ' '\n' | grep -E 'nvidia|nouveau|simpledrm'

# 5) Rollback se necessário
sudo bootc rollback && systemctl reboot
```

Critérios de aceite:

1. Boot completo em Wayland, login e áudio funcionando.
2. `kinoite-optimize --audit` sem `[WARN]` de kargs, NoCOW ou assinatura.
3. `rpm -qa | wc -l` menor que 2162 e ausência de `perl-libs`, `mesa-libOpenCL`, `clinfo`.
4. `systemctl list-timers` com bootc/flatpak/podman/manutenção ativos.
5. Flavor dual: `nvidia_drm` ausente de `lsmod` e CUDA/`nvidia-smi` operante.

---

## 6. Anexo — como medir o impacto

```bash
# Pacotes instalados na imagem
rpm -q --qf '%{NAME}\n' | wc -l

# Tamanho da camada customizada (aproximado por pacote)
rpm -q --qf '%{NAME} %{SIZE}\n' | sort -k2 -nr | head -20

# Duplicação de kargs no bootc
ls /usr/lib/bootc/kargs.d/ && cat /usr/lib/bootc/kargs.d/*.toml

# Units que sobrescrevem o upstream (deveria ser vazio)
for f in $(cd files/system && find usr/lib/systemd -type f); do
  diff -q "files/system/$f" "/usr/$f" >/dev/null 2>&1 && echo "idêntico ao upstream: $f"
done
```
