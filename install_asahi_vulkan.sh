#!/bin/bash
# vLLM Asahi Linux Vulkan Enabler
# Automates the platform registration and CPU/Vulkan worker bypasses.

set -e

echo "🚀 Injecting Asahi Vulkan Architecture into vLLM..."

# 1. Register the Vulkan Enum
if ! grep -q "VULKAN = enum.auto()" vllm/platforms/interface.py; then
    sed -i '/UNSPECIFIED = enum.auto()/i \    VULKAN = enum.auto()' vllm/platforms/interface.py
    echo "✅ Registered VULKAN in PlatformEnum"
fi

# 2. Create the Vulkan Platform Class
cat << 'PLATFORM' > vllm/platforms/vulkan.py
import os
from typing import Optional
import torch
from vllm.platforms.interface import Platform, PlatformEnum

class VulkanPlatform(Platform):
    _enum = PlatformEnum.VULKAN
    device_name: str = "vulkan"
    device_type: str = "vulkan"
    dispatch_key: str = "Vulkan"

    @classmethod
    def get_device_name(cls, device_id: int = 0) -> str: return "vulkan"
    @classmethod
    def is_async_output_supported(cls, enforce_eager: bool) -> bool: return False
    @classmethod
    def check_and_update_config(cls, vllm_config) -> None: pass
    @classmethod
    def is_pin_memory_available(cls) -> bool: return False
    @classmethod
    def get_default_worker_cls_name(cls) -> str: return "vllm.v1.worker.cpu_worker.CPUWorker"
    @classmethod
    def get_default_model_runner_cls_name(cls) -> str: return "vllm.v1.worker.cpu_model_runner.CPUModelRunner"
    def is_vulkan(self) -> bool: return True
PLATFORM
echo "✅ Created vllm/platforms/vulkan.py"

# 3. Add Vulkan to the Platform Router
if ! grep -q "vulkan_platform_plugin" vllm/platforms/__init__.py; then
    sed -i '/from typing import TYPE_CHECKING/a \from .vulkan import VulkanPlatform' vllm/platforms/__init__.py
    sed -i '/def xpu_platform_plugin() -> str | None:/i \def vulkan_platform_plugin() -> str | None:\n    is_vulkan = False\n    try:\n        import torch\n        if hasattr(torch, "is_vulkan_available") and torch.is_vulkan_available():\n            is_vulkan = True\n    except Exception:\n        pass\n    return "vllm.platforms.vulkan.VulkanPlatform" if is_vulkan else None\n' vllm/platforms/__init__.py
    sed -i '/"xpu": xpu_platform_plugin,/a \    "vulkan": vulkan_platform_plugin,' vllm/platforms/__init__.py
    echo "✅ Registered Vulkan in __init__.py router"
fi

# 4. Inject the Worker Interceptor
if ! grep -q "THE ASAHI INTERCEPTOR" vllm/v1/worker/worker_base.py; then
    sed -i '/parallel_config = vllm_config.parallel_config/a \        # 🔥 THE ASAHI INTERCEPTOR 🔥\n        if parallel_config.worker_cls == "auto":\n            parallel_config.worker_cls = "vllm.v1.worker.cpu_worker.CPUWorker"' vllm/v1/worker/worker_base.py
    echo "✅ Injected 'auto' worker interceptor"
fi

# 5. Bypass tcmalloc check in CPU Worker
if ! grep -q "THE ASAHI BYPASS" vllm/v1/worker/cpu_worker.py; then
    sed -i '/def check_preloaded_libs(lib_name: str):/a \            return  # 🔥 THE ASAHI BYPASS: Ignore missing C++ libraries 🔥' vllm/v1/worker/cpu_worker.py
    echo "✅ Bypassed tcmalloc requirements"
fi

echo "🔥 Asahi Vulkan architecture injected! Run 'uv pip install -e .' to build. 🔥"
