# Documento de Arquitetura Técnica (TAD)

## Imagem OCI Imutável Fedora Kinoite Custom (BlueBuild)

---

### Metadados do Documento

| Atributo                   | Detalhe                                                                  |
| :------------------------- | :----------------------------------------------------------------------- |
| **Projeto**                | `kinoite-bluebuild` (Fedora Kinoite Custom)                              |
| **Target de Distribuição** | `ghcr.io/jbdsjunior/kinoite-amd:latest`                                  |
| **Papel do Autor**         | Arquiteto de Software Principal (Principal Software & Systems Architect) |
| **Data de Referência**     | Setembro de 2026                                                         |
| **Status**                 | Aprovado para Linha de Base / RFC para Evolução Contínua                 |
| **Classificação**          | Engenharia de Sistemas Operacionais Imutáveis & DevSecOps                |

---

## 1. Visão Geral & Contexto Executivo

### 1.1 Declaração do Problema

Sistemas operacionais de estações de trabalho para engenharia (DevSecOps, desenvolvimento de software, virtualização e IA local) tradicionalmente sofrem de **deriva de configuração (configuration drift)**, dependências mutáveis colidentes, risco elevado em atualizações in-place e atrito na recuperação de desastres. O modelo convencional de pacotes (`dnf install` direto no host) acopla o estado do sistema operacional às bibliotecas de desenvolvimento, comprometendo a reprodutibilidade e a integridade da cadeia de suprimentos (supply chain).

### 1.2 A Solução Arquitetural

O projeto implementa uma **estação de trabalho nativa em contêiner (OCI-native immutable workstation)** utilizando o ecossistema Fedora Kinoite (KDE Plasma 6 Wayland) orquestrado pelo framework **BlueBuild** e gerenciado via **bootc / ostree**.

O sistema operacional inteiro é tratado como um artefato imutável, versionado no Git, construído via GitHub Actions, criptograficamente assinado com Cosign e implantado no host via substituição de imagem transacional atômica (`bootc switch` / `bootc update`), garantindo rollback instantâneo e tempo de recuperação próximo de zero.

### 1.3 Princípios Arquiteturais Cardeais

```
+---------------------------------------------------------------------------------------+
|                               PRINCÍPIOS ARQUITETURAIS                                |
+-----------------------+-----------------------+-----------------------+---------------+
|   1. Imutabilidade    |   2. Integridade &    |   3. Atomicidade &    |  4. KISS &    |
|      First            |      Assinatura       |      Resiliência      |  Zero-Overhead|
| Modificações apenas   | Assinatura Cosign no  | Transição atômica de  | Sem daemons   |
| via Git/CI/CD;        | pipeline antes da     | imagens e rollback    | redundantes;  |
| /usr montado somente  | liberação no registry.| instantâneo com       | uso de flags  |
| leitura no host.      |                       | bootc/ostree.         | nativas Linux.|
+-----------------------+-----------------------+-----------------------+---------------+
```

1. **Imutabilidade First:** O sistema base (`/usr`, `/etc` gerenciado) é imutável. Softwares adicionais residem em contêineres rootless (Podman/Distrobox) ou pacotes isolados (Flatpak).
2. **Integridade & Assinatura:** Segurança incorporada no processo de compilação. Imagens só são aceitas se assinadas por chave criptográfica confiável (Cosign).
3. **Atomicidade e Resiliência:** Atualizações são preparadas em staging em segundo plano. O host nunca fica em estado intermediário corrompido. Qualquer falha operacional é revertida com um único comando (`bootc rollback`).
4. **KISS & Zero-Overhead:** Preferência estrita por interfaces de kernel e systemd nativas (drop-ins, systemd-tmpfiles, sysctl, environment.d) em vez de utilitários de terceiros ou daemons residentes em background desnecessários.

---

## 2. Hardware Baseline & Perfil Operacional

O dimensionamento de kernel, VFS, ZRAM e subsistemas de I/O foi rigorosamente calibrado para o seguinte hardware de referência:

