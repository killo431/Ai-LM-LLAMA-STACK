#!/bin/bash
echo "Setup ROCm & Python environment in WSL2 Ubuntu 22.04"
echo "Run these commands manually or automate as needed:"
echo "sudo apt update && sudo apt upgrade -y"
echo "sudo apt install -y python3 python3-pip python3-venv build-essential curl git"
echo "Install AMD ROCm drivers from https://rocmdocs.amd.com/en/latest/Installation_Guide/Installation-Guide.html"
echo "pip3 install --upgrade pip"
echo "pip3 install crewai==0.4.12 qdrant-client[fastembed]==1.2.0 flowise==0.3.4 requests numpy pydantic httpx httpcore"
