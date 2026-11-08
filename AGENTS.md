# Diretrizes Operacionais do Agente (AGENTS.md)

Este arquivo define os fluxos de trabalho, práticas de Git, regras de LLM/IA e invariantes operacionais para agentes e desenvolvedores.
O catálogo linear de frases simples com a arquitetura e arquivos do sistema operacional está em `docs/DIRECTIVES.md`.

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
- Mudanças que afetem arquivos do repositório exigem sincronização imediata da frase descritiva em `docs/DIRECTIVES.md`.
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
- Verifique se a cobertura de arquivos em `docs/DIRECTIVES.md` permanece em 100% após a criação, exclusão ou renomeação de arquivos.

## Índice de Consulta Cirúrgica (`docs/DIRECTIVES.md`)

- Consulte `docs/DIRECTIVES.md` sob demanda utilizando `read_file` pelo intervalo de linhas da categoria necessária.
- Arquitetura, organização do repositório, hardware e flavors: linhas 6 a 42 de `docs/DIRECTIVES.md`.
- Receitas BlueBuild, módulos e isolamento NVIDIA: linhas 44 a 71 de `docs/DIRECTIVES.md`.
- Armazenamento Btrfs NoCOW, ZRAM, limites de memória e segurança: linhas 73 a 101 de `docs/DIRECTIVES.md`.
- Timers de automação, ambiente desktop KDE e navegadores: linhas 103 a 140 de `docs/DIRECTIVES.md`.
- Aceleração de IA, CDI, periféricos, Rclone e CI/CD: linhas 142 a 168 de `docs/DIRECTIVES.md`.
- Invariantes de engenharia, regras proibidas e critérios de software: linhas 170 a 192 de `docs/DIRECTIVES.md`.