| Subsistema            | Especificação Homologada                              | Impacto Arquitetural                                                                                                     |
| :-------------------- | :---------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------- |
| **Processador (CPU)** | AMD Ryzen 9 5950X (16 núcleos / 32 threads Zen 3)     | `preempt=full`, `amd_pstate=active`, desativação de NMI watchdog para eliminar jitter em 32 threads.                     |
| **Gráficos (GPU)**    | AMD Radeon RX 6600 XT (8 GB GDDR6, Navi 23 / RDNA2)   | Driver Mesa RADV, aceleração VA-API Freeworld, override HIP/ROCm `HSA_OVERRIDE_GFX_VERSION=10.3.0` (gfx1032 -> gfx1030). |
| **Memória (RAM)**     | 64 GB DDR4                                            | ZRAM com algoritmo `zstd` limitado a 32 GB (`min(ram / 2, 32768)`), `vm.swappiness=150`, `watermark_scale_factor=125`.   |
| **Armazenamento**     | 1 TB NVMe SSD (PCIe Gen4)                             | Btrfs com regras NoCOW (`+C`) em diretórios de gravação pesada de VMs e contêineres via tmpfiles.d.                      |
| **Base do SO**        | Fedora Kinoite 44 (KDE Plasma 6, Wayland puro, bootc) | Remoção completa de daemons legados de virtualização guest, telemetria e navegadores mutáveis no host.                   |

---

## 3. Visão Estrutural da Arquitetura (C4 Model - Nível de Camadas)

### 3.1 Diagrama de Fluxo de Entrega e Execução (End-to-End Delivery Flow)

```mermaid
flowchart TD
    subgraph GitRepo["Repositório Git (jbdsjunior/kinoite-bluebuild)"]
        RECIPES["Receitas Declarativas\n(recipes/*.yml)"]
        OVERLAY["Host File Overlay\n(files/system/)"]
        WORKFLOWS["Workflows GitHub Actions\n(.github/workflows/)"]
    end

    subgraph CICD["Esteira CI/CD (GitHub Actions)"]
        CHECK["check-updates.yml\n(Inspeção de Digest Upstream)"]
        BUILD["build-amd.yml\n(BlueBuild Engine v1)"]
        SIGN["Cosign Signer\n(Assinatura com Chave Privada)"]
    end

    subgraph Registry["Registro OCI Seguro (GHCR)"]
        OCI_IMG["ghcr.io/jbdsjunior/kinoite-amd:latest\n(Camadas OCI + Assinatura + Cosign Attestation)"]
    end

    subgraph WorkstationHost["Estação de Trabalho Local (AMD Zen3 + RDNA2)"]
        BOOTC["bootc daemon / rpm-ostree\n(Staged Updates / Atomic Rollback)"]
        KERNEL["Kernel Linux 6.x\n(Tuned kargs, sysctl, zram, Btrfs NoCOW)"]
        DESKTOP["KDE Plasma 6 (Wayland)\n(Fontes Inter/JetBrains, Konsole Tokyo Night, Starship)"]
        WORKLOADS["Isolamento de Cargas de Trabalho\n- Podman Rootless / Distrobox\n- Flatpak Applications\n- KVM / Libvirt Modular\n- ROCm / HIP AI Acceleration"]
    end

    RECIPES --> BUILD
    OVERLAY --> BUILD
    WORKFLOWS --> BUILD
    CHECK -->|Gatilho Automático| BUILD
    BUILD --> SIGN
    SIGN --> OCI_IMG
    OCI_IMG -->|Puxado e Verificado via Cosign| BOOTC
    BOOTC --> KERNEL
    KERNEL --> DESKTOP
    DESKTOP --> WORKLOADS
```

### 3.2 Diagrama de Separação de Responsabilidade em Camadas (Layered Architecture)

