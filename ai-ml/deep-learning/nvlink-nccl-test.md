---
title: "Ubuntu 20.04 上使用 NVLink 配置 NCCL 并测试 Transformers"
slug: "nvlink-nccl-test"
description: "启用 NVLink、安装 NCCL 并在多卡上测试 Transformers 训练以对比 NCCL 启用/禁用时的性能差异。"
author: "jinnyang"
date: 2023-11-30
categories:
  - ai-ml
  - deep-learning
tags:
  - nvlink
  - nccl
  - distributed-training
  - pytorch
status: published
---

## 实现代码
### 启用NVLink
本文在完成[[Ubuntu2004的3090安装CUDA123以及cuDNN8]]后继续操作
1. **关机**后插上NVLink后启用
   ```bash
   sudo nvidia-smi nvlink -sc 1
   ```
   重启检查连接情况
   ```bash
   nvidia-smi topo --matrix
   ```
   查看NVLink状态（速度）
   ```bash
   nvidia-smi nvlink --status
   ```
2. 下载解压NCCL后安装
   ```bash
   curl -o - https://developer.nvidia.com/downloads/compute/machine-learning/nccl/secure/2.19.3/agnostic/x64/nccl_2.19.3-1+cuda12.3_x86_64.txz | tar -Jxf -
   mv nccl_2.19.3-1+cuda12.3_x86_64/lib/* /usr/local/cuda-12.3/lib64/
   mv nccl_2.19.3-1+cuda12.3_x86_64/include/* /usr/local/cuda-12.3/include/
   ```

### 测试
1. 创建测试环境
   ```bash
   conda create -n NVLinkTest python=3.10
   conda activate NVLinkTest
   conda install -n NVLinkTest pytorch==1.13.1 torchvision==0.14.1 torchaudio==0.13.1 pytorch-cuda=11.7 -c pytorch -c nvidia
   pip install evaluate datasets accelerate git+http://gitcache.nas.internal/github.com/huggingface/transformers
   ```
   注意，目前PyTorch 2的并行化并不适用（总有问题）。
2. 拉取测试代码
   ```bash
   git clone http://gitcache.nas.internal/github.com/huggingface/transformers
   cd transformers
   ```
3. 禁用NCCL，运行测试
   ```bash
   rm -r /tmp/test-clm; NCCL_P2P_DISABLE=1 CUDA_VISIBLE_DEVICES=0,1 \
   python -m torch.distributed.launch --nproc_per_node 2 examples/pytorch/language-modeling/run_clm.py \
   --model_name_or_path gpt2 --dataset_name wikitext --dataset_config_name wikitext-2-raw-v1 \
   --do_train --output_dir /tmp/test-clm --per_device_train_batch_size 4 --max_steps 200
   ```
   输出
   ```
   ***** train metrics *****
   epoch                    =       0.69
   train_loss               =     3.2972
   train_runtime            = 0:01:12.41
   train_samples            =       2318
   train_samples_per_second =     22.094
   train_steps_per_second   =      2.762
   ```
4. 启用NCCL
   ```bash
   rm -r /tmp/test-clm; NCCL_P2P_DISABLE=0 CUDA_VISIBLE_DEVICES=0,1 \
   python -m torch.distributed.launch --nproc_per_node 2 examples/pytorch/language-modeling/run_clm.py \
   --model_name_or_path gpt2 --dataset_name wikitext --dataset_config_name wikitext-2-raw-v1 \
   --do_train --output_dir /tmp/test-clm --per_device_train_batch_size 4 --max_steps 200
   ```
   输出
   ```
   epoch                    =       0.69
   train_loss               =     3.2972
   train_runtime            = 0:01:08.18
   train_samples            =       2318
   train_samples_per_second =     23.466
   train_steps_per_second   =      2.933
   ```
   重复实验，结论成立：NCCL有用，但有限。


[Ubuntu2004的3090安装CUDA123以及cuDNN8]: ../../inputs/notes/Snipptes/Linux/Ubuntu/Ubuntu2004%E7%9A%843090%E5%AE%89%E8%A3%85CUDA123%E4%BB%A5%E5%8F%8AcuDNN8.md "Ubuntu2004的3090安装CUDA123以及cuDNN8"
