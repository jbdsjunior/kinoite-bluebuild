# Plano de Remediação — Auditoria Completa vs `AGENTS.md`

**Data:** 2026-10-01 · **Escopo:** todos os invariantes das seções 4–8 do `AGENTS.md`
**Metodologia:** auditoria estática do repositório (75 arquivos rastreados) + verificação empírica no host de produção (imagem implantada, kernel 7.2.8-200.fc44, bootc 1.16.13) + confirmação em fontes upstream (referência D-Bus do NetworkManager, `pipewire-props(7)`, ArchWiki/Chromium, código-fonte do bootc, presets do Fedora 44, kernel config do host).

---

## 1. Sumário executivo

| Categoria | Quantidade |
| :-- | :-- |
| Correções verificadas (repo) | 8 (F1–F8) |
| Ação de runtime no host | 1 (F10) |
| Conflito de política a documentar | 1 (F9) |
| Itens de decisão do proprietário | 7 (D1–D7) |
| Falsos positivos descartados com evidência | 6 (FP1–FP6) |
| Invariantes verificados conformes sem ação | 22 |

**Prioridade absoluta aplicada: Segurança > Performance > Conveniência.**

---

## 2. Correções verificadas (repo)

### F1 · fix(audio) — `bluez5.a2dp.ldac.quality` em seção incorreta
- **Arquivo:** `files/system/usr/share/wireplumber/wireplumber.conf.d/80-bluetooth-policy.conf`
- **Problema:** a chave está em `monitor.bluez.properties`. Segundo `pipewire-props(7)` e a documentação oficial do WirePlumber, `bluez5.a2dp.ldac.quality` é **propriedade de dispositivo**, aplicável via `monitor.bluez.rules` → `update-props`. Na seção de monitor é um *no-op* (a qualificação LDAC hoje vale apenas porque o default do PipeWire já é `"auto"`).
- **Correção:** mover a chave para um bloco `monitor.bluez.rules` com `matches = [{ device.name = "~bluez_card.*" }]` (padrão idêntico ao exemplo oficial). Mantém `bluez5.codecs`, `bluez5.enable-sbc-xq` (propriedades de monitor válidas) e `bluetooth.autoswitch-to-headset-profile = false` (well-known setting) inalterados.
- **Rollback:** `git revert <sha>`; a mudança é declarativa e entra no próximo deploy.

### F2 · chore(ci) — Pinagem SHA da action `blue-build/github-action`
- **Arquivo:** `.github/workflows/build-amd.yml`
- **Problema:** `uses: blue-build/github-action@v1` é a única action de terceiros referenciada por tag mutável — viola o invariante §7 (pinagem por SHA completo).
- **Correção:** `uses: blue-build/github-action@c295af864f2802fc6aea227507af43d35823db81 # v1` (commit apontado pela tag `v1` de 2026-09-14, resolvido via GitHub API). Dependabot passa a rastrear o SHA pelo comentário de versão.
- **Rollback:** `git revert <sha>`.

### F3 · chore(ci) — `persist-credentials: false` no checkout do `check-updates.yml`
- **Arquivo:** `.github/workflows/check-updates.yml`
- **Problema:** `build-amd.yml` já usa `persist-credentials: false`; `check-updates.yml` deixa credenciais persistidas no `git config` do runner sem necessidade (o job usa `gh` via `GH_TOKEN` de env).
- **Rollback:** `git revert <sha>`.

### F4 · refactor(systemd) — Habilitações redundantes com presets do Fedora
- **Arquivo:** `recipes/common-systemd.yml`
- **Evidência:** `/usr/lib/systemd/system-preset/90-default.preset` do Fedora 44 habilita `systemd-resolved.service`, `firewalld.service` e **todos** os sockets modulares do libvirt. Os presets são aplicados durante o build (comprovação empírica: `virtinterfaced.socket` está habilitado na imagem implantada sem constar na lista do repositório).
- **Correção:** remover da lista `enabled` (system): `systemd-resolved.service`, `firewalld.service`, `virtqemud.socket`, `virtnetworkd.socket`, `virtstoraged.socket`, `virtnodedevd.socket`, `virtproxyd.socket`, `virtsecretd.socket`, `virtnwfilterd.socket`.
- **Mantém (sem preset no Fedora — habilitação necessária):** `bootc-fetch-apply-updates.timer`, `flatpak-system-update.timer`, `podman-restart.service`, `podman-auto-update.timer`, `tailscaled.service` e os equivalentes de usuário (`flatpak-user-update.timer`, `podman-auto-update.timer`, `podman-restart.service`, `soar-upgrade-packages.timer`).
- **Mantém:** `masked: systemd-remount-fs.service` (verificado: **não** é mascarado por padrão no Kinoite 44; padrão uBlue comprovado).
- **Rollback:** `git revert <sha>`.

