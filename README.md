# Ai-LM-LLAMA-STACK

A self-hosted AI platform that combines local LLM inference, multi-agent orchestration, visual workflow automation, retrieval-augmented generation (RAG), and document Q&A—all running on your own hardware with Docker Compose.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Services & Ports](#services--ports)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [GPU Support (AMD ROCm)](#gpu-support-amd-rocm)
- [Python Orchestration Layer](#python-orchestration-layer)
- [Useful Scripts](#useful-scripts)
- [Backup & Maintenance](#backup--maintenance)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Project Overview

**Ai-LM-LLAMA-STACK** is a fully local, privacy-first AI stack designed for developers and researchers who want to experiment with large language models, agentic workflows, and retrieval-augmented generation without relying on external cloud services.

All components communicate over a private Docker bridge network (`ai-network`) and persist their data in local bind-mounted volumes under `./volumes/`.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Host Machine                             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────┐  │
│  │  Open WebUI  │  │  AnythingLLM│  │     CrewAI Studio      │  │
│  │  :8080       │  │  :3001      │  │     :8501              │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬────────────┘  │
│         │                │                      │               │
│  ┌──────▼──────────────────────────────────────▼────────────┐  │
│  │                   ai-network (bridge)                     │  │
│  │                                                           │  │
│  │  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐   │  │
│  │  │  Ollama  │  │  Qdrant  │  │ LightRAG│  │  Flowise │   │  │
│  │  │  :11434  │  │  :6333   │  │  :9621  │  │  :3000   │   │  │
│  │  └─────────┘  └──────────┘  └─────────┘  └──────────┘   │  │
│  │                                                           │  │
│  │  ┌──────────────────────┐  ┌──────────────────────────┐  │  │
│  │  │       n8n            │  │       PostgreSQL          │  │  │
│  │  │       :5678          │  │       :5432 (internal)    │  │  │
│  │  └──────────────────────┘  └──────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Services & Ports

| Service | Port | Description |
|---|---|---|
| **Open WebUI** | `8080` | Chat interface for Ollama models |
| **CrewAI Studio** | `8501` | Visual multi-agent workflow builder (Streamlit) |
| **AnythingLLM** | `3001` | Document ingestion and Q&A |
| **Flowise** | `3000` | Drag-and-drop AI workflow designer |
| **n8n** | `5678` | General-purpose workflow automation |
| **LightRAG** | `9621` | Graph-enhanced RAG API server |
| **Ollama** | `11434` | Local LLM inference engine |
| **Qdrant** | `6333` / `6334` | Vector database (HTTP / gRPC) |
| **PostgreSQL** | `5432` (internal) | Relational database for n8n and other services |

---

## Prerequisites

### Windows 11 (primary target)

| Requirement | Notes |
|---|---|
| Windows 11 with WSL2 enabled | Virtualization must be on in BIOS |
| Ubuntu 22.04 LTS in WSL2 | `wsl --install -d Ubuntu-22.04` |
| Docker Desktop ≥ 4.x | Enable WSL2 backend integration |
| Python 3.13+ | Required for the orchestration scripts |
| PowerShell 7+ | Required for `scripts/install_deps.ps1` |
| AMD ROCm drivers (optional) | Only for GPU-accelerated Ollama |

### Linux / macOS

Docker Engine and Docker Compose v2 are sufficient for running the stack without WSL2.

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/killo431/Ai-LM-LLAMA-STACK.git
cd Ai-LM-LLAMA-STACK
```

### 2. Create your environment file

```bash
cp .env.example .env
```

Edit `.env` and fill in any API keys or custom values you need (see [Configuration](#configuration)).

### 3. Create volume directories

```bash
mkdir -p volumes/flowise_data volumes/crewai_studio_data \
          volumes/lightrag_rag_storage volumes/lightrag_inputs \
          volumes/lightrag_tiktoken volumes/anythingllm_data \
          volumes/openwebui_data volumes/n8n_storage \
          volumes/ollama_storage volumes/qdrant_storage
```

### 4. Start the stack

```bash
docker compose up -d
```

Wait for all health checks to pass (roughly 60–90 seconds on first run while images are pulled).

### 5. Access the services

| Interface | URL |
|---|---|
| Open WebUI (chat) | http://localhost:8080 |
| CrewAI Studio | http://localhost:8501 |
| AnythingLLM | http://localhost:3001 |
| Flowise | http://localhost:3000 |
| n8n | http://localhost:5678 |
| LightRAG API | http://localhost:9621 |
| Ollama API | http://localhost:11434 |
| Qdrant dashboard | http://localhost:6333/dashboard |

---

## Configuration

All runtime settings are controlled through the `.env` file. Copy `.env.example` as a starting point:

| Variable | Default | Description |
|---|---|---|
| `INSTANCES` | `mixtral:8x7b-instruct-q4_k_m,...` | Ollama models to load at startup |
| `OPENAI_API_KEY` | _(empty)_ | Optional OpenAI key for hybrid workflows |
| `ANTHROPIC_API_KEY` | _(empty)_ | Optional Anthropic key |
| `GROQ_API_KEY` | _(empty)_ | Optional Groq key |
| `SERPER_API_KEY` | _(empty)_ | Optional Serper web-search key |
| `LMSTUDIO_API_BASE` | _(empty)_ | LM Studio API endpoint for local models |
| `FLOWISE_USERNAME` | `admin` | Flowise web-UI username |
| `FLOWISE_PASSWORD` | `admin` | Flowise web-UI password |
| `OPEN_WEBUI_PORT` | `8080` | Host port for Open WebUI |
| `LIGHTRAG_PORT` | `9621` | Host port for LightRAG |
| `WEBHOOK_URL` | `http://localhost:5678` | Public URL used by n8n webhooks |
| `RESTART_OPTION` | `unless-stopped` | Docker restart policy |

> **Security note:** Change the default `FLOWISE_USERNAME`/`FLOWISE_PASSWORD` and the PostgreSQL password (`Texas123!` in `docker-compose.yml`) before exposing the stack to any network.

---

## GPU Support (AMD ROCm)

The stack ships an optional Docker Compose override for AMD GPUs:

```bash
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

You must set the GPU group IDs in `.env` first:

```dotenv
VIDEO_GID=44
RENDER_GID=107
KFD_GID=302
HSA_OVERRIDE_GFX_VERSION=11.0.0   # adjust for your GPU family
ROCM_VERSION=6.0
HIP_VISIBLE_DEVICES=0
```

For WSL2, run `scripts/setup_wsl.sh` from inside your Ubuntu terminal to install the ROCm prerequisites.

---

## Python Orchestration Layer

Beyond Docker, the repository contains a Python layer for programmatic control.

### CrewAI entrypoint (`run_crewai.py`)

Starts a CrewAI multi-agent crew using the configuration in `config/crewai_project.yaml`:

```bash
python run_crewai.py
```

Agent definitions live in `agents/agent_definitions.py`. Memory is backed by Qdrant via `memory/qdrant_storage.py`.

### Autonomous Deployment Agent (`deployment_agent.py`)

Runs a full end-to-end deploy cycle—installing dependencies, building images, starting containers, verifying services, and launching the orchestrator:

```bash
python deployment_agent.py
```

---

## Useful Scripts

| Script | Platform | Purpose |
|---|---|---|
| `scripts/install_deps.ps1` | Windows (PowerShell) | Guided dependency install checklist |
| `scripts/setup_wsl.sh` | WSL2 / Ubuntu | Install Python, pip, and ROCm in WSL2 |
| `scripts/download_models.sh` | Linux | Pull Ollama models into shared storage |
| `scripts/import_models_rocm.sh` | Linux | Import models for ROCm Ollama |
| `scripts/entrypoint.sh` | Docker | Container entrypoint for Ollama ROCm image |
| `scripts/healthcheck.sh` | Linux | Check health of all running services |
| `scripts/fetch_sources.sh` | Linux | Fetch upstream source packages |
| `scripts/backup_postgres.sh` | Linux | Dump PostgreSQL database to file |
| `scripts/backup_qdrant.sh` | Linux | Snapshot Qdrant collections to file |

---

## Backup & Maintenance

### PostgreSQL backup

```bash
bash scripts/backup_postgres.sh
```

### Qdrant snapshot

```bash
bash scripts/backup_qdrant.sh
```

### Update all images

```bash
docker compose pull
docker compose up -d
```

---

## Project Structure

```
Ai-LM-LLAMA-STACK/
├── agents/                  # CrewAI agent definitions and tool helpers
│   ├── __init__.py
│   ├── agent_definitions.py
│   └── tools.py
├── config/                  # YAML configuration for CrewAI and tasks
│   ├── crewai_project.yaml
│   ├── flows/
│   └── tasks.yaml
├── memory/                  # Qdrant-backed memory module
│   └── qdrant_storage.py
├── scripts/                 # Shell and PowerShell helper scripts
├── volumes/                 # Bind-mounted Docker volumes (created at runtime)
├── img/                     # Screenshots and logos
├── docker-compose.yml       # Main Compose file (CPU)
├── docker-compose.gpu.yml   # GPU override (AMD ROCm)
├── Dockerfile               # Multi-stage build (CrewAI + Ollama ROCm)
├── run_crewai.py            # CrewAI orchestration entrypoint
├── deployment_agent.py      # Autonomous deploy/verify agent
├── requirements.txt         # Python dependencies
├── .env.example             # Environment variable template
├── BUILD_INSTRUCTIONS.txt   # Step-by-step build guide
├── TASK_LIST.md             # Deploy checklist
├── CONTRIBUTING.md          # Contribution guidelines
└── README.md                # This file
```

---

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Key points:

- Keep PRs small and focused on a single change.
- This is a **learning and experimentation platform**—production-grade features are out of scope.
- Everything should work completely offline and locally by default.

---

## License

This project is distributed under the terms of the [LICENSE](LICENSE) file included in this repository.
