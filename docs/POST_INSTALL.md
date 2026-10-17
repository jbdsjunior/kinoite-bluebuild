# Guia Unificado de Instalação, Operação, Nuvem e Calibração de BIOS (`kinoite-amd`)

Referência operacional consolidada para instalação, desbloqueio automático via TPM 2.0, validação pós-instalação, contêineres ROCm/CDI, montagens FUSE (Rclone + OAuth 2.0) e calibração de BIOS na estação **AMD Ryzen 9 5950X + Radeon RX 6600 XT + 64 GB DDR4 + Gigabyte X570 AORUS PRO WIFI (BIOS F39)**.

---

## 1. Instalação, Particionamento Btrfs e TPM 2.0 (PCR 7)

### 1.1 Esquema de Partições Recomendado (1 TB NVMe PCIe Gen4 — `nvme0n1`)

No instalador Fedora Anaconda (**Custom Partitioning**), utilize LUKS2 + Btrfs sem partição de swap física (o sistema provisiona **32 GB ZRAM `zstd`** em RAM via `60-zram-policy.conf` com `vm.swappiness=150`):

```text
/dev/nvme0n1p1 : 1024 MiB | /boot/efi | EFI System Partition (vfat)
/dev/nvme0n1p2 : 2048 MiB | /boot     | ext4 (assinaturas de kernel e GRUB)
/dev/nvme0n1p3 : ~950 GiB | LUKS2 (aes-xts-plain64) -> Pool Btrfs:
  ├── Subvolume: root  -> /                       [compress=zstd:1]
  ├── Subvolume: home  -> /var/home               [compress=zstd:1]
  └── Subvolume: vms   -> /var/lib/libvirt/images [nodatacow]
```

### 1.2 Desbloqueio Automático LUKS2 via AMD fTPM 2.0 (PCR 7)

Vincular exclusivamente ao **PCR 7** (estado do Secure Boot e chaves UEFI) garante desbloqueio automático em < 50ms sem quebrar após atualizações de kernel ou imagens `bootc`:

```bash
# 1. Gerar chave de recuperação offline (guardar fora do computador)
sudo systemd-cryptenroll --recovery-key /dev/nvme0n1p3

# 2. Vincular fTPM 2.0 ao PCR 7
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3
sudo cryptsetup luksDump /dev/nvme0n1p3

# 3. Garantir opção tpm2-device=auto em /etc/crypttab:
# luks-<UUID> UUID=<UUID> none discard,tpm2-device=auto

# 4. Regerar initramfs
sudo dracut -f --regenerate-all
```

> [!NOTE]
> **Pós-Atualização de BIOS:** Se atualizar a BIOS da placa-mãe no futuro, digite a senha manual no primeiro boot e re-registre o TPM:
> `sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p3 && sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3 && sudo dracut -f --regenerate-all`

### 1.3 Transição Atômica para a Imagem Customizada (`bootc`)

```bash
# Mudar para a imagem assinada e reiniciar
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest
systemctl reboot
```

---

## 2. Verificação Pós-Instalação e Manutenção (`kinoite-optimize`)

```bash
# Status da imagem OCI, assinatura e kernel
bootc status
uname -r

# Executar utilitário unificado de manutenção (8 fases: sysctl, tmpfiles, NoCOW, defrag VM, flatpak/podman prune, kargs e saúde)
sys-optimize
```

Atalhos declarados em `/etc/profile.d/60-kinoite-aliases.sh`:
- `optimize` / `sys-optimize`: executa `/usr/bin/kinoite-optimize`.
- `update-system`: `sudo bootc upgrade`.
- `cleanup`: limpa metadados `rpm-ostree`, Flatpaks não utilizados e contêineres parados.
- `tmpfiles-user`: `systemd-tmpfiles --user --create`.

---

## 3. Áudio PipeWire (Baixa Latência) e Bluetooth

A imagem calibra o PipeWire (`60-quantum-tuning.conf` e `60-pulse-quantum.conf`) em **quantum `256` @ `48kHz` (~5.3ms, faixa `128`–`512`)** e desativa o autosuspend USB Bluetooth (`btusb.enable_autosuspend=0`):

```bash
pw-metadata -n settings
# Esperado: clock.rate = 48000 | clock.quantum = 256 | clock.min-quantum = 128 | clock.max-quantum = 512

cat /sys/module/btusb/parameters/enable_autosuspend
# Esperado: N
```

