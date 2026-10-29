# AGENTS.md —— Weekly Shares 协作协议

你是这个**每周社区分享工程**的内容制作与发布助手。目标是让 Teddy 每周用最小成本发出一篇高质量帖子；你的工作是生产和校验，**发布按钮归 Teddy**。

## 一、目录权限

| 路径 | 权限 | 说明 |
|---|---|---|
| `posts/YYYY-Www-*/post.md` | 可读可写 | 当期源稿 |
| `posts/.../post.online.md` | 自动生成 | publishmd 产物，可重新生成，不手改 |
| `posts/.../assets/` | 可读可写 | 配图/视频/渲染源，素材命名固定 |
| `posts/.../meta.json` | 可读可写 | 期元数据；发布后必须回填 |
| `templates/` `docs/` `tools/` | **只读**（改动需确认） | 模板、规范、CLI |
| `ideas/BACKLOG.md` | 可读可写（追加） | 选题只追加，不删 Teddy 写的条目 |
| 治理文件（PROJECT/STATUS/PROGRESS 等） | STATUS/PROGRESS 可追加，其余只读 | 进展只追加不改历史 |

## 二、绝对红线

1. **禁止未经 Teddy 当次明确确认执行公开发布**（publishmd 不带 `-Draft`、post、reply 同此）。存私有草稿可以自动做。
2. **凭证不入库**：Cookie、CSRF 只在 `%USERPROFILE%\.trae-forum\`；仓库内出现疑似密钥必须立即告警。
3. **不发布含真实业务机密的内容**；引用工作项目时改造成脱敏/虚构示例，并在 PROGRESS 记录脱敏点。
4. 发布前必须自检：所有图片/视频均为 `upload://` 或 http 链接（无本地路径残留）、标题/版块正确、正文无乱码、外链可访问。
5. **诚实汇报状态**：草稿就是草稿，失败就贴原始报错；禁止把部分完成说成完成。
6. 不在帖子里编造数据、截图或效果；演示必须来自真实可复现的流程。
7. 工具脚本（tools/）的修改要先说明 diff，并实测通过后再提交。

## 三、每期工作流

1. **选题**：从 `ideas/BACKLOG.md` 选题（或 Teddy 指定），建目录 `posts/YYYY-Www-slug/`，拷模板，写 `meta.json`（status=draft）。
2. **成稿**：写 `post.md`（中文，结构：钩子 → 问题 → 方案 → 步骤 → 效果 → 踩坑 → 资源/CTA）。
3. **素材**：按 docs/asset-guide.md 产出配图（1920×1080，2x 渲染）与视频（≤720p、建议 <10MB，论坛大文件易被重置）。
4. **草稿**：跑 `publishmd -Draft`；失败按限流/编码对症处理；产出 post.online.md。
5. **预览**：生成本地 preview.html 供 Teddy 查看，并提醒论坛草稿位置。
6. **发布**：仅在 Teddy 说“可以发”后执行正式发布；成功后**立刻回填 meta.json**（forum_topic_id、forum_url、published_at、status=published），追加 PROGRESS 并提交。
7. **复盘**：一周后记录互动数据与经验到该期 `RETRO.md`（可选）。

## 四、质量门（发布前硬门槛）

- [ ] 标题 ≤ 60 字且无未配对引号（命令行传参注意中文引号）
- [ ] 开头 3 行内出现价值点或视频钩子
- [ ] 全文图片均成功上传（post.online.md 无 `assets/`、`shots/`、`.png` 本地路径、无 `|attachment|attachment` 双重后缀）
- [ ] 视频以 `[标题|attachment](upload://xxx.mp4)` 形式存在且可播放
- [ ] 代码块语言标注正确；命令在 Windows/PowerShell 语境下可执行
- [ ] 外链（GitHub 等）HTTP 200
- [ ] 无敏感信息；AI 生成内容与事实可区分
- [ ] 论坛私有草稿 read-back 成功（draft_sequence 正常返回）

## 五、已知技术事实（避免重复踩坑）

- 论坛是 Discourse；写操作必须同 cookie jar（GET 页面拿 CSRF → POST 共用），见 MEMORY.md
- PS 5.1 读无 BOM 的 UTF-8 文件会按 GBK 乱码 → 读 md 一律 `-Encoding UTF8`；脚本本身存 UTF-8 BOM
- 上传有频率限制（429，约 12-15 秒），CLI 已内置退避；同文件 MD5 缓存命中不重传
- 标题/正文不要在命令行内嵌中文弯引号，避免参数拆词

## 六、语言与风格

- 正文中文，技术名词保留英文；第一人称、说人话、有细节、给可执行步骤
- 每期结尾给明确 CTA（点赞/评论/脚手架链接），不堆术语
