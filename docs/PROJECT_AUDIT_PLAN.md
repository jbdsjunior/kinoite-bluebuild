# Plano de Auditoria, Modularização e Manutenção Contínua (Kinoite BlueBuild)

> **Status:** Proposta / Plano de Engenharia (Aguardando Aprovação)
> **Data:** Setembro de 2026
> **Alvo:** Repositório `jbdsjunior/kinoite-bluebuild`
> **Diretrizes:** Zero perda de informações e recursos; Máxima modularidade, minimalismo, organização e facilidade para manutenção e updates contínuos.

---

## 1. Diagnóstico da Auditoria (Estado Atual)

Uma auditoria exaustiva de todos os componentes do projeto revelou os seguintes pontos de atenção e oportunidades de melhoria:

### 1.1 Receitas BlueBuild (`recipes/`)

1. **Redundância de Repositórios**: O repositório `terra.repo` é importado separadamente em `common-fonts.yml` (para `ms-core-fonts`) e em `common-tools.yml` (para `topgrade` e `starship`). Isso causa buscas redundantes de metadados durante o build.
2. **Código Morto / Comentado**: Blocos extensos de código YAML comentados em `common-drivers.yml` (`@multimedia`, pacotes ROCm desativados), `common-flatpaks.yml` (dezenas de IDs de aplicativos comentados), `common-kargs.yml` e `common-tools.yml`.
3. **Ordem de Execução no `recipe-amd.yml`**: O módulo `type: files` está posicionado no início do pipeline (antes do debloat e antes da instalação dos pacotes). Na especificação do BlueBuild/bootc, sobreposições de arquivos (`files`) devem ocorrer após a instalação dos pacotes base, garantindo que arquivos personalizados em `/usr/lib` e `/etc` sobreponham de forma previsível os arquivos padrões dos pacotes RPM, sem gerar arquivos `.rpmnew`.

### 1.2 Hierarquia do Sistema Imutável (`files/system/`)

1. **Duplicidade de Variáveis de Ambiente**: As mesmas variáveis (`HSA_OVERRIDE_GFX_VERSION`, `AMD_VULKAN_ICD`, `EDITOR`, `VISUAL`, `PAGER`, `FREETYPE_PROPERTIES`, `ELECTRON_OZONE_PLATFORM_HINT`) estão definidas identicamente em `/usr/lib/environment.d/60-kinoite-environment.conf` e em `/etc/profile.d/50-shell-env-overrides.sh`. No Linux moderno com systemd, `environment.d` é a fonte canônica para sessões gráficas e de usuário; o `profile.d` deve apenas complementar shells interativos sem redeclarar variáveis globais.
2. **Princípio do SO Stateless (Hermético)**: Arquivos estáticos de configuração como `/etc/containers/nodocker` podem residir sob `/usr/share/containers/nodocker`, preservando `/etc` limpo para configurações modificáveis pelo usuário.

### 1.3 Esteira CI/CD e Automação de Atualizações (`.github/workflows/`)

1. **Gatilhos de Build Incompletos em `build-amd.yml`**: A esteira de compilação da imagem (`build-amd.yml`) atualmente responde apenas a `workflow_dispatch` (manual) ou ao acionador do `check-updates.yml`. Alterações diretas no código de `recipes/` ou `files/` na branch `main` não disparam o build automaticamente.
2. **Ausência de CI Linter & Validador de PRs**: Falta uma validação rápida de Pull Requests e sintaxe (`yamllint`, `shellcheck`, schema BlueBuild) para barrar erros de digitação antes de gastar minutos de compilação em runners do GitHub.
3. **Gestão Contínua de Dependências (Renovate / Dependabot)**: Não há automação declarativa para atualizar GitHub Actions, imagens base e utilitários.

---

## 2. Pilares do Plano de Implementação

```
+---------------------------------------------------------------------------------------+
|                                PILARES DE OTIMIZAÇÃO                                  |
+-------------------+-------------------+-------------------+---------------------------+
| 1. Receitas       | 2. Sistema        | 3. CI/CD &        | 4. DX &                   |
|    Modulares      |    Stateless      |    Automação      |    Manutenção             |
| Unificação repos; | Única fonte env;  | Triggers Git;     | Justfile nativo;          |
| limpeza de dead   | /usr prioritário; | Linter PRs;       | Scripts vinculados;       |
| code; reordenação.| script canônico.  | Renovate updates. | Docs sincronizados.       |
+-------------------+-------------------+-------------------+---------------------------+
```

### Pilar 1: Otimização e Modularidade Declarativa das Receitas (`recipes/`)

- **Ação 1.1 - Reorganização de Módulos & Centralização de Repositórios:**
  - Criar um arquivo `recipes/common-repos.yml` (ou unificar repositórios em `common-core.yml`) para que `terra.repo`, `rpmfusion` e outros repositórios externos sejam baixados e gerenciados em um único estágio previsível.
