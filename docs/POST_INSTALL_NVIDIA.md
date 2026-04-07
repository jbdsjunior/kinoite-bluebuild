# Guia Pós-Instalação: NVIDIA e Híbrido (`kinoite-nvidia`)

Validação de runtime, integração GPU com containers e Secure Boot para sistemas com GPUs NVIDIA.

> **Pré-requisito:** Complete primeiro os passos em [`POST_INSTALL.md`](POST_INSTALL.md).

## Secure Boot (Enrollment MOK)

Se Secure Boot estiver habilitado, registre a chave para módulos kernel NVIDIA:

```bash
ujust enroll-secure-boot-key
```
