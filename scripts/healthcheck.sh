#!/bin/bash
curl -f http://localhost:11434/api/health && echo "Ollama healthy"
curl -f http://localhost:6333/healthz && echo "Qdrant healthy"
curl -f http://localhost:8501/_stcore/health && echo "CrewAI healthy"