---

## 4. Virtualização KVM, Btrfs NoCOW e Aceleração de IA (ROCm CDI)

### 4.1 KVM / Libvirt e NoCOW (`+C`)

Os diretórios `/var/lib/libvirt/images`, `/var/lib/containers/storage{,/volumes}`, `~/.local/share/{libvirt/images,gnome-boxes/images,containers/storage{,/volumes}}` e `~/.cache/rclone` (`0700`) recebem `+C` (NoCOW) via `tmpfiles.d` (`h`):

```bash
systemctl status virtqemud.socket virtqemud.service
lsattr -d /var/lib/libvirt/images ~/.local/share/containers/storage ~/.cache/rclone
```

Para máquinas virtuais de alto desempenho no QEMU/Libvirt, utilize imagens RAW sparse com `cache='none'`, `io='native'` e `discard='unmap'`.

### 4.2 GPU AMD RX 6600 XT e Inferência Local via CDI (`/etc/cdi/amdgpu.yaml`)

Sem inflar a imagem base com pacotes ROCm no host, o arquivo `/etc/cdi/amdgpu.yaml` mapeia `/dev/kfd` e `/dev/dri/*` e injeta `HSA_OVERRIDE_GFX_VERSION=10.3.0` (`gfx1032` -> `gfx1030`):

```bash
# Validar GPU e VA-API no host
echo $HSA_OVERRIDE_GFX_VERSION   # 10.3.0
vulkaninfo --summary | grep driverName
vainfo
clinfo

# Executar Ollama ou PyTorch com aceleração GPU via CDI
podman run -d --device amd.com/gpu=all -v ollama:/root/.ollama -p 11434:11434 --name ollama docker.io/ollama/ollama:rocm
```

---

## 5. Linha de Boot (Kargs) e Recuperação de Desastres (Rollback)

### 5.1 Auditoria e Saneamento de Kargs

A imagem opera na baseline nativa do Fedora Kinoite 44 acrescida unicamente da exceção homologada `btusb.enable_autosuspend=0` (`recipes/common-kargs.yml` e `60-btusb.conf`):

```bash
cat /proc/cmdline
rpm-ostree kargs

# Remover kargs obsoletos/instáveis caso herdados de instalações antigas:
sudo rpm-ostree kargs \
  --delete-if-present=amd_pstate=active \
  --delete-if-present=tsc=reliable \
  --delete-if-present=nowatchdog \
  --delete-if-present=iommu=pt \
  --delete-if-present=slab_nomerge \
  --delete-if-present=vsyscall=none \
  --delete-if-present=preempt=full \
  --delete-if-present=page_alloc.shuffle=1
```

### 5.2 Rollback Transacional e SysRq REISUB

