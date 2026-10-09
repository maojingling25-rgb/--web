# 上线部署清单

本项目由 GitHub Pages、Supabase 和 GitHub Actions 组成：

- GitHub Pages：公开首页、文章页和管理员审核页。
- Supabase：文章、来源、审核记录、订阅邮箱和 Magic Link 登录。
- GitHub Actions：每天北京时间 08:00 和 20:00 采集公开来源并生成待审核草稿。

## 1. Supabase

1. 创建项目，Demo 阶段使用 Free 计划。
2. Region 选择美国东部即可。
3. 在 SQL Editor 执行：

```text
supabase/schema.sql
supabase/demo_seed.sql
```

4. 在 Authentication 中启用 Email 登录 / Magic Link。
5. 在 URL Configuration 中加入：

```text
https://<github用户名>.github.io/<仓库名>/
https://<github用户名>.github.io/<仓库名>/admin.html
http://localhost:4173/
http://localhost:4173/admin.html
```

管理员邮箱固定为 `maojingling25@gmail.com`。

## 2. GitHub Actions Secrets

在仓库的 `Settings → Secrets and variables → Actions` 中添加以下 Secrets：

```text
SUPABASE_URL
SUPABASE_SECRET_KEY
OPENAI_API_KEY
```

其中：

- `SUPABASE_URL`：`https://...supabase.co`
- `SUPABASE_SECRET_KEY`：Supabase API 页面的 `sb_secret_...`
- `OPENAI_API_KEY`：现有 OpenAI API Key

不要把上述 Secret 写入仓库文件。尤其不要把 `SUPABASE_SECRET_KEY` 或 `OPENAI_API_KEY`
放到 `public-config.js`、GitHub Variables、文章内容或聊天记录中。

如果使用 MiraclePlus 代理平台，`OPENAI_API_KEY` 填代理平台生成的 Key，不是 OpenAI
官方 Key。再在 GitHub Actions Variables 中添加：

```text
OPENAI_BASE_URL=https://openai-proxy.miracleplus.com/v1
OPENAI_MODEL=glm-5.3
OPENAI_REQUEST_TIMEOUT_MS=600000
```

当前流水线使用 OpenAI Responses API；模型需要支持 `openai-response`。代理平台的
`/keys` 是密钥管理页面，不是 API Base URL。

## 3. GitHub Actions Variables

添加以下 Variables：

```text
PUBLIC_SUPABASE_URL
PUBLIC_SUPABASE_PUBLISHABLE_KEY
OPENAI_BASE_URL
OPENAI_MODEL
OPENAI_REQUEST_TIMEOUT_MS
LOOKBACK_HOURS
DAILY_ARTICLE_LIMIT
PUBLIC_TEXT_LIMIT
```

推荐值：

```text
PUBLIC_SUPABASE_URL=https://awsewasitgfsjymnekyl.supabase.co
PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
OPENAI_BASE_URL=https://openai-proxy.miracleplus.com/v1
OPENAI_MODEL=glm-5.3
OPENAI_REQUEST_TIMEOUT_MS=600000
LOOKBACK_HOURS=36
DAILY_ARTICLE_LIMIT=10
PUBLIC_TEXT_LIMIT=18000
```

Publishable key 可以出现在静态网站中。它不等于 Secret key，数据库安全依赖
Supabase RLS 和管理员 JWT 校验。

## 4. 首次推送

在项目目录执行：

```bash
git init
git branch -M main
git add .
git commit -m "Initial demo deployment"
git remote add origin https://github.com/<github用户名>/<仓库名>.git
git push -u origin main
```

仓库的 `Settings → Pages → Source` 选择 `GitHub Actions`。之后：

- `pages.yml` 在推送到 `main` 后部署静态网站。
- `content-pipeline.yml` 每天 08:00 和 20:00（北京时间）运行。
- 内容流水线单次任务最长运行 60 分钟；代理模型生成较慢时，GitHub Actions 不会在 20 分钟处提前取消。
- 单篇 AI 生成请求默认最多等待 10 分钟；失败会跳过该篇并继续处理同一来源的其他节目。
- 也可以在 `Actions` 页面手动运行 `Update podcast intelligence`。

## 5. 人工审核流程

1. 打开 `/admin.html`。
2. 使用 `maojingling25@gmail.com` 接收 Magic Link。
3. 检查标题、摘要、核心嘉宾、7-10 条结构化洞察、编辑解读和原始播放链接。
4. 点击“通过并发布”后，文章才会出现在公开首页。

## 6. 后续改动

页面、脚本和配置修改后：

```bash
npm run check
git add .
git commit -m "Describe the change"
git push origin main
```

代码改动会自动进入下一次 Pages 部署和下一次定时任务。数据库 schema 改动不会自动
执行，必须先在 Supabase SQL Editor 执行对应 SQL，再推送代码。

已发布文章优先通过 `/admin.html` 修改。频道接入或抓取规则则修改
`config/sources.json` 和 `scripts/run-pipeline.mjs`。
