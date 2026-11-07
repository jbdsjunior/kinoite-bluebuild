# Runbook de Instalação e Operação (`kinoite-amd` / `kinoite-dual`)

Guia operacional para particionamento LUKS2/Btrfs, desbloqueio seguro TPM 2.0, manutenção e montagens Rclone.

---

## 1. Instalação e Desbloqueio TPM 2.0 (PCR 7)

### 1.1 Particionamento Recomendado

No instalador do Fedora (Anaconda), selecione o particionamento automático ou personalizado com a opção **"Criptografar meus dados"** (LUKS2) ativada.
Não crie partição de swap em disco; o sistema provisiona ZRAM automaticamente via `60-zram-policy.conf` (`zram-size = min(ram / 2, 32768)` e `vm.swappiness=150`).

### 1.2 Configurar Desbloqueio Seguro TPM 2.0 (Dois Fatores: Hardware fTPM + PIN)

Execute o utilitário integrado de provisionamento (a partição LUKS raiz é detectada automaticamente):

```bash
# Provisionamento interativo (pergunta se deseja cadastrar PIN de segurança):
sudo kinoite-setup-tpm

# Ou defina explicitamente com PIN (Recomendado - 2 Fatores: Hardware fTPM + PIN):
sudo kinoite-setup-tpm --pin

# Modo desatendido sem PIN (apenas chave de hardware fTPM bound a PCR 7 + 14):
sudo kinoite-setup-tpm --no-pin
```

*(Opcional: caso queira especificar explicitamente um dispositivo, utilize `sudo kinoite-setup-tpm /dev/nvme0n1p3 --pin`)*.

> [!TIP]
> **Proteção Física de Dois Fatores (PIN + PCR 7/14):** Com a opção `--pin`, o disco só é descriptografado pelo TPM se o usuário digitar o PIN no teclado durante a inicialização. Com `--no-pin`, o fTPM descriptografa o disco automaticamente em ~1s mantendo a tela de login padrão do usuário. Em ambos os modos, a integridade do firmware e bootloader é verificada via PCR 7 + 14, impedindo acesso a dados se o NVMe for fisicamente removido.

> [!NOTE]
> **Pós-Atualização de Firmware (UEFI) ou Chave MOK:** Se atualizar o firmware da placa-mãe ou inscrever novas chaves MOK, digite a senha manual no primeiro boot e re-execute o comando (`sudo kinoite-setup-tpm --pin` ou `--no-pin`), que recria o slot TPM de forma idempotente.

> [!IMPORTANT]
> **Initramfs e PCR 14:** o utilitário não reescreve mais `/boot/initramfs-<kver>.img` diretamente (esse arquivo pertence ao deployment). A regeneração é solicitada via `rpm-ostree initramfs --enable` e aplicada no próximo deployment. O binding em PCR 14 inclui medições de kernel/initramfs: após updates de kernel, se o desbloqueio automático falhar, re-execute `sudo kinoite-setup-tpm --pin` (ou `--no-pin`) para re-selar o slot.

---

## 2. Transição para a Imagem Customizada (`bootc`)

