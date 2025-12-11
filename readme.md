# YGGDRASIL 知识树 🌳

欢迎来到 YGGDRASIL 知识仓库！这是一个系统化组织的个人知识管理系统，涵盖人工智能、量化交易、数学基础等多个领域。

## 📖 目录结构

```
YGGDRASIL/
├── ai-ml/               # 🤖 人工智能与机器学习
├── finance-quant/       # 💹 金融量化
├── math-foundation/     # 📐 数学基础
├── methodology/         # 🔧 方法论
├── snippets-library/    # 📚 代码片段库
├── _templates/          # 📋 文档模板
├── _drafts/             # ✏️ 草稿区
└── _archive/            # 📦 归档内容
```

## 🎯 主要领域

### 🤖 [AI & Machine Learning](./ai-ml/)
人工智能与机器学习核心技术
- [NLP](./ai-ml/nlp/) - 自然语言处理
- [Deep Learning](./ai-ml/deep-learning/) - 深度学习基础
- [Computer Vision](./ai-ml/computer-vision/) - 计算机视觉

### 💹 [金融量化](./finance-quant/)
量化交易完整知识体系
- [技术指标](./finance-quant/indicators/) - 动量、波动率、成交量指标
- [交易策略](./finance-quant/strategies/) - 策略开发与回测
- [量化模型](./finance-quant/models/) - 定价、风险、优化模型
- [ML应用](./finance-quant/ml-applications/) - 机器学习在量化中的应用
- [风险管理](./finance-quant/risk-management/) - 风险度量与控制
- [数据工程](./finance-quant/data-engineering/) - 数据管道与基础设施

### 📐 [数学基础](./math-foundation/)
理论支撑与数学工具
- [统计学](./math-foundation/statistics/) - 统计与概率论
- [优化理论](./math-foundation/optimization/) - 最优化方法
- [随机过程](./math-foundation/stochastic-processes/) - 随机微分方程

### 🔧 [方法论](./methodology/)
跨领域方法论与元知识
- [知识工程](./methodology/knowledge-eng/) - 知识组织与管理
- [研究方法](./methodology/research-methods/) - 学术研究方法论

### 📚 [代码片段库](./snippets-library/)
常用代码片段和工具函数

## 🚀 快速开始

### 浏览内容
1. 从上面的目录结构进入感兴趣的领域
2. 每个目录都有 `index.md` 提供完整导航
3. 使用 VS Code 或 Obsidian 获得最佳体验

### 搜索内容
- **全局搜索**：`Ctrl+Shift+F` (VS Code) 或 `Ctrl+Shift+F` (Obsidian)
- **按标签**：查看文档的 YAML frontmatter 中的 tags
- **按分类**：通过 categories 字段定位内容

### 创建新文档
1. 使用 `_templates/document-template.md` 作为起点
2. 确保填写完整的 YAML frontmatter
3. 遵循 kebab-case 命名规范
4. 放置在合适的目录下

## 📝 组织原则

本仓库遵循严格的知识工程标准：

### 结构规范
- ✅ **扁平化**：优先 2 层结构，最多 3 层
- ✅ **语义化**：使用 kebab-case，目录名自解释
- ✅ **索引完整**：每个目录都有 index.md
- ✅ **元数据标准**：统一的 YAML frontmatter

### 命名规范
- **目录名**：kebab-case，1-3 个英文单词
- **文件名**：kebab-case，与 slug 字段一致
- **slug**：必须与文件名（去除.md）完全一致

### 元数据标准
**必填字段**：
- `title` - 人类可读的标题
- `slug` - URL 友好的标识符
- `description` - 简短描述（1-2 句话）
- `date` - 创建日期 (YYYY-MM-DD)
- `categories` - 分类（对应目录路径）
- `tags` - 标签（跨类别关键词）

**可选字段**：
- `author` - 作者
- `updated` - 更新日期
- `status` - 状态 (draft/published/archived)
- `version` - 版本号

详见 [finance-quant/metadata-standards.md](./finance-quant/metadata-standards.md)

## 🛠️ 工具与集成

### Foam（已集成）
本仓库保留 Foam 功能，支持：
- 📥 [inbox.md](./inbox.md) - 快速笔记
- ✅ [todo.md](./todo.md) - 任务管理
- 🔗 双向链接
- 📊 知识图谱可视化

### 推荐工具
- **VS Code** + Foam 插件
- **Obsidian** - 本地知识管理
- **Git** - 版本控制

## 🎨 知识地图

```mermaid
graph TD
    A[YGGDRASIL 知识树] --> B[AI & ML]
    A --> C[金融量化]
    A --> D[数学基础]
    A --> E[方法论]
    
    B --> B1[NLP]
    B --> B2[深度学习]
    B --> B3[计算机视觉]
    
    C --> C1[技术指标]
    C --> C2[交易策略]
    C --> C3[量化模型]
    C --> C4[ML应用]
    
    D --> D1[统计学]
    D --> D2[优化理论]
    D --> D3[随机过程]
    
    E --> E1[知识工程]
    E --> E2[研究方法]
```

## 🔗 跨领域关系

- **AI → 量化**：ML技术应用于交易策略
- **数学 → AI**：优化算法支撑模型训练
- **数学 → 量化**：随机过程用于资产定价
- **方法论 → 全部**：知识管理贯穿始终

## 🏗️ 维护

本仓库由 **Architech** 智能体辅助维护，确保：
- ✅ 结构合理性
- ✅ 命名一致性
- ✅ 元数据完整性
- ✅ 索引准确性

## 📜 版本历史

- **v1.0** (2024-12-11) - 初始化仓库结构
  - 创建主要领域目录
  - 建立元数据标准
  - 生成完整索引

## 📄 许可

个人知识库，保留所有权利。

---

**开始探索** → 选择一个感兴趣的领域目录 → 查看 index.md 获取导航

*最后更新: 2024-12-11 | 维护者: Architech*
