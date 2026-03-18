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
    def get_device_name(cls, device_id: int = 0) -> str:
        return "vulkan"

    @classmethod
    def is_async_output_supported(cls, enforce_eager: bool) -> bool:
        return False

    @classmethod
    def check_and_update_config(cls, vllm_config) -> None:
        pass

    @classmethod
    def is_pin_memory_available(cls) -> bool:
        return False

    @classmethod
    def get_default_worker_cls_name(cls) -> str:
        return "vllm.v1.worker.cpu_worker.CPUWorker"

    @classmethod
    def get_default_model_runner_cls_name(cls) -> str:
        return "vllm.v1.worker.cpu_model_runner.CPUModelRunner"