- **Ação 1.2 - Higienização de Código Morto:**
  - Remover os blocos de código comentados em `common-drivers.yml`, `common-flatpaks.yml` e `common-tools.yml`.
  - Documentar pacotes opcionais e variantes no catálogo de documentação, mantendo as receitas puras, legíveis e estritamente declarativas.
- **Ação 1.3 - Reordenação Estrutural em `recipe-amd.yml`:**
  - Mover o módulo `type: files` para executar logo antes de `initramfs` e `signing`, garantindo precedência absoluta sobre quaisquer arquivos padrão instalados pelos RPMs.

---

### Pilar 2: Conformidade do Sistema Imutável (`files/system/`)

- **Ação 2.1 - Eliminação de Redundância nas Variáveis de Ambiente:**
  - Manter `/usr/lib/environment.d/60-kinoite-environment.conf` como **fonte canônica** de variáveis do sistema (GPU AMD, editores, fontes FreeType, Electron Wayland).
  - Limpar `/etc/profile.d/50-shell-env-overrides.sh` para focar exclusivamente na interatividade do shell (Starship, Zoxide, FZF bindings e Fastfetch), consumindo as variáveis já exportadas pelo systemd sem duplicá-las.

---

### Pilar 3: Automação CI/CD e Atualizações Contínuas (`.github/`)

- **Ação 3.1 - Configuração Completa de Triggers em `build-amd.yml`:**
  - Adicionar gatilho automático para push na branch `main`:
    ```yaml
    on:
      workflow_dispatch:
      push:
        branches: [main]
        paths-ignore:
          - "docs/**"
          - "README.md"
          - "LICENSE"
          - ".gitignore"
    ```
- **Ação 3.2 - Workflow de Validação Estática e Linter (`.github/workflows/lint.yml`):**
  - Criar pipeline ultrarrápido (executa em ~30s) disparado em Pull Requests e Pushes:
    - `yamllint` em todas as receitas e workflows.
    - `shellcheck` ou `bash -n` em scripts shell (`files/system/usr/bin/`, `scripts/`).
    - Validação de esquema do BlueBuild contra `https://schema.blue-build.org/recipe-v1.json`.
- **Ação 3.3 - Atualização Contínua com Renovate (`.github/renovate.json`):**
  - Configurar Renovate para abrir PRs automáticos semanais atualizando versões de GitHub Actions, digests de base e imagens de suporte, mantendo o repositório seguro e atualizado sem esforço manual.

---

### Pilar 4: Experiência do Desenvolvedor (DX) & Operação (`Justfile`)

- **Ação 4.1 - Criar um `Justfile` na raiz do projeto:**
  - Prover comandos declarativos diretos:
    - `just check`: Executa validação de sintaxe e lint local.
    - `just status`: Exibe status consolidado do bootc, timers e Flatpaks.
    - `just update`: Aciona a atualização do sistema (bootc e flatpaks).

---

### Pilar 5: Consolidação da Documentação (`docs/`)

- **Ação 5.1 - Índice Unificado de Documentação:**
  - No `README.md`, referenciar de forma modular:
    - [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md) (Arquitetura e Decisões de Design)
    - [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) (Dimensionamento e Hardware AMD)
    - [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) (Checklist de pós-instalação e uso diário)

---

## 3. Matriz de Segurança e Não-Regressão

| Recurso / Componente                 | Estado Atual                                  | Estado Pós-Plano   | Garantia de Não-Regressão                         |
| :----------------------------------- | :-------------------------------------------- | :----------------- | :------------------------------------------------ |
| **Atualização do Sistema (Polling)** | Ativo (`bootc-fetch-apply-updates.timer` 45m) | Mantido 100% ativo | Sem alterações no timer padrão do bootc.          |
| **Drivers AMD / Mesa Freeworld**     | Configurado em `common-drivers.yml`           | Mantido 100% ativo | Pacotes de aceleração de vídeo e GPU preservados. |
| **Virtualização KVM / Libvirt**      | Modular libvirt daemons e regras NoCOW        | Mantido 100% ativo | Zero alteração em pacotes e tmpfiles.d.           |
| **Fontes & CJK**                     | Fontconfig 64 + pacotes CJK estáticos         | Mantido 100% ativo | Noto CJK, WQY e Inter mantidos.                   |
| **Rclone Sync**                      | `rclone@.service` + env files declarativos    | Mantido 100% ativo | Sem alteração nos templates de serviço.           |

---

## 4. Fases Sugeridas para Execução (Quando Aprovado)

- **Fase 1:** Criação do `Justfile` e workflow de Lint/Validação (`.github/workflows/lint.yml`).
- **Fase 2:** Limpeza e modularização das receitas (`recipes/`) e unificação de repositórios.
- **Fase 3:** Refatoração de variáveis (`environment.d` vs `profile.d`) e eliminação de redundâncias de scripts.
- **Fase 4:** Adição dos gatilhos automáticos de push no `build-amd.yml` e configuração do Renovate.
- **Fase 5:** Atualização e alinhamento final dos links no `README.md` e `docs/`.