```mermaid
graph TD
    subgraph L5["Camada 5: Aplicações & Cargas de Trabalho Isoladas"]
        APP_FLATPAK["Aplicações de Desktop (Flatpak System/User)"]
        APP_DEV["Dev Environments (Distrobox / Podman Rootless)"]
        APP_VIRT["Virtualização Isolada (KVM / QEMU / Libvirt)"]
        APP_AI["IA & Inferência Local (Ollama / PyTorch ROCm)"]
    end

    subgraph L4["Camada 4: Sessão de Usuário & Shell UX"]
        ENV_SESSION["Systemd Environment.d (Wayland Ozone, RADV, Truecolor)"]
        SHELL_UX["Shell Interativo (Starship, Zoxide, FZF, Eza, Bat)"]
        UI_THEME["Tipografia Mac-Like & Konsole Tokyo Night"]
    end

    subgraph L3["Camada 3: Automação do Sistema & Serviços"]
        TIMERS["Timers de Atualização Inteligentes (bootc, flatpak, podman, soar)"]
        NET_RESILIENCE["ExecCondition via D-Bus NetworkManager (Anti-Metered/Offline)"]
        TMPFILES["Btrfs NoCOW Enforcement (tmpfiles.d / user-tmpfiles.d)"]
        SYS_HARDEN["SSHD Hardening, Blacklist Modprobe, Polkit Libvirt"]
    end

    subgraph L2["Camada 2: Imagem Base OCI & Gestor Transacional"]
        BASE_OS["Fedora Kinoite 44 OCI Base"]
        BLUEBUILD["Módulos BlueBuild (RPM Fusion Freeworld, KVM, Fonts)"]
        BOOTC_ENGINE["bootc / rpm-ostree (Staged Deployments)"]
    end

    subgraph L1["Camada 1: Kernel, Memória & Subsistema de I/O"]
        K_ARGS["Kargs: amd_pstate=active, preempt=full, iommu=pt, CIS mitigations"]
        SYSCTL_TUNE["Sysctl: TCP BBR+FQ, VFS cache 50, dirty ratios NVMe, inotify 512k"]
        ZRAM_GEN["ZRAM zstd: 32 GB Swap / swappiness=150 / page-cluster=0"]
    end

    L1 --> L2
    L2 --> L3
    L3 --> L4
    L4 --> L5
```

---

## 4. Engenharia dos Módulos Declarativos (BlueBuild Recipes)

A decomposição das receitas em `recipes/` adota alta coesão e baixo acoplamento:

| Arquivo de Módulo     | Propósito de Engenharia                     | Decisões Chave                                                                                                                                                                                                                                          |
| :-------------------- | :------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `recipe-amd.yml`      | Orquestrador principal da variante AMD      | Herda de `quay.io/fedora/fedora-kinoite`, injeta `files/system/`, orquestra submódulos e finaliza com `initramfs` e `signing`.                                                                                                                          |
| `common-debloat.yml`  | Minimização da superfície de ataque         | Eliminação de navegadores embutidos no host (`firefox`), lojas de pacotes ostree redundantes e agentes legados de VM (`qemu-guest-agent`, `open-vm-tools`, `hyperv-daemons`).                                                                           |
| `common-drivers.yml`  | Codecs multimídia e aceleração GPU          | Mesa Freeworld (`mesa-va-drivers-freeworld`, `mesa-vulkan-drivers-freeworld`), FFmpeg RPM Fusion completo, plugins GStreamer bad/ugly e codecs de áudio (`pipewire-codec-aptx`).                                                                        |
| `common-kvm.yml`      | Pilha de virtualização bare-metal           | Pacotes `@virtualization`, `gnome-boxes`, suporte TPM emulado (`swtpm`) para execução segura de VMs Windows 11 / Linux.                                                                                                                                 |
| `common-tools.yml`    | Ferramental moderno CLI & DevSecOps         | Repositórios Subatomic Terra e Tailscale; utilitários modernos de substituição (`eza`, `bat`, `btop`, `ripgrep`, `fd-find`, `fzf`, `zoxide`), contêineres (`distrobox`, `docker-compose`, `podman-docker`) e diagnóstico de GPU (`nvtop`, `radeontop`). |
| `common-fonts.yml`    | Tipografia de alta precisão                 | Fontes `Inter Variable`, `Liberation`, `MS Core Fonts` e Nerd Fonts (`JetBrainsMono`, `FiraCode`, `SymbolsOnly`).                                                                                                                                       |
| `common-systemd.yml`  | Orquestração de daemons e sockets           | Mascaramento de serviços desnecessários (`systemd-remount-fs.service`, `mcelog.service`), ativação modular de sockets libvirt (`virtqemud.socket`, etc.) e habilitação de timers de manutenção.                                                         |
| `common-kargs.yml`    | Configuração imutável da linha de boot      | Ativação do driver P-State nativo Zen 3, preempção desktop total, isolamento IOMMU e mitigação de vulnerabilidades de kernel (KSPP / CIS Benchmark).                                                                                                    |
| `common-flatpaks.yml` | Camada de aplicativos de produtividade e UI | Instalação centralizada em escopo de sistema para browsers (`Brave`, `Chrome`), ferramentas de Dev (`VS Code`), monitoramento (`MissionCenter`, `Warehouse`, `Flatseal`) e comunicação.                                                                 |
| `common-brew.yml`     | Gerenciador de pacotes complementar         | Integração do Homebrew e do gerenciador Soar para binários portáveis sem contaminação do host.                                                                                                                                                          |

