# Build ISO de instalação (BlueBuild)

Este repositório agora inclui um workflow dedicado para gerar ISO de instalação a partir de **recipe** ou de **imagem OCI publicada**.

## O que é recomendado na prática

1. **Preferir `image` em produção** quando a imagem já está publicada (ex.: GHCR) e assinada.
   - Evita diferenças entre ambiente local e CI.
   - Permite gerar a ISO a partir de uma referência explícita e auditável (idealmente digest, não só `:latest`).
2. **Usar `recipe` para desenvolvimento e validação** quando você está iterando no conteúdo da imagem.
3. **Nomear ISO com variante + run number/data** para facilitar rastreabilidade.
4. **Publicar ISO apenas como artifact de workflow** (retenção curta), em vez de versionar no git.

## Sobre os comandos citados

Os dois formatos são válidos no BlueBuild CLI:

```bash
sudo bluebuild generate-iso --iso-name weird-os.iso image ghcr.io/octocat/weird-os
sudo bluebuild generate-iso --iso-name weird-os.iso recipe recipes/recipe.yml
```

No contexto deste projeto:

- Para AMD: `recipe recipes/recipe-amd.yml`
- Para NVIDIA: `recipe recipes/recipe-nvidia.yml`

## Workflow criado

Arquivo: `.github/workflows/build-iso.yml`

### Entradas (workflow_dispatch)

- `source`: `recipe` ou `image`
- `variant`: `amd` ou `nvidia` (quando `source=recipe`)
- `image_ref`: referência da imagem OCI (quando `source=image`)
- `iso_name`: nome opcional do arquivo ISO

### Como usar

1. Vá em **Actions → build-iso → Run workflow**.
2. Escolha:
   - `source=recipe` + `variant=amd|nvidia`, **ou**
   - `source=image` + `image_ref=ghcr.io/<org>/<imagem>:<tag|digest>`.
3. Baixe a ISO no artifact gerado ao final do job.

## Exemplo recomendado para release

Use imagem já publicada e idealmente por digest:

```bash
bluebuild generate-iso --iso-name kinoite-amd-release.iso image ghcr.io/jbdsjunior/kinoite-amd@sha256:<digest>
```

## Limitações comuns

- A geração de ISO é pesada (tempo e espaço em disco no runner).
- Algumas bases podem demandar mais dependências durante o processo.
- Se usar imagem privada, ajuste permissões/token de leitura no workflow.
