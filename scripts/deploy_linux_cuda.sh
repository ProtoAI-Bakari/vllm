#!/bin/bash
# ==============================================================================
# vLLM DISTRIBUTED RAY ZERO-CLICK INSTALLER (NOBLE NUMBAT + VERBOSE)
# Target: Ubuntu 24.04 LTS (sys1-2x3090)
# ==============================================================================
set -euo pipefail

VENV_DIR="$HOME/.venvs/vLLM0160_disagg"
REPO_DIR="$HOME/DEV/bakari_vllm_linux"
TARGET_PYTHON="3.12.10"

echo "============================================================"
echo "🚀 INITIATING LINUX CUDA DEPLOYMENT (Ubuntu 24.04 / Python $TARGET_PYTHON)"
echo "============================================================"

# 1. System Dependencies for Pyenv & Build
echo "=> [1] Installing Linux build dependencies..."
sudo apt-get update -y
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git

# 2. Correct CUDA 12.8 Compiler for Ubuntu 24.04 (Noble)
echo "=> [2] Forcing pure Ubuntu 24.04 CUDA 12.8 Compiler Injection..."
# Purge the incorrect 22.04 keyring to prevent repo crossing
sudo rm -f /etc/apt/sources.list.d/cuda*.list
# Grab the correct Noble Numbat (24.04) keyring
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update -y
sudo apt-get install -y cuda-toolkit-12-8

# Force the shell executing this script to see the new compiler immediately
export CUDA_HOME=/usr/local/cuda-12.8
export PATH=/usr/local/cuda-12.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:${LD_LIBRARY_PATH:-}

echo "   [*] Verifying CUDA Compiler Version:"
nvcc --version

# 3. Pyenv Forge for Exact Version Parity
echo "=> [3] Forging Python $TARGET_PYTHON Environment..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

if ! command -v pyenv >/dev/null 2>&1; then
    echo "   [*] Installing pyenv..."
    curl https://pyenv.run | bash
fi

eval "$(pyenv init -)"

if ! pyenv versions --bare | grep -q "^${TARGET_PYTHON}$"; then
    echo "   [*] Compiling Python $TARGET_PYTHON from source (takes ~3-5 mins)..."
    export PYTHON_CONFIGURE_OPTS="--enable-shared"
    # -v keeps Pyenv from running silent
    pyenv install -v --skip-existing "$TARGET_PYTHON"
fi

PYTHON_EXE="$PYENV_ROOT/versions/$TARGET_PYTHON/bin/python"

# 4. Workspace & Environment Isolation
echo "=> [4] Forging pristine workspace and virtual environment..."
mkdir -p "$REPO_DIR" && cd "$REPO_DIR"
rm -rf "$VENV_DIR"
"$PYTHON_EXE" -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

# 5. Core Dependencies & CUDA PyTorch
echo "=> [5] Upgrading build toolchain & Installing CUDA PyTorch..."
pip install -v --upgrade pip cmake ninja wheel setuptools packaging
# Pulling cu128 to match your Bare Metal hardware constraints
pip install -v torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --index-url https://download.pytorch.org/whl/cu128
pip install -v "transformers<5"
pip install -v "ray[default]==2.54.0" 

# 6. Public HTTPS Cloning (Base vLLM only)
echo "=> [6] Cloning optimized repository..."
rm -rf vllm
git clone -b fix/bakari-apple-silicon-ray-sync https://github.com/ProtoAI-Bakari/vllm.git

# 7. Build vLLM for CUDA
echo "=> [7] Compiling vLLM with CUDA backend (THIS WILL SPIT TEXT - LET IT COOK)..."
cd vllm
pip install -v -e .

# 8. Linux/Ray Specific Env Fixes
echo "=> [8] Applying Ray Environment bypasses..."
mkdir -p "$HOME/.config/vllm"
echo '["LD_LIBRARY_PATH"]' > "$HOME/.config/vllm/ray_non_carry_over_env_vars.json"

echo "============================================================"
echo "✅ NOBLE DEPLOYMENT SUCCESSFUL (Python $(python -V))"
echo "Activate environment: source $VENV_DIR/bin/activate"
echo "============================================================"