### F5 · refactor(sysctl) — Redeclaração de default do kernel
- **Arquivo:** `files/system/usr/lib/sysctl.d/90-kernel-tuning.conf`
- **Problema:** `fs.suid_dumpable = 0` é o default do kernel (§5: proibido redeclarar defaults). Os demais sysctls do arquivo são justificados (não-defaults com racional documentado).
- **Rollback:** `git revert <sha>`.

### F6 · refactor(sysctl) — `accept_ra` redundante com wildcard
- **Arquivo:** `files/system/usr/lib/sysctl.d/90-network-tuning.conf`
- **Problema:** `net.ipv6.conf.default.accept_ra = 2` é redundante — a linha `net.ipv6.conf.*.accept_ra = 2` já cobre `default` e `all`.
- **Rollback:** `git revert <sha>`.

### F7 · refactor(dns) — Defaults do systemd-resolved
- **Arquivo:** `files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`
- **Problema:** `Cache=yes` e `CacheFromLocalhost=no` são defaults do resolved (§5). Mantém-se o restante: `DNS=` (DoT Cloudflare), `FallbackDNS=` (DoT Quad9), `DNSSEC=allow-downgrade`, `LLMNR=no` (hardening real), `MulticastDNS=resolve` (mudança deliberada de comportamento).
- **Rollback:** `git revert <sha>`.

### F8 · refactor(flatpak) — Entrada morta no override do VS Code
- **Arquivos:** `files/system/usr/share/flatpak/overrides/com.visualstudio.code` (+ sincronização via tmpfiles)
- **Problema:** `xdg-run/docker.sock:ro` referencia socket inexistente (sistema podman-only; o socket de usuário é `xdg-run/podman`). Config morta → remoção proativa (§4).
- **Mantém:** `xdg-run/podman:ro` (funcional para rootless Podman/DevKits).
- **Rollback:** `git revert <sha>`.

---

## 3. Ação de runtime no host (fora do repositório)

### F10 · Kargs declarados na imagem nunca chegaram ao bootconfig (deadlock de bootstrap do bootc)
- **Evidência empírica:** `/proc/cmdline` e ambas as entradas BLS (`/boot/loader/entries/ostree-{1,2}.conf`) **não contêm** nenhum dos kargs declarados; `usr/lib/bootc/kargs.d/bluebuild-kargs.toml` **está presente** no deployment iniciado.
- **Causa-raiz (código-fonte `crates/lib/src/bootc_kargs.rs`):** bootc aplica aos novos deployments o **diff** entre o `kargs.d` do deployment atual e o da nova imagem. Como o conjunto é idêntico em todas as imagens desde a primeira implantação (feita por um bootc anterior ao suporte a `kargs.d`), o diff é vazio e os kargs ficam permanentemente fora do bootconfig. Instalações novas via `bootc install` não são afetadas.
- **Ação única no host (aplica ao deployment em execução e propaga como baseline):**
  ```bash
  sudo rpm-ostree kargs \
    --append=amd_pstate=active --append=iommu=pt --append=preempt=full \
    --append=btusb.enable_autosuspend=n \
    --append=slab_nomerge --append=page_alloc.shuffle=1 --append=vsyscall=none
  ```
  Reiniciar e validar com `cat /proc/cmdline`.
- **Rollback:** `sudo rpm-ostree kargs --delete=<karg>` (um `--delete` por karg) + reboot.
- **Repo:** adicionar etapa de validação `cat /proc/cmdline` ao health-check do `docs/POST_INSTALL.md` (WP5).

---

## 4. Conflito de política a documentar (runtime)

