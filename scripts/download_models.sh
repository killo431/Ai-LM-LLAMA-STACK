#!/bin/bash
MODEL_LIST=(
  "mixtral:8x7b-instruct-q4_k_m"
  "mistral-openhermes:7b-q5_k_m"
  "codestral:22b-v0.1-q3_k_s"
  "llava-llama3:8b"
)
for MODEL in "${MODEL_LIST[@]}"; do
  ollama pull "$MODEL"
done