A transição segue o protocolo de **duas etapas** descrito no [README](../README.md#quick-start):
bootstrap inicial (`bootc switch` sem política, provisiona as chaves Cosign em `/etc/pki/containers/`)
e imposição estrita (`bootc switch --enforce-container-sigpolicy`, trava o deployment em
`ostree-image-signed`). Os mesmos comandos valem para `kinoite-amd` e `kinoite-dual`.

### 2.1 Inscrição e Permanência da Chave MOK (`kinoite-dual` com Secure Boot)

Ao utilizar a imagem Dual-GPU (`kinoite-dual`) em placas-mãe com **UEFI Secure Boot ativo**, os módulos do driver proprietário NVIDIA (`nvidia.ko`, `nvidia-uvm.ko`) exigem a inscrição do certificado Machine Owner Key (MOK) do build:

1. **Importar o Certificado MOK no Host (Apenas no Primeiro Setup):**
   ```bash
   sudo mokutil --import /etc/pki/akmods/certs/akmods-ublue.der
   ```
   *Defina uma senha temporária de sua escolha apenas para autorizar o cadastro na reinicialização.*

2. **Confirmar na Tela Azul do MOK Manager (UEFI):**
   * Reinicie o computador (`systemctl reboot`).
   * A tela azul do **MOK Manager** aparecerá antes do boot.
   * Selecione **Enroll MOK** -> **Continue** -> **Yes** -> digite a senha da etapa 1 e confirme com **Reboot**.

3. **Permanência no Hardware:**
   * O certificado fica gravado na NVRAM protegida da placa-mãe de forma permanente. Atualizações de imagem ou kernel não solicitam nova confirmação.
   * Verificação: `nvidia-smi`.

---

## 3. Manutenção e Auditoria do Sistema (`sys-optimize`)

O utilitário integrado opera em dois modos distintos:

| Modo | Comando | Comportamento |
| :--- | :--- | :--- |
| **Manutenção completa** | `sudo kinoite-optimize` (alias `sys-optimize`) | Executa as 7 fases: sysctl, tmpfiles/NoCOW + GRUB auto-hide, saúde do Btrfs/TRIM, relatório de fragmentação de VMs, retenção do journald, higiene de Flatpak/Podman, higiene de deployment; em seguida roda a auditoria. |
| **Auditoria somente leitura** | `kinoite-optimize --audit` | Executa apenas a auditoria dos 7 pilares, sem alterar o sistema (não requer root, embora alguns checks sejam pulados sem privilégio). |

Os 7 pilares da auditoria (AGENTS.md §5):

1. Supply Chain, chaves Cosign e assinatura criptográfica.
2. Resiliência de pacotes e ausência de downgrade (deriva upstream).
3. Armazenamento Btrfs NoCOW e gestão de memória/ZRAM.
4. Grafo de áudio PipeWire & WirePlumber.
5. Aceleração de GPU, Vulkan e Wayland zero-copy.
6. Resiliência de boot (GRUB limpo, SysRq REISUB, `sulogin`).
7. Governança de timers de manutenção e armazenamento.

Atalhos adicionais no terminal (`60-kinoite-aliases.sh`):
- `sysup`: `sudo bootc update`.
- `rollback`: `sudo bootc rollback`.
- `status-rclone` / `logs-rclone`: monitoramento de serviços Rclone do usuário.
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

> [!NOTE]
> **OpenCL/ROCm não rodam mais no host:** `mesa-libOpenCL`/`clinfo` foram removidos da imagem
> (filosofia Kinoite: ferramentas de GPU ficam no container). Use a imagem ROCm oficial, que já traz
> `HSA_OVERRIDE_GFX_VERSION=10.3.0` no CDI. O `amdgpu.yaml` versionado é um snapshot desta máquina
> (endereço PCI fixo); em outro hardware regenere com `amd-ctk cdi generate --output=/etc/cdi/amdgpu.yaml`.

---

## 5. DNS privado com DoT (opt-in)

A imagem **não fixa resolvedores DNS**: hardcodar um resolver de terceiros (com as suas escolhas de
`DNSOverTLS`/`DNSSEC`) quebra VPNs, portais cativos e split-DNS corporativo. O
`/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf` da imagem apenas habilita `MulticastDNS=resolve`
e desativa `LLMNR`.

Se você quiser DNS criptografado com filtragem de anúncios/rastreadores no host, aplique a configuração
por máquina (sobrevive a updates da imagem porque `/etc` é mutável):

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/70-dot-privado.conf >/dev/null <<'EOF'
[Resolve]
# Control D (p2 = Block Malware + Ads + Trackers) em portas 853 dedicadas (.11)
DNS=76.76.2.11#p2.freedns.controld.com 76.76.10.11#p2.freedns.controld.com
DNS=2606:1a40::11#p2.freedns.controld.com 2606:1a40:1::11#p2.freedns.controld.com

# Fallback: Cloudflare com DoT
FallbackDNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com

# TLS estrito: impede downgrade para texto claro
DNSOverTLS=yes

# Obrigatoriamente 'no' com resolvers de bloqueio: o Control D responde domínios
# bloqueados com respostas sintéticas, o que invalida assinaturas DNSSEC e gera
# feature loops de degradação no systemd-resolved.
DNSSEC=no

MulticastDNS=resolve
LLMNR=no
EOF
sudo systemctl restart systemd-resolved
resolvectl status | head -20
```

Para reverter ao comportamento padrão (DHCP/NetworkManager):

```bash
sudo rm /etc/systemd/resolved.conf.d/70-dot-privado.conf
sudo systemctl restart systemd-resolved
```

> [!WARNING]
> Em máquinas com VPN corporativa ou Tailscale em modo *MagicDNS*, mantenha `DNS`/`FallbackDNS` vazios:
> o `systemd-resolved` já recebe os servidores por link (`resolvectl dns <iface>`). Forçar um resolver
> global desvia consultas internas e pode quebrar a resolução de hosts privados.

---

## 6. Montagens FUSE de Nuvem (Rclone)

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

- **Higiene:** Os diretórios remotos são montados em `/run/user/` (excluídos do indexador Baloo) e o Dolphin/KIO está pré-configurado para exclusão direta na nuvem sem poluição de pastas locais `.Trash-*`.

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

---

## 8. Inicialização Silenciosa e Elegante (Zero-Touch GRUB Auto-Hide)

O Fedora Kinoite utiliza o mecanismo **GRUB Menu Auto-Hide** com transição *flicker-free* via tema Plymouth BGRT (o logotipo da placa-mãe AORUS permanece estático até a tela de login/desbloqueio sem cortes de tela preta).

### 8.1 Provisionamento 100% Nativo na Imagem

Como o Fedora Kinoite (`bootc`/`rpm-ostree`) mantém permanentemente múltiplos deployments (sistema ativo + rollback), o GRUB é configurado em modo forçado (`menu_auto_hide=2` + `user.cfg`) através da unidade systemd [`kinoite-boot-init.service`](../files/system/usr/lib/systemd/system/kinoite-boot-init.service):

- Grava `menu_auto_hide=2`, `boot_success=1` e `boot_indeterminate=0`.
- Grava `set timeout=0` e `set timeout_style=hidden` em `/boot/grub2/user.cfg`.
- Opera de forma zero-touch no primeiro boot.

Caso deseje verificar o status do ambiente GRUB no host:

```bash
sudo grub2-editenv - list | grep menu_auto_hide
```

### 8.2 Salvaguardas de Segurança e Rollback Automático

- **Fallback Automático (`grub-boot-success.timer`):** O timer de sessão do usuário aguarda 2 minutos de desktop estável para confirmar o boot. Se o sistema falhar ao inicializar ou desligar abruptamente, o GRUB **automaticamente reexibe o menu com as opções de rollback no próximo boot**.
- **Acesso Manual ao Menu:** Para forçar a exibição do menu do GRUB a qualquer momento, ligue o computador mantendo pressionada a tecla **`Shift`** ou tocando repetidamente em **`Esc`** ou **`F8`**.
- **Reverter para Menu Sempre Visível:** Caso deseje que o menu volte a aparecer sempre:
  ```bash
  sudo grub2-editenv - unset menu_auto_hide
  sudo rm -f /boot/grub2/user.cfg
  ```

### 8.3 Bloqueio de Bootloader e Console (Zero Unauthenticated Recovery)

Para garantir que terceiros com acesso físico não possam editar a linha do kernel (`init=/bin/bash` ou parâmetros não autorizados):

1. **Configurar Senha de Proteção no GRUB:**
   ```bash
   sudo grub2-setpassword
   ```
   *Efeito:* O GRUB continuará inicializando o sistema normalmente, mas exigirá o usuário `root` e a senha definida caso alguém pressione a tecla `e` para editar os parâmetros de boot.

2. **Garantir Credencial de Emergência (`sulogin`):**
   ```bash
   sudo passwd root
   ```
   *Efeito:* Garante que, se o sistema entrar em modo `emergency` ou `rescue` (por exemplo, após falha crítica de disco), o shell de manutenção só possa ser acessado mediante digitação de senha, alinhado ao padrão de segurança física *Zero Unauthenticated Recovery*.