---

## 5. Subsistemas Críticos & Especificação Técnica de Tuning

### 5.1 Subsistema de Memória e Swap ZRAM

- **Política ZRAM:** Alocação de swap compactado via `systemd-zram-generator` configurada em `/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`:
  $$\text{zram-size} = \min\left(\frac{\text{RAM}}{2}, 32768\right) = 32\text{ GB}$$
- **Algoritmo de Compressão:** `zstd`, provendo razão de compressão típica de 3:1 com descompressão ultra-rápida.
- **Calibração de Kernel (`sysctl`):**
  - `vm.swappiness = 150`: Prioriza a transferência de páginas anônimas ociosas para o ZRAM antes de descartar o cache de arquivos (pagecache), mantendo o sistema responsivo durante compilações e execução de LLMs.
  - `vm.page-cluster = 0`: Desativa a leitura em bloco sequencial de páginas de swap; como o ZRAM é RAM de acesso aleatório, a paginação 1:1 elimina amplificação de leitura inútil e latência.
  - `vm.watermark_scale_factor = 125`: Mantém uma margem segura de páginas livres, acionando o `kswapd` antecipadamente para evitar picos de latência (direct reclamation stalls).

### 5.2 Subsistema de Armazenamento e Btrfs NoCOW

Btrfs utiliza CoW (Copy-on-Write), o que gera severa fragmentação e degradação em cargas com escritas aleatórias em arquivos pré-alocados (imagens de disco `.qcow2` / `.raw` e bases de contêineres).

- **Enforcement Automático:** Aplicado via `systemd-tmpfiles` antes da criação de arquivos nos seguintes caminhos:
  - `/var/lib/libvirt/images` (`+C`)
  - `/var/lib/containers/storage` e volumes (`+C`)
  - `/var/lib/docker` (`+C`)
  - `/var/lib/distrobox` (`+C`)
  - Espaços de usuário correspondentes (`~/.local/share/containers/storage`, `~/.local/share/libvirt/images`).

### 5.3 Subsistema Gráfico, IA Local & Multimídia

- **Aceleração 3D / Vulkan:** `AMD_VULKAN_ICD=RADV`, selecionando o driver de código aberto de alto desempenho da comunidade Mesa.
- **Suporte a IA / ROCm:** O hardware host conta com a GPU RX 6600 XT (arquitetura Navi 23 / `gfx1032`). Por padrão, runtimes de IA (ROCm/HIP, PyTorch, llama.cpp) suportam primariamente arquiteturas comerciais da linha CDNA ou Navi 21 (`gfx1030`). A variável:
  $$\text{HSA\_OVERRIDE\_GFX\_VERSION} = 10.3.0$$
  está propagada em `/etc/profile.d` e `/usr/lib/environment.d`, permitindo que contêineres e aplicações executem kernels HIP diretamente na GPU sem falhas de inicialização de hardware.

### 5.4 Automação de Atualizações com Resiliência de Rede

O sistema implementa uma automação de atualização sem precedentes em estações Linux:

- **Janela de Execução:** Os timers de atualização (`bootc-fetch-apply-updates`, `flatpak-system-update`, `podman-auto-update`, `soar-upgrade-packages`) iniciam **5 minutos após o boot** (`OnBootSec=5m`) e executam **a cada 45 minutos** (`OnUnitActiveSec=45m`).
- **Resiliência D-Bus / NetworkManager:** Para impedir consumo indevido de franquias móveis ou falhas ruidosas quando offline, o serviço executa a verificação prévia:
  ```bash
  ExecCondition=/usr/bin/bash -c 'm=$(/usr/bin/busctl --system get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Metered 2>/dev/null || true); c=$(/usr/bin/busctl --system get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Connectivity 2>/dev/null || true); [[ -n "$m" && -n "$c" && "$m" != *" 1" && "$m" != *" 3" && "$c" != *" 1" && "$c" != *" 2" && "$c" != *" 3" ]]'
  ```
  Se a conexão estiver tarifada (Metered) ou em estado de portal cativo/sem internet (Connectivity != 4), o serviço aborta de forma limpa com código zero (skip), sem poluir o journal com mensagens de erro.
- **Priorização de Recursos:** O processo de download e descompressão de camadas opera em classe de I/O e CPU idle (`Nice=19`, `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`), garantindo impacto nulo na renderização do desktop a 144Hz+.

---

## 6. Auditoria de Arquitetura & Dívidas Técnicas Identificadas

Durante a auditoria exaustiva do repositório realizada pela perspectiva do Arquiteto Revisor, identificou-se os seguintes pontos de atenção e melhoria imediata:

|   Item   | Arquivo / Componente                  | Natureza do Problema                                                                                                                           | Impacto / Risco                                                       |
| :------: | :------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- |
| **A-01** | `recipes/common-flatpaks.yml`         | Duplicação do pacote `org.fkoehler.KTailctl` nas linhas 42 e 44.                                                                               | Baixo (idempotência no Flatpak, mas denota falta de linting estrito). |
| **A-02** | `.github/workflows/check-updates.yml` | Agendamento via cron `0 */2 * * *` (a cada 2 horas), enquanto a diretriz do `agent.md` especifica checagem a cada hora (`0 * * * *`).          | Médio (atraso na detecção de patches de segurança upstream).          |
| **A-03** | `recipes/common-drivers.yml`          | Pacotes ROCm do sistema comentados (`rocm-smi`, `rocm-hip`, `rocm-opencl`). Usuário precisa de IA local, mas as libs não estão na imagem base. | Alto para Developer Experience (obriga setup manual em contêineres).  |
| **A-04** | `.github/workflows/build-amd.yml`     | Build manual exclusivo (`workflow_dispatch`), sem disparo automático em push na branch principal (`main`).                                     | Médio (desalinhamento com GitOps contínuo).                           |
| **A-05** | `recipes/common-brew.yml`             | Módulo `soar` habilitado com auto-upgrade a cada `45m`, gerando concorrência desnecessária com o timer do systemd.                             | Baixo / Médio (potencial contenção de lock no diretório de usuário).  |

---

## 7. Recomendações e Melhorias Arquiteturais Sugeridas (Roadmap)

### 7.1 Melhoria 1: Implementação de CDI (Container Device Interface) para Aceleração ROCm

- **Contexto:** Manter o runtime do ROCm limpo do sistema base é uma excelente prática para evitar inflar a imagem OCI em mais de 4 GB. No entanto, passar a GPU AMD RX 6600 XT para contêineres Podman frequentemente exige permissões excessivas (`--privileged`, `--device /dev/kfd`, `--device /dev/dri`).
- **Proposta Arquitetural:** Adicionar uma especificação declarativa de **CDI (Container Device Interface)** em `/etc/cdi/amdgpu.yaml`. Isso permite executar contêineres de inferência (como Ollama ou vLLM) com a flag limpa e segura `podman run --device amd.com/gpu=all`.

### 7.2 Melhoria 2: CI/CD GitOps com Validação Automatizada de Boot (Boot Validation Gate)

- **Contexto:** Atualmente, a imagem é compilada no GitHub Actions, mas se um módulo de kernel ou argumento do GRUB corromper o initramfs, o erro só será notado pelo usuário após a reinicialização da máquina física.
- **Proposta Arquitetural:** Integrar um job de teste no GitHub Actions utilizando `qemu-system-x86_64` ou `bootc-image-builder` em modo headless (KVM nos runners do GitHub) para realizar um boot de validação (Sanity Boot Check) antes de mover a tag `:latest` no GHCR.

### 7.3 Melhoria 3: Automação Integrada de Políticas Flatpak Overrides