### F9 · tuned (`throughput-performance`) sobrepõe a política de memória da imagem
- **Evidência empírica:** `tuned` ativo com perfil `throughput-performance` (via `tuned-ppd`, backend PPD do KDE no Fedora 41+): `vm.swappiness=10` ao vivo, contra `vm.swappiness=150` declarado em `90-memory-fs-tuning.conf` (agressivo-ZRAM). O perfil também sobrepõe `vm.dirty_*` (40%/10% de 64 GB) sobre os valores da imagem (3%/10%).
- **Contexto:** tuned é componente do SO base (não remover sem quebrar os perfis de energia do Plasma). O perfil ativo decorre da escolha "Performance" do usuário no KDE.
- **Encaminhamento (D2):** (A) documentar a interação e manter a escolha de perfil do usuário — recomendado (KISS); ou (B) provisionar perfil custom do tuned que reconcilie a política (complexidade extra; troca manual de perfil no KDE pode reverter o estado).
- **Repo:** nota de documentação no `docs/POST_INSTALL.md`/`docs/TECHNICAL_ARCHITECTURE.md` (WP5).

---

## 5. Itens de decisão do proprietário (D1–D7) — **decididos em 2026-10-01**

| ID | Item | Decisão do proprietário |
| :-- | :-- | :-- |
| D1 | `image-version: latest` vs baseline "Kinoite 44" do AGENTS.md — `latest` causa upgrade de major version não auditado quando o Fedora 49 for publicado | **Manter `latest`** (rastreio automático de security updates da major corrente) |
| D2 | tuned × política de memória (F9) | **Documentar e aceitar** a escolha de perfil do usuário (nota incluída no POST_INSTALL §10 e TECHNICAL_ARCHITECTURE §5.1) |
| D3 | `net.ipv4.ip_forward=1` + `net.ipv6.conf.all.forwarding=1` (default do Fedora: 0; CIS recomenda desativado em workstation; libvirt/netavark habilitam dinamicamente quando necessário) | **Manter estático** (funcional para KVM/Podman/Tailscale) |
| D4 | `bluetooth.disable_ertm=1` — quirk legado de gamepads antigos; nenhum gamepad homologado; TWS áudio (A2DP/AVRCP) não usa ERTM | **Removido** (commit `8c87d32`); `btusb.enable_autosuspend=n` permanece |
| D5 | Higiene de pacotes: `pipewire-codec-aptx`, `twolame` + `vorbis-tools`, `wqy-zenhei-fonts` | **Remover `twolame`, `vorbis-tools` e `wqy-zenhei-fonts`** (commit `ec90f6f`); **manter `pipewire-codec-aptx`** para dispositivos aptX de terceiros |
| D6 | `DNSOverTLS=opportunistic` vs `yes` | **Manter `opportunistic`** (resiliência em redes que bloqueiam a porta 853) |
| D7 | SSHD: adicionar `PasswordAuthentication no` + `KbdInteractiveAuthentication no` (CIS) | **Aplicado** (commit `45434c5`) — acesso exclusivamente por chaves confirmado |

---

## 6. Falsos positivos descartados com evidência (sem ação)

| ID | Suspeita inicial | Evidência que a descarta |
| :-- | :-- | :-- |
| FP1 | Guarda `ExecCondition` (busctl/NM) com lógica invertida | Referência D-Bus NM: `NM_METERED_YES=1`, `GUESS_YES=3` (bloqueados ✓), `NM_CONNECTIVITY_{NONE=1, PORTAL=2, LIMITED=3}` (bloqueados ✓), `FULL=4`/`UNKNOWN=0` permitidos ✓ — idêntico à recomendação upstream ("tratar GUESS_YES como YES") |
| FP2 | `bootc update` seria verbo inválido | Alias documentado de `upgrade` (verificado em `bootc update --help`); staging sem `--apply` é correto para workstation (upstream aplicaria reboot forçado; aqui aplica via `ostree-finalize-staged` no shutdown) |
| FP3 | `StartLimitIntervalSec` fora de seção no `rclone@.service` | Está em `[Unit]` (linhas 7–8), correto |
| FP4 | `RCLONE_ONEDRIVE_DELTA` não existiria | Flag real no rclone 1.74.3 (teste positivo + controle negativo com flag inventada) |
| FP5 | Features de vídeo Chromium incorretas | `AcceleratedVideoDecodeLinuxGL`, `AcceleratedVideoDecodeLinuxZeroCopyGL`, `AcceleratedVideoEncoder` confirmadas na ArchWiki (válidas p/ Chromium ≥131/143) |
| FP6 | `amd_pstate=active`/`vsyscall=none`/`preempt=full` seriam redundantes | Kernel config do host: default é `amd_pstate=guided` (MODE=3), `vsyscall=xonly`, preemption dinâmica default `voluntary` — os três kargs são mudanças reais |

