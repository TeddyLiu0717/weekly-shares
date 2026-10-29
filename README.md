# Weekly Shares

Teddy 的每周社区分享工程：把每周值得分享的**干货**与自己的**实践沉淀**，稳定生产成一篇带图、带演示视频、可一键发布的社区帖子。

- 主阵地：Trae 官方中文社区 https://forum.trae.cn （Discourse）
- 节奏：每周一期，每期一个独立目录
- 原则：内容先在本地成稿 → 私有草稿验证 → **人工确认后**才公开发布

## 目录结构

```text
weekly-shares/
├── posts/                         # 每期内容（按 ISO 周编号）
│   └── 2026-W44-ai-knowledge-base/
│       ├── post.md                #   源稿（引用本地 assets）
│       ├── post.online.md         #   发布版（素材已替换为论坛 upload:// 链接）
│       ├── meta.json              #   期元数据：标题/版块/状态/论坛链接
│       └── assets/                #   配图、视频、渲染源文件
├── templates/                     # 每周帖子模板、meta 模板
├── ideas/                         # 选题池 BACKLOG.md
├── tools/                         # 论坛 CLI（trae-forum.ps1 + auth.py）
├── docs/                          # 发布 SOP、素材规范
└── 治理文件：PROJECT / ROADMAP / ACCEPTANCE / AGENTS / STATUS / PROGRESS / MEMORY ...
```

## 每周三步

```powershell
# 1. 成稿后先存论坛【私有草稿】（自动上传图片/视频并改写链接）
powershell -ExecutionPolicy Bypass -File tools\trae-forum.ps1 publishmd `
  -Title "标题" -RawFile posts\2026-W45-xxx\post.md -Category 9 -Draft

# 2. 在论坛发帖框确认效果（或打开本地 preview.html）

# 3. 人工说“可以发”后，去掉 -Draft 正式发布
powershell -ExecutionPolicy Bypass -File tools\trae-forum.ps1 publishmd `
  -Title "标题" -RawFile posts\2026-W45-xxx\post.md -Category 9
```

详见 [发布 SOP](docs/publishing-sop.md)。版块：互动交流=11、问题求助=7、产品建议=8、**技巧分享=9**、官方公告=4。

## 已发布

| 期 | 标题 | 版块 | 状态 | 链接 |
|---|---|---|---|---|
| 2026-W44 | 我让 AI 帮我养知识库：4000 页 Obsidian 知识库全自动搭建手册 | 技巧分享(9) | 草稿待发布 | — |

## 环境

- Windows + PowerShell；CLI 用 `powershell.exe`（5.1）运行
- Python 3（auth 取 Cookie；本期素材脚本）
- 图片/视频渲染：Edge headless + ffmpeg（静态绿色版，不进仓库）
- 登录凭证只存 `%USERPROFILE%\.trae-forum\`，**绝不入库**