- **Contexto:** Aplicativos Flatpak (como VS Code e navegadores) executam sob sandboxing restrito. Frequentemente, o desenvolvedor precisa de permissões de acesso ao socket do Podman, Wayland nativo e diretórios de projetos.
- **Proposta Arquitetural:** Criar um módulo declarativo em `/files/system/etc/flatpak/overrides/` fornecendo permissões calibradas pré-configuradas para o VS Code acessar o socket de contêiner e o agente SSH, reduzindo atrito pós-instalação.

### 7.4 Melhoria 4: Autenticação de Supply Chain com Attestation SLSA L3

- **Contexto:** O projeto já utiliza Cosign para assinar a imagem final (`cosign_private_key: ${{ secrets.SIGNING_SECRET }}`).
- **Proposta Arquitetural:** Evoluir para **GitHub Artifact Attestations** (compatível com Sigstore e in-toto), permitindo geração de SBOM (Software Bill of Materials) em formato SPDX e atestação de proveniência criptográfica sem necessidade de gerenciar segredos manuais de chave privada de longo prazo no repositório.

### 7.5 Melhoria 5: Sincronização de Cron do Pipeline de Checagem Upstream

- **Contexto:** Ajustar o cron de `.github/workflows/check-updates.yml` para `0 * * * *` para atender formalmente ao requisito estipulado em `agent.md`, garantindo alinhamento total entre documentação e código de infraestrutura.

---

## 8. Matriz de Decisões Arquiteturais (ADRs Resumidos)

### ADR-001: Adoção do Framework BlueBuild sobre Containerfile Raw

- **Decisão:** Utilizar o BlueBuild (`recipes/*.yml`) em detrimento de Containerfiles imperativos.
- **Justificativa:** BlueBuild provê abstração declarativa padronizada, suporte nativo a módulos reutilizáveis, compilação otimizada com cache de camadas (`chunkah`), gerenciamento automatizado de initramfs e integração com assinatura Cosign, reduzindo linhas de código imperativo em 70%.

### ADR-002: Transição Nativa de Imagens via `bootc` em vez de `rpm-ostree rebase`

- **Decisão:** Padronizar comandos e documentação no utilitário `bootc` (projeto upstream Red Hat/Fedora para contêineres inicializáveis).
- **Justificativa:** O `bootc` trata a imagem OCI como fonte canônica e de primeira classe, integrando-se diretamente com registries OCI padrão e garantindo consistência semântica com o ecossistema de contêineres corporativo moderno.

### ADR-003: Alocação Agressiva de ZRAM zstd com Alto Swappiness

- **Decisão:** Definir ZRAM para 50% da memória (32 GB) com `vm.swappiness=150` em uma estação de 64 GB de RAM física.
- **Justificativa:** Em ambientes com máquinas virtuais de grande porte e modelos de linguagem locais, a demanda de memória ocorre em surtos abruptos. Manter as páginas ociosas comprimidas em memória ultrarrápida preserva o cache de disco do sistema operacional, evitando gargalos de I/O no NVMe e garantindo estabilidade absoluta contra o OOM killer.

---

## 9. Procedimentos Operacionais Padrão (SOP) & Recuperação de Desastres

| Operação                         | Comando Canônico                                         | Comportamento Esperado                                                                                        |
| :------------------------------- | :------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------ |
| **Verificação de Estado**        | `bootc status`                                           | Exibe a implantação ativa, hash de digest OCI e se há atualizações em staging preparadas para o próximo boot. |
| **Atualização Manual**           | `sudo bootc update`                                      | Baixa atomicamente as novas camadas da imagem em background. Aplicação efetivada no próximo reboot.           |
| **Rollback Atômico**             | `sudo bootc rollback`                                    | Alterna o ponteiro de boot para a implantação imediatamente anterior. Efetivado no próximo reboot.            |
| **Reversão para Upstream**       | `sudo bootc switch quay.io/fedora/fedora-kinoite:latest` | Retorna o sistema ao Fedora Kinoite puro original de fábrica.                                                 |
| **Auditoria de Drift no `/etc`** | `sudo ostree admin config-diff`                          | Lista todas as modificações manuais locais realizadas sobre os arquivos de configuração do sistema.           |

---

_Documento aprovado e mantido sob controle de versão do repositório `jbdsjunior/kinoite-bluebuild`._
