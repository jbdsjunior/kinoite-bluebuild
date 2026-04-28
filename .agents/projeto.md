# PROJETO — BlueBuild / Fedora Kinoite

## AMBIENTE

- OS: Fedora Kinoite (baseline 2026, rolling).
- Filesystem: BTRFS (NoCOW em camadas de containers/VMs).
- Atomicidade obrigatória em todas as transições de imagem.

## HARDWARE

- CPU: AMD Ryzen 9 5950X (16c/32t).
- RAM: 64 GB DDR4.
- Storage: 1 TB NVMe.

## TOPOLOGIA MULTI-GPU

- **GPU0 (Primária):** AMD RX 6600 XT → Wayland/Display exclusivo.
- **GPU1 (Secundária):** NVIDIA RTX 3080 Ti → CUDA / LLM exclusivo.
- **Regra:** Isolamento de drivers é inegociável. Nenhuma operação deve provocar conflito de DRM/KMS entre AMDGPU e NVIDIA.

## CARGAS DE TRABALHO

- Navegação pesada + vídeo acelerado por hardware.
- Desenvolvimento de software.
- Execução e otimização de modelos de IA locais (GPU1).

## HARD CONSTRAINTS

- **Regra:** Imagens e Jobs CI/CD AMD/NVIDIA estritamente separados. Modularidade inegociável.
- **Proibição:** Funcionalidade _Rechunk_ permanece DESATIVADA.
- **Isolamento:** Qualquer arquitetura mutável ou brecha de segurança deve ser reescrita para rollback atômico e isolamento limpo.
