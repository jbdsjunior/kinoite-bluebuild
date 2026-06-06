# 🚀 Relatório de Refatoração e Melhorias: Kinoite BlueBuild (2026)

**Objetivo:** Modernizar a infraestrutura como código (IaC) do repositório, garantindo maior aderência aos princípios de sistemas imutáveis/atômicos e corrigindo anti-patterns de configuração de aplicações no *user space*.

## 1. Avaliação Crítica: Configuração de Browsers (Chrome/Brave) no Flatpak

**O Problema Atual:**
O uso do diretório `files/system/usr/etc/skel/.var/app/` para injetar as flags (`brave-flags.conf` e `chrome-flags.conf`) é considerado um anti-pattern em sistemas atômicos modernos.

* O diretório `/etc/skel` é avaliado apenas no momento da **criação de um novo usuário**.
* Para um usuário existente, se você adicionar uma nova flag otimizada no seu repositório Git, o sistema atualizará a imagem OCI, mas as alterações **não serão aplicadas** no diretório `~/.var/app/` do usuário existente após o reboot.

**A Solução Recomendada (Padrão 2026):**
A melhor prática para gerenciar configurações no *home directory* de sistemas imutáveis de forma idempotente é utilizar o **systemd-tmpfiles a nível de usuário** (`user-tmpfiles.d`). Isso garante que, a cada login, o sistema garanta a existência e o estado do arquivo, atualizando as flags automaticamente.

Além disso, as flags de Wayland (`--ozone-platform=wayland`) já são o comportamento padrão nas versões recentes do Chromium/Brave rodando em ambientes KDE Plasma modernos, podendo ser removidas para reduzir verbosidade.

### 📝 Instrução para o Agente LLM (Ação 1):

> "Agente, mova os arquivos `brave-flags.conf` e `chrome-flags.conf` do diretório `files/system/usr/etc/skel/.var/app/...` para um novo diretório de armazenamento somente leitura da imagem, como `files/system/usr/share/browser-configs/`. Em seguida, crie um novo arquivo de configuração do systemd-tmpfiles em `files/system/usr/share/user-tmpfiles.d/70-browser-flags.conf` com as seguintes diretivas (utilizando a ação 'L+' para criar um symlink forçado ou 'C' para copiar):
> `L+ %h/.var/app/com.brave.Browser/config/brave-flags.conf - - - - /usr/share/browser-configs/brave-flags.conf`
> `L+ %h/.var/app/com.google.Chrome/config/chrome-flags.conf - - - - /usr/share/browser-configs/chrome-flags.conf`
> Remova a flag `--ozone-platform=wayland` dos arquivos, pois tornou-se redundante."

---

## 2. Automação Declarativa de Permissões (Remoção do script manual)

**O Problema Atual:**
O arquivo `setup-kvm.sh` utiliza `usermod -aG libvirt,kvm` de forma imperativa. Em sistemas baseados em imagens OCI (ostree), a manipulação manual do `/etc/group` introduz estado local (drift) que quebra a filosofia de "reprodutibilidade total".

**A Solução Recomendada:**
A abordagem correta no ecossistema atual é não exigir que o usuário pertença ao grupo `libvirt`. Em vez disso, deve-se fornecer regras Polkit declarativas na imagem que permitem aos usuários do grupo `wheel` (ou usuários com uma sessão ativa local) gerenciar o `libvirtd` sem senhas adicionais.

### 📝 Instrução para o Agente LLM (Ação 2):

> "Agente, exclua o script `files/scripts/setup-kvm.sh` e remova qualquer referência a ele no `common-kvm.yml` e `docs/POST_INSTALL.md`. Em seu lugar, crie uma regra Polkit declarativa em `files/system/usr/share/polkit-1/rules.d/50-libvirt.rules` contendo o código JavaScript polkit padrão que concede permissões `org.libvirt.unix.manage` sem autenticação para usuários que pertençam ao grupo `wheel` ou tenham uma sessão de assento ativa (`subject.local && subject.active`)."

---

## 3. Gestão de Contêineres e Limpeza de Serviços

**O Problema Atual:**
Nos recipes de ferramentas (`common-tools.yml`), o pacote `podman-compose` está sendo instalado. Hoje, o Podman suporta nativamente o uso do `docker-compose` moderno em conjunto com o `podman.socket`, sendo o pacote de terceiros Python (`podman-compose`) menos atualizado para especificações Compose complexas.

Os systemd timers customizados para limpeza e updates (ex: `rpm-ostreed-automatic.timer.d/override.conf`) estão bem estruturados, mas devem aproveitar as novas features do systemd para randomização avançada de atrasos, evitando contenção de I/O massiva durante o boot.

### 📝 Instrução para o Agente LLM (Ação 3):

> "Agente, no arquivo `recipes/common-tools.yml`, substitua o pacote `podman-compose` pelo pacote padrão `docker-compose`. Verifique os arquivos `podman-user-prune.timer` e `podman-system-prune.timer` e adicione a propriedade `FixedRandomDelay=true` em conjunto com o `RandomizedDelaySec`, para garantir que o espalhamento de carga de I/O em background seja otimizado para a arquitetura Zen 3 (Ryzen 9 5950X)."

---

## 4. Estrutura e Práticas de CI/CD em Imagens OCI Otimizadas

**O Problema Atual:**
O arquivo `check-updates.yml` resolve o digest do *upstream* utilizando ferramentas locais no runner e armazena via cache de Actions puro, acionando o build via CLI do GitHub.

**A Solução Recomendada:**
Melhorar a semântica da esteira para que fique encapsulada, evitando redundância com o agendador padrão de dependências e mantendo o fluxo *event-driven* puro.

### 📝 Instrução para o Agente LLM (Ação 4):

> "Agente, no arquivo `.github/workflows/build-amd.yml`, certifique-se de que as ações invocadas (`actions/checkout`, `aquasecurity/trivy-action`, `github/codeql-action/upload-sarif`) estão utilizando os *hashes* exatos dos *commits* para maior segurança da cadeia de suprimentos (SLSA Nível 3), em vez das *tags* genéricas (ex: `@v6` ou `@v0.36.0`). Remova a declaração isolada de `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` do corpo global dos workflows se as versões atualizadas das ações utilizadas já estiverem compatíveis nativamente com Node 20/24."
