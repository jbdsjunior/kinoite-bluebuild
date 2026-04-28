# ORGANIZAÇÃO DA BASE DE INSTRUÇÕES (`.agents/`)

## Objetivo

Evitar desorganização, duplicação e drift de contexto na operação de agentes LLM.

## Regras de classificação (onde cada coisa deve ficar)

- **Geral do agente (imutável por projeto):** `agent.md`
- **Contexto específico do projeto:** `projeto.md`
- **Práticas e padrões técnicos:** `skills.md`
- **Checklist de validação/auditoria:** `checklist.md`
- **Governança da estrutura e manutenção de arquivos:** `organizacao.md`

## Anti-sprawl (evitar crescimento desordenado)

1. Não adicionar conteúdo de projeto em `agent.md`.
2. Não duplicar regra em múltiplos arquivos; manter referência para fonte canônica.
3. Ao criar nova seção, justificar em 1 linha o motivo e o impacto operacional.
4. Se um arquivo ultrapassar ~200 linhas, considerar divisão temática.

## Fluxo de atualização recomendado

1. Identificar aprendizado novo.
2. Classificar por domínio (projeto, skill, checklist, governança).
3. Atualizar apenas o arquivo alvo.
4. Validar consistência cruzada com os demais arquivos.
5. Registrar mudança com resumo curto (o quê, por quê, impacto).

## Critérios de qualidade para LLM

- Instruções objetivas e verificáveis.
- Linguagem estável, sem termos vagos.
- Baixa redundância e alta recuperabilidade de contexto.
- Estrutura previsível (títulos e bullets consistentes).
