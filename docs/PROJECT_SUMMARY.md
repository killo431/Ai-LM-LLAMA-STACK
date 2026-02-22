# Project Summary — Ai-LM-LLAMA-STACK

## What Is This Project?

**Ai-LM-LLAMA-STACK** is an open-source, self-hosted AI platform that lets developers and researchers run a complete AI ecosystem on their own hardware. The stack integrates local LLM inference, multi-agent orchestration, visual workflow automation, retrieval-augmented generation (RAG), and a document Q&A interface—all wired together through Docker Compose and a private internal network.

No data ever leaves the machine. There are no external API calls required to get started.

---

## Problem It Solves

Cloud AI services provide convenience but come with trade-offs: cost at scale, data-privacy concerns, internet dependency, and vendor lock-in. **Ai-LM-LLAMA-STACK** removes all of those barriers by providing a curated, pre-configured set of best-in-class open-source AI tools that work together out of the box.

---

## Key Components

### Inference Engine
| Component | Role |
|---|---|
| **Ollama** | Serves quantized LLMs (Llama, Mistral, Mixtral, CodeStral, LLaVA, etc.) over a REST API at `localhost:11434`. Supports CPU and AMD ROCm GPU acceleration. |

### User Interfaces
| Component | Role |
|---|---|
| **Open WebUI** | A polished chat interface (similar to ChatGPT) that connects directly to Ollama. Available at `localhost:8080`. |
| **AnythingLLM** | Upload documents (PDF, DOCX, TXT, etc.) and query them with your local LLM. Available at `localhost:3001`. |

### Agentic Orchestration
| Component | Role |
|---|---|
| **CrewAI Studio** | A Streamlit-based visual builder for defining multi-agent crews, tasks, and tools. Backed by the Python `crewai` library. Available at `localhost:8501`. |
| **Flowise** | A drag-and-drop LangChain / LlamaIndex flow designer for building conversational AI chains. Available at `localhost:3000`. |

### Workflow Automation
| Component | Role |
|---|---|
| **n8n** | A no-code/low-code workflow automation platform that can trigger AI pipelines, connect external APIs, and process events. Available at `localhost:5678`. |

### Memory & Storage
| Component | Role |
|---|---|
| **Qdrant** | A high-performance vector database used for semantic search, embedding storage, and agent memory. Available at `localhost:6333`. |
| **LightRAG** | A graph-enhanced RAG server that builds knowledge graphs from ingested documents for higher-quality retrieval. Available at `localhost:9621`. |
| **PostgreSQL** | A relational database used internally by n8n and CrewAI Studio for persistent state. |

---

## Technology Stack

| Layer | Technologies |
|---|---|
| Container runtime | Docker Compose v2 |
| LLM inference | Ollama (CPU + AMD ROCm GPU) |
| Agent framework | CrewAI 0.4.x, Flowise |
| RAG | LightRAG, AnythingLLM |
| Vector store | Qdrant |
| Workflow engine | n8n |
| Web UI | Open WebUI |
| Database | PostgreSQL 16 |
| Scripting | Python 3.13+, PowerShell 7+, Bash |
| Target platform | Windows 11 / WSL2 (Ubuntu 22.04), Linux, macOS |

---

## Design Principles

1. **Privacy-first** — Everything runs locally. No telemetry or cloud calls are required.
2. **Zero-to-running quickly** — A single `docker compose up -d` brings the full stack online.
3. **Opinionated but extensible** — Sensible defaults are provided; every service can be customised or swapped.
4. **Learning-focused** — Intended as an experimentation platform, not a production deployment.

---

## Getting Started in 60 Seconds

```bash
git clone https://github.com/killo431/Ai-LM-LLAMA-STACK.git
cd Ai-LM-LLAMA-STACK
cp .env.example .env
mkdir -p volumes/{flowise_data,crewai_studio_data,lightrag_rag_storage,lightrag_inputs,lightrag_tiktoken,anythingllm_data,openwebui_data,n8n_storage,ollama_storage,qdrant_storage}
docker compose up -d
```

Then open **http://localhost:8080** to start chatting with your local LLM.

---

## Repository Layout

```
.
├── agents/            CrewAI agent definitions
├── config/            YAML configs for CrewAI
├── docs/              Project documentation (this folder)
├── memory/            Qdrant memory module
├── scripts/           Setup, health-check and backup scripts
├── volumes/           Bind-mounted Docker data volumes
├── docker-compose.yml Main service definitions
├── docker-compose.gpu.yml  AMD ROCm GPU override
├── Dockerfile         Multi-stage image build
├── run_crewai.py      Python CrewAI entrypoint
└── deployment_agent.py  Automated deploy/verify agent
```

---

## Roadmap Ideas

- NVIDIA CUDA GPU override alongside AMD ROCm
- Pre-built example n8n workflows
- Example CrewAI crews (research, coding, content)
- Web-based health-check dashboard
- One-click Windows installer

---

*For full setup instructions, see [README.md](../README.md). To contribute, read [CONTRIBUTING.md](../CONTRIBUTING.md).*
