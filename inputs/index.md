---
title: "Inputs — 待分类与待处理项"
slug: "inputs"
description: "存放临时输入、待分类或待处理文档的收集区，作为进入正式知识目录的临时缓冲。"
author: "System"
date: 2025-12-18
categories:
  - inputs
tags:
  - inputs
  - inbox
  - staging
is_index: true
---

# Inputs — 待分类与待处理项

本目录用于收集尚未确定最终归属的文档或临时笔记（例如从其他工具导入的笔记、尚需补全元数据的草稿或收件箱中待处理的条目）。将文件放入此目录可以方便后续归类、补全 YAML 元数据并移动到正式目录。

## 📚 子目录

- `_archive/` - 存放已归档但保留的旧输入（可选）
- `_templates/` - 输入相关的快速模板（可选）

## 📄 文档列表（示例）

- [[./example-input.md|示例输入文档]] - 简短描述：一个示例占位文件，用于说明如何使用 inputs 目录

## 使用建议

1. 将临时笔记或导入的文档放入此目录，文件名使用 kebab-case（例如：`meeting-notes-2025-12-18.md`）。
2. 为每个文档补全 YAML frontmatter（必填字段：title, slug, description, date, categories, tags）。
3. 经过整理后，把文件移动到对应的正式目录（例如 `ai-ml/`, `finance-quant/` 等）。
4. 定期清理 `inputs/`，避免堆积过多未分类文件（建议每月审查）。

---
*最后更新: 2025-12-18 | 维护者: Architect*
