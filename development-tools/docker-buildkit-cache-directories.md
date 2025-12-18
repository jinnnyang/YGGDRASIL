# BuildKit缓存挂载：常用缓存目录完整指南

## 概述

Docker BuildKit的缓存挂载功能允许在构建过程中持久化缓存目录，显著提升构建效率。除了Node.js的npm缓存外，BuildKit还支持多种主流编程语言和包管理器的缓存目录。

## 核心概念

### 什么是缓存挂载
缓存挂载是BuildKit提供的一种持久化缓存机制，允许在多次构建之间共享依赖包和编译产物。与传统的Docker层缓存不同，缓存挂载提供更细粒度的缓存控制。

### 工作原理
- 首次构建：下载依赖并存储到缓存目录
- 后续构建：直接使用缓存中的依赖，避免重复下载
- 缓存持久化：即使Docker层被重建，缓存内容仍然保留

## 常用缓存目录详解

### 🦀 Rust/Cargo 缓存

#### 核心缓存目录
```dockerfile
# Cargo包注册表缓存 - 存储从crates.io下载的包
RUN --mount=type=cache,target=/usr/local/cargo/registry

# Git依赖缓存 - 存储通过Git获取的依赖
RUN --mount=type=cache,target=/usr/local/cargo/git/db

# 完整的Cargo缓存目录
RUN --mount=type=cache,target=/root/.cargo
```

#### 实际应用示例
```dockerfile
FROM rust:1.70
WORKDIR /app

# 复制依赖文件
COPY Cargo.toml Cargo.lock ./

# 使用多缓存挂载构建
RUN --mount=type=cache,target=/app/target \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/usr/local/cargo/registry \
    cargo build --release

# 复制源代码
COPY src/ ./src/
RUN cargo build --release
```

### 🐍 Python 缓存

#### pip缓存目录
```dockerfile
# pip默认缓存目录
RUN --mount=type=cache,target=/root/.cache/pip

# 通用Python缓存目录（适用于pip、Pipenv、Poetry）
RUN --mount=type=cache,target=/root/.cache
```

#### 应用示例
```dockerfile
FROM python:3.11-slim
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 使用缓存安装依赖
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# 复制源代码
COPY . .
```

### 🐹 Go 缓存

#### Go模块缓存
```dockerfile
# Go模块和包缓存
RUN --mount=type=cache,target=/go/pkg/mod
```

#### 应用示例
```dockerfile
FROM golang:1.21
WORKDIR /app

# 复制go.mod和go.sum
COPY go.mod go.sum ./

# 使用缓存下载依赖
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# 复制源代码并构建
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    go build -o main .
```

### ☕ Java/Maven 缓存

#### Maven本地仓库
```dockerfile
# Maven本地仓库缓存
RUN --mount=type=cache,target=/root/.m2
```

#### 应用示例
```dockerfile
FROM maven:3.9-eclipse-temurin-17
WORKDIR /app

# 复制pom.xml
COPY pom.xml .

# 使用缓存下载依赖
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline

# 复制源代码并构建
COPY src/ ./src/
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests
```

### 📦 其他包管理器缓存

#### Ruby/Bundler
```dockerfile
RUN --mount=type=cache,target=/root/.gem
```

#### .NET/NuGet
```dockerfile
RUN --mount=type=cache,target=/root/.nuget/packages
```

#### PHP/Composer
```dockerfile
RUN --mount=type=cache,target=/tmp/cache
```

#### APT包管理器（需要特殊处理）
```dockerfile
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get --no-install-recommends install -y gcc
```

## 高级使用技巧

### 1. 并发安全配置

对于需要独占访问的缓存，使用`sharing=locked`参数：

```dockerfile
# APT包管理器需要锁定访问
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get install -y package-name
```

### 2. 多阶段构建中的缓存策略

```dockerfile
# 构建阶段 - 使用缓存
FROM rust:1.70 AS builder
WORKDIR /app
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release

# 运行阶段 - 最小化镜像
FROM debian:bookworm-slim
COPY --from=builder /app/target/release/myapp /usr/local/bin/
CMD ["myapp"]
```

### 3. 缓存管理命令

```bash
# 查看缓存使用情况
docker buildx du

# 清理缓存挂载
docker builder prune --filter type=exec.cachemount

# 清理所有未使用的构建缓存
docker builder prune
```

## 最佳实践

### 1. 缓存目录选择原则
- 使用包管理器的默认缓存目录
- 确保缓存目录包含所有必要的依赖文件
- 避免缓存临时文件和编译产物

### 2. 性能优化建议
- 将依赖文件复制放在源代码复制之前
- 使用多阶段构建分离构建和运行环境
- 合理设置缓存挂载的权限

### 3. CI/CD集成
```yaml
# GitHub Actions示例
- name: Build with BuildKit cache
  uses: docker/build-push-action@v5
  with:
    context: .
    cache-from: type=registry,ref=myapp:buildcache
    cache-to: type=registry,ref=myapp:buildcache,mode=max
```

## 常见问题解决

### 1. 缓存未生效
- 检查BuildKit是否启用：`DOCKER_BUILDKIT=1`
- 确认缓存目录路径正确
- 验证Docker版本支持缓存挂载

### 2. 权限问题
- 确保容器用户有缓存目录的读写权限
- 对于系统级缓存目录，可能需要使用`sudo`

### 3. 缓存污染
- 定期清理缓存：`docker builder prune`
- 在依赖变更时手动清理相关缓存

## 性能对比

| 方案 | 首次构建 | 后续构建 | 缓存持久性 |
|------|----------|----------|------------|
| 无缓存 | 慢 | 慢 | 无 |
| 层缓存 | 中等 | 快 | 高 |
| 缓存挂载 | 中等 | 很快 | 中等 |
| 外部缓存 | 中等 | 很快 | 很高 |

## 总结

BuildKit缓存挂载是提升Docker构建效率的重要工具。通过合理配置各种编程语言的缓存目录，可以显著减少构建时间，特别是在依赖频繁变更的开发环境中。正确使用缓存挂载需要理解各语言包管理器的工作原理，并结合项目的具体需求进行配置。

## 参考资源

- [Docker BuildKit官方文档](https://docs.docker.com/build/cache/)
- [BuildKit缓存挂载参考](https://docs.docker.com/reference/dockerfile/#run---mounttypecache)
- [各语言包管理器官方文档]
