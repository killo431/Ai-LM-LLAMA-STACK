# Multi-stage build for CrewAI and Ollama ROCm

# Stage 1: MyCrewAI
FROM python:3.12-slim-bookworm AS crewai-build
WORKDIR /CrewAI-Studio
RUN apt update && apt upgrade -y && apt-get install build-essential git -y
COPY ./crewai/requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt
COPY ./crewai/ .
EXPOSE 8501
# Example: ensure groups exist in the image with specific GIDs
RUN groupadd -g 44 video || true \
 && groupadd -g 107 render || true \
 && groupadd -g 302 kfd || true

# Stage 2: Ollama ROCm
FROM ollama/ollama:rocm AS ollama-build
ENV INSTANCES="mixtral:8x7b-instruct-q4_k_m,mistral-openhermes:7b-q5_k_m,codestral:22b-v0.1-q3_k_s,llava-llama3:8b"
ENV GPUS_COUNT=1
ENV SHARED_PATH_HOST="/data/shared"
ENV MEMORY_LIMIT="32G"
ENV USABLE_CPU_CORES_COUNT=14
RUN mkdir -p /data/shared
COPY scripts/download_models.sh /usr/local/bin/download_models.sh
COPY scripts/import_models_rocm.sh /usr/local/bin/import_models_rocm.sh
RUN chmod +x /usr/local/bin/download_models.sh /usr/local/bin/import_models_rocm.sh
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
EXPOSE 11434
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
