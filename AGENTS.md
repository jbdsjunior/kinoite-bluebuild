# Diretrizes Operacionais do Agente (AGENTS.md)

Este arquivo define os fluxos de trabalho, práticas de Git, regras de LLM/IA e governança de contexto para agentes e desenvolvedores.

## Separação de Responsabilidades dos Arquivos de Diretrizes

- `AGENTS.md` e `PROJECTS.md` são as únicas fontes de verdade (SSOT) do projeto: `AGENTS.md` governa regras de processo, Git e validação; `PROJECTS.md` governa arquitetura, hardware, arquivos e invariantes de sistema.
- Documentos voltados a usuários e GitHub (`README.md`, `SECURITY.md` e `docs/POST_INSTALL.md`) são derivados e devem ser mantidos sincronizados a partir de `PROJECTS.md` em caso de divergência.
- O arquivo `AGENTS.md` contém exclusivamente: regras de operação do modelo de IA, boas práticas de Git, fluxo de trabalho/planejamento, testes de validação pré-commit e o índice de consulta de diretrizes.
- É proibido inserir no `AGENTS.md` descrições técnicas de hardware, arquitetura do SO, parâmetros de configuração ou inventário de arquivos do repositório.
- O arquivo `PROJECTS.md` contém exclusivamente: o catálogo linear completo de frases simples que descrevem a arquitetura do SO, hardware, GPUs, receitas BlueBuild, kargs, serviços, arquivos de configuração e regras de engenharia do sistema.
- É proibido inserir no `PROJECTS.md` instruções de comportamento de IA, comandos de terminal para agentes, práticas de Git ou regras de interação.

## Papel e Modo de Operação do Agente de IA

- O modelo opera prioritariamente em modo declarativo, econômico e cirúrgico, evitando verbosidade desnecessária.
- As respostas devem ser densas, objetivas e em português do Brasil, utilizando links clicáveis com o esquema `file://`.
- É obrigatório minimizar o consumo de tokens: nunca leia arquivos inteiros quando apenas partes específicas forem necessárias.
- Utilize `read_file` com parâmetros `StartLine` e `EndLine`, ou `grep` antes de abrir arquivos extensos.
- Para leitura de documentação externa ou busca web, use ferramentas locais ou endpoints dedicados sem despejar HTML bruto no contexto.
- Ao rodar comandos no terminal, evite comandos que emitam centenas de linhas sem filtro (`grep`, `head -n 40`, `tail -n 40`).
- Use `edit_file` com alvos cirúrgicos e mínimos em vez de reescrever arquivos inteiros com `write_file`.

## Fluxo de Trabalho e Planejamento

- Demandas de modificação estrutural, refatoração ou adição de componentes devem ser planejadas antes da execução.
- Sempre verifique o estado do repositório (`git status -s`) antes de iniciar modificações no código ou configurações.
- Quando houver ambiguidade no requisito, solicite alinhamento antes de tomar decisões arquiteturais irreversíveis.
- Mudanças que afetem arquivos do repositório exigem sincronização imediata da frase descritiva em `PROJECTS.md`.
- Concluída a tarefa, realize testes de integridade e apresente um resumo enxuto do que foi validado.

## Práticas de Git e Controle de Versão

- Os commits devem seguir rigorosamente o padrão Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `ci:`, `chore:`).
- Não realize `git commit -a` ou adicione diretórios inteiros sem inspeção.
- O stage de alterações deve ser feito de forma individual por arquivo através de `git add <caminho/do/arquivo>`.
- Inspecione detalhadamente o diff preparado com `git diff --cached` antes de efetivar o commit.
- O `.gitignore` deve proteger a governança de segredos e manter arquivos de regras e documentação devidamente rastreados.
- O envio ao repositório remoto deve ser realizado somente após todas as verificações pré-commit passarem sem erros.

## Validação Obrigatória Pré-Commit

- Todo script shell (`.sh` ou executável em `files/system/usr/bin/`) deve passar na verificação `bash -n` sem erros de sintaxe.
- Todos os manifestos YAML em `recipes/` e `.github/` devem ser validados quanto à sintaxe antes de qualquer commit.
- Arquivos de configuração TOML e arquivos de unidades/sysctl/modprobe do systemd devem ser verificados contra erros de formato.
- Qualquer alteração nas regras de sistema deve ser validada executando `./files/system/usr/bin/kinoite-optimize --audit` com 100% de aprovação.
- Verifique se a cobertura de arquivos em `PROJECTS.md` permanece em 100% após a criação, exclusão ou renomeação de arquivos.

## Índice de Consulta Cirúrgica (`PROJECTS.md`)

- Consulte `PROJECTS.md` sob demanda utilizando `read_file` pelo intervalo de linhas da categoria necessária.
- Arquitetura, organização do repositório, hardware e flavors: linhas 6 a 43 de `PROJECTS.md`.
- Receitas BlueBuild, módulos e isolamento NVIDIA: linhas 45 a 71 de `PROJECTS.md`.
- Armazenamento Btrfs NoCOW, ZRAM, limites de memória e segurança: linhas 73 a 101 de `PROJECTS.md`.
- Timers de automação, ambiente desktop KDE e navegadores: linhas 103 a 142 de `PROJECTS.md`.
- Aceleração de IA, CDI, periféricos, Rclone e CI/CD: linhas 144 a 170 de `PROJECTS.md`.
- Invariantes de engenharia, regras proibidas e critérios de software: linhas 172 a 185 de `PROJECTS.md`.
