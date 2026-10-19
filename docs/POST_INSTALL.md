# Runbook de Instalação, Operação e Calibração de BIOS (`kinoite-amd`)

Guia operacional direto para particionamento, desbloqueio automático TPM 2.0, verificação pós-instalação, montagens Rclone e calibração de BIOS no hardware:
**AMD Ryzen 9 5950X + Radeon RX 6600 XT + 64 GB DDR4 + Gigabyte X570 AORUS PRO WIFI (BIOS F39)**.

---

## 1. Instalação e Desbloqueio TPM 2.0 (PCR 7)

### 1.1 Particionamento Recomendado (1 TB NVMe — `nvme0n1`)

No Fedora Anaconda (**Custom Partitioning**), configure LUKS2 + Btrfs sem swap em disco (a imagem provisiona **32 GB ZRAM `zstd`** via `60-zram-policy.conf` com `vm.swappiness=150`):

```text
/dev/nvme0n1p1 : 1024 MiB | /boot/efi | EFI System Partition (vfat)
/dev/nvme0n1p2 : 2048 MiB | /boot     | ext4 (bootloader e kernel)
/dev/nvme0n1p3 : ~950 GiB | LUKS2     | Pool Btrfs [compress=zstd:1]:
  ├── Subvolume: root  -> /
  ├── Subvolume: home  -> /var/home
  └── Subvolume: vms   -> /var/lib/libvirt/images [nodatacow]
```

### 1.2 Configurar Desbloqueio Automático TPM 2.0

Execute o script de provisionamento integrado na partição LUKS:

```bash
sudo kinoite-setup-tpm /dev/nvme0n1p3
```

> [!NOTE]
> **Pós-Atualização de BIOS:** Se atualizar a BIOS no futuro, digite a senha manual no primeiro boot e re-execute o mesmo comando (`sudo kinoite-setup-tpm /dev/nvme0n1p3`), que recria o slot TPM de forma idempotente.

---

## 2. Transição para a Imagem Customizada (`bootc`)

Na instalação limpa a partir do Fedora Kinoite upstream:

```bash
# 1. Transição inicial para a imagem OCI customizada
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
systemctl reboot

# 2. Opcional (após o boot): impor verificação criptográfica estrita nas próximas atualizações
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest
```

---

## 3. Manutenção e Auditoria do Sistema (`sys-optimize`)

Execute o utilitário integrado de manutenção para sincronizar sysctls, tmpfiles, permissões Btrfs NoCOW, desfragmentar discos de VM, limpar caches e verificar a saúde dos subsistemas:

```bash
sys-optimize
```

Atalhos no terminal (`/etc/profile.d/60-kinoite-aliases.sh`):
- `sys-optimize` / `optimize`: executa `/usr/bin/kinoite-optimize` (8 fases completas).
- `update-system`: `sudo bootc upgrade`.
- `rollback`: `sudo bootc rollback`.
- `status-rclone`: `systemctl --user status "rclone@*"`.
- `logs-rclone`: `journalctl --user -u "rclone@*" -f`.
- `setup-tpm`: `sudo kinoite-setup-tpm`.

---

## 4. IA Local e Contêineres ROCm (CDI)

A estação suporta aceleração total na **RX 6600 XT** através de duas camadas já integradas:

1. **Host (`llamafile`, `llama.cpp`, GGUF) via Vulkan 1.4 (`radv`):**
   ```bash
   ./seu-modelo.llamafile --gpu vulkan -ngl 99 --mlock
   ```
   *(SELinux e limites de memlock ilimitados já estão provisionados nativamente)*.

2. **Contêineres ROCm/HIP (Ollama, PyTorch) via CDI (`/etc/cdi/amdgpu.yaml`):**
   ```bash
   podman run -d --device amd.com/gpu=all --ipc=host -v ollama:/root/.ollama:Z -p 11434:11434 --name ollama docker.io/ollama/ollama:rocm
   ```

---

## 5. Montagens FUSE de Nuvem (Rclone)

Os remotes montam automaticamente fora da home em `/run/user/$UID/cloud/<Remote>` com cache VFS persistente em `~/.cache/rclone` (`0700`, NoCOW `+C`):