```bash
# Reverter para o deployment anterior
sudo bootc rollback
systemctl reboot

# Reverter para a imagem oficial upstream do Fedora Kinoite
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

- **Recuperação de Emergência do Teclado (`kernel.sysrq = 1`):** Em caso de travamento gráfico, pressione `Alt + SysRq` seguido sequencialmente de `R` → `E` → `I` → `S` → `U` → `B` para sincronizar caches Btrfs e reiniciar com segurança.

---

## 6. Montagens FUSE de Nuvem (Rclone) e OAuth 2.0 Dedicado

### 6.1 Arquitetura e Inicialização (`rclone@.service`)

- **Template:** `/usr/lib/systemd/user/rclone@.service` monta `~/Cloud/<Remote>` com cache VFS (`~/.cache/rclone`, `0700`, NoCOW `+C`, `max-size=15G`, `max-age=24h`, `min-free-space=15G`, `write-back=10s`, `attr-timeout=1h`, `buffer-size=32M`, `read-ahead=64M`, `read-chunk-streams=4`).
- **Configuração por Provedor:** `/usr/share/rclone/env/{GoogleDrive,OneDrive}.env` são sincronizados para `~/.config/rclone/env/*.env` no login via `70-rclone-env.conf`. Overrides persistentes do usuário devem ser salvos em `~/.config/rclone/env/<Remote>.local.env`.
- **Google Drive (`GoogleDrive.env`):** `TPSLIMIT=12`, `TPSLIMIT_BURST=100`, `DRIVE_CHUNK_SIZE=64M`, `DRIVE_PACER_MIN_SLEEP=10ms`, `DRIVE_PACER_BURST=100`, `DRIVE_LIST_CHUNK=1000`, `DRIVE_USE_TRASH=true`, `DRIVE_SKIP_GDOCS=true`, `POLL_INTERVAL=15s`.
- **OneDrive (`OneDrive.env`):** `TPSLIMIT=5`, `TPSLIMIT_BURST=10`, `ONEDRIVE_CHUNK_SIZE=50M` (múltiplo de 320 KiB), `ONEDRIVE_DELTA=true`, `ONEDRIVE_LIST_CHUNK=1000`, `POLL_INTERVAL=1m`.

```bash
# Configurar remote (GoogleDrive ou OneDrive) e ativar serviço
rclone config
tmpfiles-user
systemctl --user daemon-reload
systemctl --user enable --now rclone@GoogleDrive.service
systemctl --user enable --now rclone@OneDrive.service

# Atalhos de monitoramento
status-rclone
logs-rclone
restart-rclone
```

### 6.2 Higiene de Exclusão no Dolphin, Duplicados e Indexador Baloo

- **Baloo (`baloofilerc`):** `$HOME/Cloud` possui exclusão imutável (`[$ei]`). Caso indexado anteriormente, limpe com `balooctl6 purge`.
- **Exclusão Direta (`Shift + Delete`):** `ShowDeleteCommand=true` em `/etc/xdg/kdeglobals` exibe **"Excluir"** no menu de contexto do Dolphin. Em `~/Cloud/`, use sempre `Shift + Delete` (ou "Excluir") para acionar `unlink()` direto — o Rclone move o arquivo para a lixeira na nuvem do Google Drive/OneDrive sem criar pastas locais `.Trash-1000`.
- **Remoção de Pastas Pesadas e Deduplicação:** Para pastas com centenas de arquivos, use `rclone purge GoogleDrive:caminho/da/pasta` (server-side em < 1s). O utilitário `sys-optimize` remove `.Trash-*` residuais e resolve erros `Dir.Remove not empty` via `rclone dedupe --dedupe-mode newest`.

### 6.3 Configuração de Client ID OAuth 2.0 Próprio no Google Cloud (Sem Expiração de 7 Dias)

O `client_id` público do Rclone sofre rate-limit global (`403 RATE_LIMIT_EXCEEDED`, pacer de 16–32s). Criar um aplicativo próprio publicado garante **20.000 requisições/100s exclusivas** e tokens permanentes:

1. **Projeto e API:** No [Google Cloud Console](https://console.cloud.google.com/), crie um projeto (`Rclone-Kinoite`) e ative a **Google Drive API** em *APIs e Serviços → Biblioteca*.
2. **Branding (Sem Logotipo):** Em *Google Auth Platform / Tela de permissão OAuth*, defina o nome `Rclone Kinoite`, selecione seu e-mail e **deixe o logotipo em branco** (enviar logotipo exige verificação documental; sem logotipo a publicação pessoal é imediata).
3. **Escopos:** Em *Acesso a dados*, adicione o escopo `.../auth/drive` (*Ver, editar, criar e excluir todos os seus arquivos do Google Drive*).
4. **Publicação Definitiva:** Em *Público-alvo (Audience)*, mantenha como **Externo**, adicione seu e-mail em *Usuários de teste* e clique em **Publicar aplicativo (Publish app)** para mudar o status para **Em produção** (impede que o *refresh token* expire a cada 7 dias).
5. **Credenciais Desktop:** Em *Clientes (Credentials)* → **+ Criar cliente** → selecione **App para Computador (Desktop App)** e copie o `client_id` e `client_secret`.
6. **Vincular no Rclone (pode ser reutilizado em múltiplos remotes do Google Drive):**
   ```bash
   rclone config update GoogleDrive client_id "SEU_CLIENT_ID" client_secret "SUA_CHAVE_SECRETA"
   rclone config reconnect GoogleDrive:
   systemctl --user restart rclone@GoogleDrive.service
   ```
   *(No navegador, clique em **Avançado → Acessar Rclone Kinoite (não seguro) → Continuar**).*

---

## 7. Timers de Atualização, Proteção TuneD e Hardening de Segurança

```bash
# Validar timers automáticos (OnBootSec=5m, OnUnitActiveSec=45m + /usr/libexec/kinoite/network-guard)
systemctl status bootc-fetch-apply-updates.timer flatpak-system-update.timer podman-auto-update.timer
systemctl --user status flatpak-user-update.timer podman-auto-update.timer soar-upgrade-packages.timer

# Validar sysctls protegidos contra sobrescrita do TuneD (60-sysctl-protection.conf)
sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio net.ipv4.tcp_congestion_control

# Validar blacklist CIS de módulos e DNS-over-TLS Cloudflare
modprobe -n -v sctp
resolvectl status
```

---

## 8. Calibração de BIOS — Gigabyte X570 AORUS PRO WIFI (BIOS F39) + 5950X + 64 GB DDR4

### 8.1 Topologia Daisy-Chain e Invariantes Térmicas de DRAM (4 DIMMs Mistos)

```text
[ Soquete AM4 ] ---> [ A1 / B1 (Stubs): 16 GB 1R Genérico ] ---> [ A2 / B2 (Terminação Física): 16 GB 2R KingSpec KS3200D4R13516G ]
```

- **Terminação Física Obrigatória:** Os módulos dual-rank (2R) devem residir estritamente nos slots **A2 e B2**, e os single-rank (1R) em **A1 e B1**.
- **Acoplamento Térmico SoC → Slots A1/A2:** O modo `Auto` da placa-mãe sob XMP aplica `1.20V–1.25V` no `CPU VCORE SOC`, aquecendo o plano de cobre do soquete AM4 adjacente aos slots A1/A2. Fixar `VSOC = 1.100 V` e `DRAM Voltage = 1.350 V` contém a dissipação térmica ($P \propto V^2$).
- **Recarga Capacitiva (`tRFC` / `tREFI`):** Manter estritamente em `Auto` com `Auto Self Refresh (ASR) = Enabled` (2x refresh próximo a 85 °C) e fluxo de ar ativo no gabinete sobre os 4 módulos.

### 8.2 Profile A — Baseline Estável Homologado (Passo a Passo na BIOS F39)

Pressione `<Delete>` no boot e `<F2>` para **Advanced Mode**:

1. **Aba `Tweaker`:**
   - `Extreme Memory Profile (X.M.P.)`: `Profile1` (DDR4-3200 MT/s).
   - `FCLK Frequency`: `1600MHz` | `UCLK DIV1 MODE`: `UCLK==MEMCLK` (sincronia 1:1).
   - `Advanced Memory Settings`:
     - `Memory Boot Mode`: `Normal` | `Standard Timing Control`: `Auto` (`tRFC` e `tREFI` em `Auto`).
     - `Gear Down Mode`: `Enabled` | `Power Down Enable`: `Disabled` | `Memory Context Restore`: `Disabled`.
     - `CAD Bus Timing`: `ClkDrvStr`, `AddrCmdDrvStr`, `CsOdtDrvStr`, `CkeDrvStr` = `24 Ω`.
     - `Data Bus Timing`: `ProcODT = 40.0 Ω` (fallback `43.6 Ω`), `RttNom = Disabled`, `RttWr = RZQ/3 (80 Ω)`, `RttPark = RZQ/5 (48 Ω)`.
   - `Advanced Voltage Settings`:
     - `DRAM Voltage (CH A/B)`: `1.350 V` (teto estrito `1.350 V`; undervolt validado `1.300 V`–`1.320 V` permitido).
     - `CPU VCORE SOC`: `1.100 V` (teto `1.150 V`).
   - `Advanced CPU Settings`:
     - `Core Performance Boost`: `Auto` | `SVM Mode`: `Enabled` | `AMD Cool&Quiet`: `Enabled` | `Global C-state Control`: `Enabled`.
     - `Power Supply Idle Control`: `Typical Current Idle` (obrigatório para evitar travamentos em C6 idle).
2. **Aba `Settings`:**
   - `IO Ports`: `Above 4G Decoding = Enabled` | `Re-Size BAR Support = Enabled` (SAM 8192M) | `PCIe Slot Configuration = Auto`.
   - `Miscellaneous`: `AMD CPU fTPM = Enabled` | `TSME = Disabled` (remove latência de encriptação DRAM).
   - `AMD CBS`:
     - `NBIO Common Options → IOMMU`: `Enabled`.
     - `UMC Common Options → DDR Common Options → DRAM Controller Configuration`: `Auto Self Refresh (ASR)` / `Extended Temperature Range = Enabled`.
     - `SMU Common Options`: `CPPC = Enabled` | `CPPC Preferred Cores = Enabled` | `DF Cstates = Auto`.
   - `AMD Overclocking`:
     - `DDR and Infinity Fabric`: `1600 MHz` | `UCLK==MEMCLK` | `VDDG IOD = 1000 mV` (`1.000 V`) | `VDDG CCD = 950 mV` (`0.950 V`) | `cLDO VDDP = 900 mV` (`0.900 V`).
     - `Precision Boost Overdrive`: `Auto` (stock: PPT 142W, TDC 95A, EDC 140A) | `Curve Optimizer = Disabled`.
3. **Aba `Boot` & `Save & Exit`:**
   - `CSM Support = Disabled` | `Fast Boot = Disabled`.
   - Salvar em `Save Profiles → Slot 1` (`Profile 1 - Stable Baseline 64GB`) e pressionar `<F10>`.

### 8.3 Profile B — Tuning Opcional Pós-Validação

Aplicar **somente após o Profile A passar na validação (§8.4) com zero erros**:
- **Fase 1 (Timings Primários):** Testar `20-20-20-20-40` (ou `18-22-22-42`) mantendo `tRC`, `tRFC` e `tREFI` em `Auto` e `Gear Down Mode = Enabled`.
- **Fase 2 (PBO):** Limites stock (`PPT 142W / TDC 95A / EDC 140A`) ou High-Throughput (`PPT 175W / TDC 120A / EDC 150A` apenas com watercooler 280/360mm $< 75^\circ\text{C}$). Proibido `Motherboard` limits ou `PBO Scalar > 1X`.
- **Fase 3 (Curve Optimizer Per-Core):**
  - Hierarquia CPPC do host: **CCD0** contém os núcleos preferenciais (`Core 0` e `Core 3` score `236`, `Core 6` `231`, `Core 5` `226`). **Proibido aplicar CO negativo no CCD0 (Cores 0 a 7 = `0`)**, pois induz kernel oops em cargas leves.
  - **CCD1 (Cores 8 a 15, scores 166–201):** Permitido testar offset negativo conservador de `-5` (opcionalmente `-10` após validação).

### 8.4 Auditoria de Hardware e Testes de Estresse (Obrigatório)

```bash
# 1. Confirmar frequência DDR4-3200 nos 4 slots, driver amd-pstate-epp e Re-Size BAR (8192M)
sudo dmidecode -t memory | grep -E "Locator:|Speed:|Configured Memory Speed:|Part Number:|Rank:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver /sys/devices/system/cpu/amd_pstate/status
journalctl -k -b 0 | grep -E "amdgpu.*BAR=|iommu: Default domain"

# 2. Listar hierarquia CPPC highest_perf dos 32 threads
paste <(for i in /sys/devices/system/cpu/cpu*/topology/core_id; do echo "CPU $(basename $(dirname $(dirname $i)) | sed 's/cpu//'): core $(cat $i)"; done) \
      <(for i in /sys/devices/system/cpu/cpu*/acpi_cppc/highest_perf; do echo "highest_perf: $(cat $i)"; done) | sort -k6,6nr | head -n 16

# 3. Teste ativo de estresse DRAM + Infinity Fabric (1h alocando ~52 GB) e CPU (30m)
toolbox create -y memtest
toolbox run -c memtest sudo dnf install -y stressapptest stress-ng
toolbox run -c memtest stressapptest -s 3600 -M 52000 -W
toolbox run -c memtest stress-ng --cpu 32 --cpu-method all --verify --timeout 30m --metrics-brief

# 4. Verificar ausência de erros MCE / PCIe AER no kernel e rasdaemon
journalctl -k -b 0 -p 3 --no-pager
sudo ras-mc-ctl --errors
```

- **Validação Offline de DRAM (Não-ECC):** Executar ≥ 4 passes completos no **PassMark MemTest86** via USB UEFI (critério: 0 erros; se houver erro, ajustar `ProcODT` para `43.6 Ω` ou `VSOC` para `1.125 V`).
