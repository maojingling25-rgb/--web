# 听见全球 AI 前沿

一个面向 AI 播客与访谈的自动采集、AI 解读和人工审核发布站点。

## Demo 形态

- 公开前台：`index.html`，展示最新解读、搜索、主题筛选和原始链接。
- 审核后台：`admin.html`，管理员邮箱 Magic Link 登录后编辑、发布、拒绝、下线文章。
- 数据库：Supabase PostgreSQL，保存频道、来源条目、生成后的解读和审核记录。
- 后台任务：GitHub Actions 每天北京时间 08:00 和 20:00 自动运行。
- AI：OpenAI API。完整公开正文或字幕只在生成草稿时临时读取，不长期保存。

## 本地预览

本地预览不需要 Supabase。页面会先显示内置样例内容。

```bash
python3 -m http.server 4173
```

然后打开：

- 公开前台：http://localhost:4173/index.html
- 审核后台：http://localhost:4173/admin.html

后台必须连接 Supabase 后才能登录和审核。

## 创建 Supabase 项目

1. 打开 Supabase，新建项目。
2. Region 选择美国东部，Demo 阶段使用免费套餐即可。
3. 进入 SQL Editor，先执行 `supabase/schema.sql`。
4. 如果要快速验证前台读取，继续执行 `supabase/demo_seed.sql`。
5. 进入 Authentication，启用 Email OTP / Magic Link。
6. 进入 Authentication 的 URL Configuration，添加你的 GitHub Pages 地址，之后再添加 `/admin.html` 地址。

管理员邮箱固定为：`maojingling25@gmail.com`。

## Supabase 需要配置的值

进入 Supabase 项目设置，找到 API 页面。当前代码支持新版密钥命名：

- Project URL：用于 `SUPABASE_URL` 和 `PUBLIC_SUPABASE_URL`
- Publishable key：用于 `PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- Secret key：只用于 `SUPABASE_SECRET_KEY`

Secret key 只能放 GitHub Secrets，不能写进前端文件、网页代码或聊天记录。旧版 `anon` 和
`service_role` 命名仍然兼容，但新项目优先使用上面的变量名。

## 创建 GitHub 仓库并发布

1. 创建一个公开 GitHub 仓库。
2. 把本项目推送到仓库默认分支。
3. 在 GitHub 仓库进入 Settings → Pages。
4. Source 选择 GitHub Actions。
5. 进入 Settings → Secrets and variables → Actions。

添加 Secrets：

```text
SUPABASE_URL
SUPABASE_SECRET_KEY
OPENAI_API_KEY
```

添加 Variables：

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

当前代理平台配置：

```text
OPENAI_BASE_URL=https://openai-proxy.miracleplus.com/v1
OPENAI_MODEL=glm-5.3
OPENAI_REQUEST_TIMEOUT_MS=600000
```

`OPENAI_BASE_URL` 是代理的接口地址，不是 `/keys` 管理页面。`glm-5.3` 已通过
Responses API 测试。若改用其他模型，必须确认该模型支持 `openai-response`。
`OPENAI_REQUEST_TIMEOUT_MS` 是单篇 AI 生成请求的超时时间，默认 10 分钟。

如果 GitHub 仓库使用项目 Pages 地址，Supabase Authentication → URL Configuration
至少加入以下地址（把占位符替换成真实仓库信息）：

```text
https://<github用户名>.github.io/<仓库名>/
https://<github用户名>.github.io/<仓库名>/admin.html
http://localhost:4173/
http://localhost:4173/admin.html
```

GitHub Pages 的 Source 选择 `GitHub Actions`。首次部署前，先在 Supabase SQL Editor
依次执行 `supabase/schema.sql` 和 `supabase/demo_seed.sql`。

## 自动更新规则

- 每天北京时间 08:00 和 20:00 运行。
- 每天最多生成 10 条草稿。
- GitHub Actions 单次任务最长运行 60 分钟，以适配代理模型较慢时的生成耗时。
- 单篇生成失败会记录为 `item_failed`，不会跳过同一来源里的其他节目。
- 只处理 `config/sources.json` 中 `enabled = true` 且存在 `feed_url` 的来源。
- 新内容先进入 `draft`，公开前台只读取 `published`。
- 生成内容必须包含：摘要、嘉宾介绍、重要观点、编辑解读、原始链接。
- `重要观点`同时保存为 `insights` JSON 数组，每篇必须有 7-10 条洞察；每条包含 `title`、`claim`、`analysis`、`value` 四个字段，前台按“核心论断 / 深层分析 / 战略价值”分层展示。
- `编辑解读`必须是至少 3 个自然段的公众号式深度分析，流水线要求不少于 500 个可读字符；整篇正文不少于 800 个可读字符。
- 嘉宾介绍的对象必须是本期访谈中实际输出核心观点的被访谈者或主要对谈者；频道名、播客名、主持人和制作机构只能放在来源字段，不能写成嘉宾。
- `guest_name` 与 `guest_intro` 必须在管理员审核时确认；公开资料不足时使用“待人工确认”，不能根据节目主页猜测人物。
- 单集链接字段只接受具体单集页面、视频播放页或音频直链，不能用频道主页作为回退链接。

## 内容和版权边界

- 不保存完整音频。
- 不长期保存完整转录稿。
- 公开正文、公开字幕和网页文字只作为生成草稿的临时上下文。
- 前台展示生成后的解读和原始来源链接。
- 旧文章如果没有 `insights`，文章页会暂时使用 `key_points` 兼容展示；后台保存或发布时必须补齐 7-10 条结构化洞察。
- 每篇解读的嘉宾介绍只描述该篇访谈中输出核心观点的人物本人，不描述整个频道或节目。
- 人工审核后才发布。

## 本地检查

```bash
npm install
npm run check
```

`npm run check` 只做脚本语法检查。真正运行后台任务时需要安装依赖，GitHub Actions 会在运行时自动安装。

## 后续修改和同步

- 页面样式与公开展示：修改 `index.html`、`article.html`。
- 审核流程：修改 `admin.html`。
- 本地 Demo 内容：修改 `demo-articles.js`。
- 频道与 RSS：修改 `config/sources.json`。
- AI 生成规则和采集逻辑：修改 `scripts/run-pipeline.mjs`。
- 数据库结构：修改 `supabase/schema.sql`，并在 Supabase SQL Editor 手动执行对应迁移。

代码修改完成后：

```bash
npm run check
git add .
git commit -m "Describe the change"
git push origin main
```

推送后，GitHub Pages 会重新部署静态前台，GitHub Actions 的下一次任务会使用新流水线。
数据库迁移不会因 `git push` 自动执行，必须单独在 Supabase SQL Editor 执行。
