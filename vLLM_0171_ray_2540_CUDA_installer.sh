#!/bin/bash
# ==============================================================================
# vLLM CUDA DISTRIBUTED RAY ZERO-CLICK INSTALLER
# Target: Ubuntu/Linux CUDA Bare-Metal Node
# ==============================================================================
set -euo pipefail

ENV_NAME=".venv-vLLM_0170_Ray_02540_CUDA"
VENV_DIR="$HOME/$ENV_NAME"
WHEEL_DIR="$HOME/DEV/WHEELS"
TARGET_PYTHON="3.12"

echo "============================================================"
echo "🚀 INITIATING ATOMIC CUDA DEPLOYMENT (vLLM 0.17.1 | Ray 2.54.0)"
echo "============================================================"

# 1. Workspace & UV Toolchain
echo "=> [1] Forging pristine workspace and UV toolchain..."
export UV_NO_PROGRESS=1
export UV_HTTP_TIMEOUT=600

rm -rf "$VENV_DIR" ~/.cache/uv
mkdir -p "$WHEEL_DIR"

if ! command -v uv >/dev/null 2>&1; then
    echo "   📥 Installing astral/uv runtime..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.cargo/env"
else
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# 2. Virtual Environment
echo "=> [2] Forging Python $TARGET_PYTHON Environment..."
uv venv "$VENV_DIR" --python "$TARGET_PYTHON" --seed
PY_BIN="$VENV_DIR/bin/python3"

# 3. Core PyTorch Bounds
echo "=> [3] Installing PyTorch Ecosystem (v2.10.0+cu128)..."
uv pip install "torch==2.10.0" "torchaudio==2.10.0" "torchvision==0.25.0" --python "$PY_BIN" --index-url https://download.pytorch.org/whl/cu128 --quiet

# 4. Flash Attention (Pre-compiled Local)
echo "=> [4] Injecting Pre-compiled Flash Attention (v2.8.3)..."
uv pip install flash-attn==2.8.3 --find-links "$WHEEL_DIR" --python "$PY_BIN" --quiet

# 5. Official vLLM
echo "=> [5] Installing Official vLLM (v0.17.1)..."
uv pip install vllm==0.17.1 --python "$PY_BIN" --quiet

# 6. Ecosystem & Ray
echo "=> [6] Installing Ray, Transformers & Ecosystem..."
uv pip install "ray[default]==2.54.0" "transformers>=4.56.0,<5.0.0" pyarrow accelerate outlines --python "$PY_BIN" --quiet

# 7. Verification
echo "=> [7] Executing Final System Verification..."
"$PY_BIN" -c "import torch, vllm, flash_attn, transformers, ray; print(f'\n   [VERIFIED] Torch: {torch.__version__} | vLLM: {vllm.__version__} | FA: {flash_attn.__version__} | Trans: {transformers.__version__} | Ray: {ray.__version__}')"

echo "============================================================"
echo "✅ CUDA DEPLOYMENT SUCCESSFUL"
echo "Activate environment: source $VENV_DIR/bin/activate"
echo "============================================================"
