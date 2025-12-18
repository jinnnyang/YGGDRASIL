---
title: "使用 Docker + wget 爬取整个站点目录"
slug: "docker-wget-site-mirror"
description: "演示如何在 Docker 容器中使用 wget 递归爬取并镜像整个网站到本地目录。"
author: "Unknown"
date: 2023-11-22
categories:
  - development-tools
tags:
  - docker
  - wget
  - site-mirror
  - scraping
status: published
---

## 需求概述
从网站抓取整个站点。

## 实现代码
```
docker container run --rm -v ./download:/download -w /download netdata/wget:latest wget -c -r -np -k -L -p https://www.sbert.net/