```bash
# 1. Configurar remotes (ex: GoogleDrive ou OneDrive)
rclone config

# 2. Ativar e iniciar serviço do usuário
systemctl --user enable --now rclone@GoogleDrive.service
systemctl --user enable --now rclone@OneDrive.service

# 3. Reconectar caso o token expire
rclone config reconnect GoogleDrive:
```

- **Higiene:** O Dolphin está pré-configurado com `ConfirmDelete=true`, `ConfirmTrash=false` e `ShowDeleteCommand=true`, permitindo excluir diretamente para a lixeira remota da nuvem sem criar pastas `.Trash-1000`. Além disso, o Rclone bloqueia a sincronização de `.Trash-*` via `--exclude`. Pastas em `/run/user` já estão excluídas do indexador Baloo.
- **Client ID Dedicado:** Para conexões corporativas/intensivas no Google Drive sem limite semanal, defina seu Client ID próprio no Google Cloud Console e publique-o em modo de produção (sem logotipo para liberação imediata).

---

## 6. Calibração de BIOS — Gigabyte X570 AORUS PRO WIFI (F39) + 5950X + 64 GB

Topologia física de memória (4 DIMMs mistos, 2 DPC / 3 ranks por canal):
- **A1/B1 (Stubs):** 16 GB 1R genérico.
- **A2/B2 (Terminações Físicas Daisy-Chain):** 16 GB 2R KingSpec (obrigatório nas pontas).

### Tabela de Configuração Rápida (Profile A — Baseline Estável)

Pressione `<Delete>` no boot e `<F2>` para **Advanced Mode**:

| Menu BIOS | Parâmetro | Valor Configurado | Justificativa |
| :--- | :--- | :--- | :--- |
| **Tweaker** | `X.M.P.` | `Profile1` (DDR4-3200) | Clock nominal homologado |
| | `FCLK Frequency` | `1600MHz` | Proporção 1:1 estrita (`UCLK==MEMCLK`) |
| | `Gear Down Mode` | `Enabled` | Estabilidade do barramento de comando |
| | `Power Down Enable` | `Disabled` | Elimina latência de wakeup de C-state |
| | `CAD Bus Timing` | `24-24-24-24 Ω` | Força de condução balanceada |
| | `Data Bus Timing` | `ProcODT = 40.0 Ω` / `RttPark = RZQ/5` | Previne reflexão de sinal nos stubs |
| | `DRAM Voltage` | `1.350 V` | Teto seguro de retenção térmica |
| | `CPU VCORE SOC` | `1.100 V` | Impede aquecimento do soquete AM4 |
| | `Power Supply Idle`| `Typical Current Idle` | Previne travamentos em C6 idle |
| **Settings**| `Above 4G` / `Re-Size BAR`| `Enabled` | SAM de 8192 MB na GPU RX 6600 XT |
| | `AMD CPU fTPM` | `Enabled` | Necessário para PCR 7 LUKS |
| | `TSME` | `Disabled` | Elimina overhead de criptografia de DRAM |
| **AMD CBS** | `IOMMU` | `Enabled` | Isolamento DMA para KVM e CDI |
| | `Auto Self Refresh`| `Enabled` | Refrescamento capacitivo estendido |
| | `CPPC` / `Preferred Cores`| `Enabled` | Obrigatório para o driver `amd-pstate-epp` |
| | `PBO` | `Auto` (Stock: 142W/95A/140A) | Evita degradação por tensão |
| | `Curve Optimizer` | `Disabled` | Zero instabilidade no CCD0 |
| **Boot** | `CSM Support` / `Fast Boot` | `Disabled` | Modo UEFI puro nativo |

Salvar em **Save Profiles → Slot 1** (`Profile 1 - Stable Baseline 64GB`) e pressionar `<F10>`.

---

## 7. Rollback e Recuperação de Emergência

```bash
# Reverter para a imagem do deployment anterior
sudo bootc rollback
systemctl reboot

# Reverter para o Fedora Kinoite upstream oficial
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

- **SysRq REISUB (`kernel.sysrq = 1`):** Em caso de congelamento gráfico, segure `Alt + SysRq` e digite pausadamente `R` → `E` → `I` → `S` → `U` → `B` para descarregar caches Btrfs e reiniciar com segurança.
