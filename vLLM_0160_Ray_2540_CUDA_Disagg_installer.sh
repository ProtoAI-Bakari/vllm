#!/bin/bash
# ==============================================================================
# vLLM CUDA DISTRIBUTED RAY ZERO-CLICK INSTALLER (DISAGG PREFILL)
# Target: Ubuntu/Linux CUDA Bare-Metal Node (Dual 3090)
# ==============================================================================
set -euo pipefail

ENV_NAME="vLLM_0160_Ray_02540_CUDA_Disagg"
VENV_DIR="$HOME/.venvs/$ENV_NAME"
WHEEL_DIR="/repo/models/RUN/WHEELS"
TARGET_PYTHON="3.12"

echo "============================================================"
echo "🚀 INITIATING ATOMIC CUDA DISAGG DEPLOYMENT"
echo "============================================================"

# 1. Workspace & UV Toolchain
echo "=> [1] Forging pristine workspace and UV toolchain..."
export UV_NO_PROGRESS=1

mkdir -p "$HOME/.venvs"

if ! command -v uv >/dev/null 2>&1; then
    echo "   📥 Installing astral/uv runtime..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.cargo/env"
else
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# 2. Virtual Environment
echo "=> [2] Forging Python $TARGET_PYTHON Environment in ~/.venvs/..."
rm -rf "$VENV_DIR"
uv venv "$VENV_DIR" --python "$TARGET_PYTHON" --seed
PY_BIN="$VENV_DIR/bin/python3"
PIP_BIN="$VENV_DIR/bin/pip"

# 3. Core PyTorch Bounds
echo "=> [3] Installing PyTorch Ecosystem (v2.10.0+cu128)..."
uv pip install "torch==2.10.0" "torchaudio==2.10.0" "torchvision==0.25.0" --python "$PY_BIN" --index-url https://download.pytorch.org/whl/cu128 --quiet

# 4. Zero-Compile Local Wheel Installation
echo "=> [4] Injecting Pre-compiled vLLM and Mooncake Wheels from $WHEEL_DIR..."
# We use standard pip here to ensure proper wheel metadata handling for complex C++ extensions
"$PIP_BIN" install --no-index --find-links="$WHEEL_DIR" vllm mooncake-transfer-engine

# 5. Ecosystem & Ray
echo "=> [5] Installing Ray, Transformers & Ecosystem..."
uv pip install "ray[default]==2.54.0" "transformers>=4.56.0,<5.0.0" pyarrow accelerate outlines --python "$PY_BIN" --quiet

# 6. Verification
echo "=> [6] Executing Final System Verification..."
"$PY_BIN" -c "import torch, vllm, ray, mooncake; print(f'\n   [VERIFIED] Torch: {torch.__version__} | vLLM: {vllm.__version__} | Ray: {ray.__version__} | Mooncake: Active')"

echo "============================================================"
echo "✅ CUDA DISAGG DEPLOYMENT SUCCESSFUL"
echo "Activate environment: source $VENV_DIR/bin/activate"
echo "============================================================"
