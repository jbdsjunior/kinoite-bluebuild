# Hardware Baseline & Tuning Rationale

## Perfil-alvo

Este projeto é otimizado para workstation de alta capacidade, com foco em KDE Plasma + virtualização + containers + cargas de desenvolvimento.

| Componente | Especificação de referência |
| :-- | :-- |
| **CPU** | AMD Ryzen 9 5950X |
| **GPU Primária (display/Wayland)** | AMD RX 6600 XT |
| **GPU Secundária (compute)** | NVIDIA RTX 3080 Ti |
| **RAM** | 64 GB |
| **Storage** | 1 TB NVMe |
| **SO Base** | Fedora Kinoite |

---

## Motivação técnica

- O baseline prioriza estabilidade para multitarefa pesada, VMs, containers e compilação local.
- A arquitetura híbrida AMD+NVIDIA separa renderização desktop (AMD) de workloads CUDA/compute (NVIDIA).
- Ajustes de I/O e serviços estão versionados para comportamento previsível em ambiente imutável.

---

## Limites operacionais esperados

Em hardware abaixo desse baseline, você pode observar:

- maior latência na sessão gráfica sob carga;
- degradação em builds locais e rotinas de virtualização;
- concorrência de memória em workloads paralelos.

> ⚠️ **Aviso:** o projeto não impede execução em hardware inferior, mas foi validado e ajustado para o baseline acima.

---

## Relação com receitas e variantes

| Variante | Pipeline | Perfil |
| :-- | :-- | :-- |
| `amd` | `.github/workflows/build-amd.yml` | sistemas sem dependência de stack NVIDIA |
| `nvidia` | `.github/workflows/build-nvidia.yml` | sistemas com GPU NVIDIA e requisitos de compute |

- Receitas principais: `recipes/recipe-amd.yml` e `recipes/recipe-nvidia.yml`.
- Módulos compartilhados: `recipes/common-*.yml`.
- Conforme configuração atual de CI, `build_chunked_oci` permanece **desativado** (`false`).
