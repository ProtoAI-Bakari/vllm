#!/bin/bash
set -euo pipefail

VENV_DIR="$HOME/.vllm_mlx_ray"
REPO_DIR="$HOME/vllm-mlx-workspace"
TARGET_PYTHON="3.12.10"

echo "============================================================"
echo "🚀 INITIATING ATOMIC GOLDEN DEPLOYMENT (v3.12.10 FORCE)"
echo "============================================================"

# 1. Pyenv Forge for Exact Version Parity
if [[ "$(/usr/bin/python3 -V 2>&1)" != "Python $TARGET_PYTHON" ]]; then
    echo "=> [1] Version mismatch or missing. Forcing Python $TARGET_PYTHON Forge..."
    brew install pyenv >/dev/null 2>&1 || true
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    
    echo "=> Building $TARGET_PYTHON from source (this may take 5 mins)..."
    export PYTHON_CONFIGURE_OPTS="--enable-shared"
    pyenv install --skip-existing "$TARGET_PYTHON"
    PYTHON_EXE="$HOME/.pyenv/versions/$TARGET_PYTHON/bin/python3"
else
    PYTHON_EXE=$(which python3)
fi

# 2. Workspace & Environment Isolation
echo "=> [2] Forging pristine workspace and virtual environment..."
mkdir -p "$REPO_DIR" && cd "$REPO_DIR"
"$PYTHON_EXE" -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# 3. Core Dependencies & Build Tools
echo "=> [3] Upgrading build toolchain..."
pip install --upgrade pip cmake ninja wheel > /dev/null

# 4. Public HTTPS Cloning
echo "=> [4] Cloning optimized repositories..."
rm -rf vllm vllm-metal
git clone -b fix/bakari-apple-silicon-ray-sync https://github.com/ProtoAI-Bakari/vllm.git
git clone -b feat/bakari-metal-ray-distributed https://github.com/ProtoAI-Bakari/vllm-metal.git

# 5. Pure Constraint Enforcement (No extras in constraints)
echo "=> [5] Injecting strict dependency bounds..."
sed 's/\[.*\]//g' vllm-metal/requirements.txt > pure_constraints.txt
pip install -r vllm-metal/requirements.txt
pip install -c pure_constraints.txt -e ./vllm
pip install -c pure_constraints.txt -e ./vllm-metal

echo "============================================================"
echo "✅ DEPLOYMENT SUCCESSFUL (Python $(python -V))"
echo "Activate environment: source $VENV_DIR/bin/activate"
echo "============================================================"
