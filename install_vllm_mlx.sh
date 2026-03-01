#!/bin/bash
# ==============================================================================
# GOLDEN INSTALLER: Distributed vLLM MLX + Ray (Apple Silicon)
# Author: ProtoAI-Bakari
# ==============================================================================
set -euo pipefail

VENV_DIR="$HOME/.vllm_mlx_ray"
REPO_DIR="$HOME/vllm-mlx-workspace"

echo "============================================================"
echo "🚀 INITIATING GOLDEN DEPLOYMENT"
echo "============================================================"

if ! command -v python3.12 &> /dev/null; then
    echo "❌ FATAL: python3.12 is required but not found in PATH."
    echo "Please install via: brew install python@3.12"
    exit 1
fi

echo "=> [1] Forging pristine workspace and virtual environment..."
mkdir -p "$REPO_DIR" && cd "$REPO_DIR"
python3.12 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo "=> [2] Upgrading build toolchain..."
pip install --upgrade pip cmake ninja wheel > /dev/null

echo "=> [3] Cloning optimized repositories..."
rm -rf vllm vllm-metal
git clone -b fix/bakari-apple-silicon-ray-sync https://github.com/ProtoAI-Bakari/vllm.git
git clone -b feat/bakari-metal-ray-distributed https://github.com/ProtoAI-Bakari/vllm-metal.git

echo "=> [4] Injecting strict dependency bounds..."
pip install -r vllm-metal/requirements.txt

echo "=> [5] Compiling Core and Metal Plugin (No-Deps)..."
pip install -c vllm-metal/requirements.txt -e ./vllm
pip install -c vllm-metal/requirements.txt -e ./vllm-metal

echo "============================================================"
echo "✅ DEPLOYMENT SUCCESSFUL."
echo "Activate environment: source $VENV_DIR/bin/activate"
echo "============================================================"