---

## 7. Invariantes verificados conformes (sem ação)

- Timers de atualização 5m/45m com guarda NM em todos os 6 serviços (bootc, Flatpak sistema/usuário, Podman sistema/usuário, soar) ✓
- Override do timer soar **necessário** (módulo gera `2min/45m/10m`; repo normaliza para 5m/45m/0) ✓
- Kargs: todos os 8 existem no kernel; nenhum parâmetro fantasma ✓ (aplicação ao bootconfig tratada em F10)
- ZRAM: override `min(ram/2, 32768)`+`zstd` justificado (default Fedora: `min(ram, 8192)`/lzo-rle) ✓
- Áudio TWS: hierarquia de codecs, `hw-volume` não desativado, `autoswitch=false` ✓ (exceto F1)
- CDI ROCm: `/dev/dri/{card1,renderD128}` confere com o hardware; `HSA_OVERRIDE_GFX_VERSION=10.3.0` ✓
- Rclone: parametrização via env, `min-free-space 15G`, `max-age 24h`, trash do Google Drive, proteções 429 do OneDrive (chunk 50M = 160×320 KiB, tpslimit 5, delta+poll 1m), extensibilidade `.env`/`.local.env` ✓
- Overrides Flatpak: template em `/usr/share`, sincronização tmpfiles para `/var/lib/flatpak/overrides` verificada em produção (arquivo implantado idêntico ao template) ✓
- Browser flags: cadeia tmpfiles de usuário operante (brave/chrome-flags.conf presentes), paridade Brave/Chrome ✓
- Baloo `[$ei]` imutável para `$HOME/Cloud` ✓ · udev `uaccess`+`0660` (sem `0666`) ✓
- profile.d: `return 0 2>/dev/null` nos dois scripts; `environment.d` como fonte única ✓
- Btrfs NoCOW: diretivas de sistema e usuário íntegras; caches `0700` ✓
- CI/CD: cron 2h, `concurrency` com `cancel-in-progress`, `permissions` mínimos, cleanup 7 versões/3 dias, dependabot diário, demais actions pinadas por SHA ✓
- Segredos: nenhum em arquivos versionados; `cosign.pub` é chave pública; `.gitignore` cobre materiais de assinatura ✓
- Estrutura de agentes: sem `agent.md` residual; `.agents/local/` ignorado ✓

---

## 8. Sequência de execução

| WP | Commits (ordem) | Conteúdo | Status |
| :-- | :-- | :-- | :-- |
| WP1 | `fix(audio): provision LDAC quality via device rules section` | F1 | ✅ `cb0ec2f` |
| WP2 | `chore(ci): pin blue-build action by commit SHA and drop persistent checkout credentials` | F2, F3 | ✅ `13d3be0` |
| WP3 | `refactor(systemd): remove preset-redundant unit enables` | F4 | ✅ `41569f3` |
| WP4 | `refactor(system): remove redundant defaults and dead configuration` | F5, F6, F7, F8 | ✅ `9255496` |
| WP5 | `refactor(kargs)` / `refactor(recipes)` / `feat(sshd)` | D4, D5, D7 | ✅ `8c87d32`, `ec90f6f`, `45434c5` |
| WP6 | `docs: sync health-checks, kargs verification and tuned interaction notes` | F9, F10, decisões | ✅ este commit |
| WP7 | Ação única no host (F10) + validação `cat /proc/cmdline` | Fora do repo | ⏳ pendente (executar manualmente) |

**Pós-merge:** disparar `build-amd` manualmente (`workflow_dispatch`) — o gatilho por digest §7 não dispara para mudanças de repositório.

**Rollback global:** cada WP é um commit isolado revertível; para o sistema implantado, `sudo bootc rollback` retorna ao deployment anterior; para F10, `sudo rpm-ostree kargs --delete=<karg>` por argumento.

---

**Estado deste documento:** decisões D1–D7 registradas; WP1–WP6 executados (2026-10-01). Removê-lo quando WP7 (ação única de kargs no host) for concluído e validado.
