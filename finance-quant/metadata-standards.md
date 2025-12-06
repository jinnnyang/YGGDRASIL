# 金融量化知识元数据标准

## 目的
为确保Yggdrasil知识仓库中金融量化领域的内容具备一致的元数据，便于检索、筛选、关联和自动化处理，制定本元数据标准。

## 适用范围
适用于所有位于 `finance-quant/` 目录及其子目录下的笔记、代码、数据文档、研究报告等知识资产。

## 元数据字段定义

### 1. 核心元数据（每篇笔记必须包含）
以下字段应置于笔记的Frontmatter（YAML格式）中。

| 字段名 | 类型 | 描述 | 示例 |
|--------|------|------|------|
| `title` | 字符串 | 笔记的标题 | "Black‑Scholes模型推导" |
| `id` | 字符串 | 全局唯一标识符（建议使用UUID或分类编码） | "FQ‑QM‑OPT‑001" |
| `created` | 日期（ISO 8601） | 创建日期 | "2025‑12‑06T11:30:00Z" |
| `updated` | 日期（ISO 8601） | 最后更新日期 | "2025‑12‑06T14:20:00Z" |
| `author` | 字符串或数组 | 作者/贡献者 | ["Alice", "Bob"] |
| `status` | 枚举 | 内容状态：draft, review, published, archived | "published" |
| `version` | 字符串 | 版本号（语义化版本） | "1.0.0" |

### 2. 分类元数据（用于自动归类）
| 字段名 | 类型 | 描述 | 示例 |
|--------|------|------|------|
| `category` | 字符串 | 一级分类（见分类体系） | "量化模型与方法" |
| `subcategory` | 字符串或数组 | 二级分类 | ["定价模型", "期权定价"] |
| `tags` | 数组 | 自由标签，用于细粒度主题标记 | ["Black-Scholes", "偏微分方程", "期权"] |
| `classification_code` | 字符串 | 分类编码（如FQ‑QM‑OPT） | "FQ‑QM‑OPT" |

### 3. 内容属性（描述内容特性）
| 字段名 | 类型 | 描述 | 示例 |
|--------|------|------|------|
| `difficulty` | 枚举 | 难度级别：beginner, intermediate, advanced, expert | "intermediate" |
| `prerequisites` | 数组 | 前置知识（笔记ID或标题） | ["FQ‑QM‑STOCH‑001", "随机过程基础"] |
| `related` | 数组 | 相关笔记ID | ["FQ‑QM‑OPT‑002", "FQ‑QM‑OPT‑003"] |
| `bibliography` | 数组 | 参考文献（DOI、URL或引用字符串） | ["https://doi.org/10.1080/14697688.1973.10489165"] |
| `language` | 字符串 | 内容主要语言（ISO 639‑1） | "zh"（中文）或 "en"（英文） |

### 4. 技术元数据（适用于代码、数据文档）
| 字段名 | 类型 | 描述 | 示例 |
|--------|------|------|------|
| `tech_stack` | 数组 | 使用的技术栈 | ["Python", "NumPy", "QuantLib"] |
| `data_source` | 字符串 | 数据来源 | "WRDS", "Yahoo Finance" |
| `environment` | 字符串 | 运行环境要求 | "Python 3.9+, Jupyter Notebook" |
| `license` | 字符串 | 许可协议 | "MIT", "CC‑BY‑4.0" |

### 5. 业务/领域元数据（适用于策略、报告）
| 字段名 | 类型 | 描述 | 示例 |
|--------|------|------|------|
| `asset_class` | 数组 | 适用的资产类别 | ["Equity", "FX"] |
| `timeframe` | 字符串 | 策略/分析的时间框架 | "日内", "长期" |
| `performance_metrics` | 数组 | 涉及的绩效指标 | ["Sharpe Ratio", "Max Drawdown"] |
| `risk_level` | 枚举 | 风险等级：low, medium, high | "medium" |

## Frontmatter 示例

```yaml
---
title: "Black‑Scholes模型推导与Python实现"
id: "FQ‑QM‑OPT‑001"
created: 2025‑12‑06T11:30:00Z
updated: 2025‑12‑06T14:20:00Z
author: ["张三", "李四"]
status: published
version: "1.0.0"
category: "量化模型与方法"
subcategory: ["定价模型", "期权定价"]
tags: ["Black-Scholes", "偏微分方程", "期权", "Python"]
classification_code: "FQ‑QM‑OPT"
difficulty: intermediate
prerequisites: ["随机过程基础", "Itô引理"]
related: ["FQ‑QM‑OPT‑002", "FQ‑QM‑OPT‑003"]
bibliography: ["Black, F., & Scholes, M. (1973). The pricing of options and corporate liabilities. Journal of Political Economy, 81(3), 637‑654."]
language: "zh"
tech_stack: ["Python", "NumPy", "SciPy"]
data_source: "模拟数据"
environment: "Python 3.9+, Jupyter Notebook"
license: "MIT"
asset_class: ["Equity"]
timeframe: "日内"
performance_metrics: ["Delta", "Gamma"]
risk_level: low
---
```

## 标签（Tags）规范

### 通用标签分类
- **模型类**：`Black-Scholes`, `Heston`, `Vasicek`, `GARCH`
- **方法类**：`蒙特卡洛`, `有限差分`, `机器学习`, `时间序列`
- **资产类**：`股票`, `债券`, `期权`, `期货`
- **风险类**：`市场风险`, `信用风险`, `流动性风险`
- **工具类**：`Python`, `R`, `QuantLib`, `回测`

### 标签命名规则
- 使用英文小写，多个单词用连字符连接（如 `black‑scholes`）。
- 避免特殊字符和空格。
- 优先使用已有标签，保持一致性。

## 分类编码（Classification Code）规则
编码格式：`FQ‑{一级代码}‑{二级代码}‑{三级代码}`

- 一级代码：2‑3个大写字母，对应一级分类（如 `MA` 代表市场与资产）
- 二级代码：2‑3个大写字母，对应二级分类（如 `EQ` 代表股票）
- 三级代码：2‑4个大写字母，对应三级主题（如 `ORDERBOOK` 代表订单簿）

示例：
- `FQ‑MA‑EQ‑ORDERBOOK`：市场与资产 → 股票 → 订单簿
- `FQ‑QM‑OPT‑BLACKSCHOLES`：量化模型与方法 → 期权定价 → Black‑Scholes

## 元数据校验
建议使用以下工具/脚本进行元数据校验：
- 使用VS Code插件（如Frontmatter Lint）检查必填字段。
- 编写Python脚本批量验证分类编码与标签的合规性。

## 版本历史
| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2025‑12‑06 | 初始版本 |

---
*维护者：Yggdrasil 架构师*
