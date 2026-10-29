# 每周发布 SOP

每周一期，目录命名 `posts/YYYY-Www-slug/`（ISO 周编号）。

## 0. 选题与建期

从 `ideas/BACKLOG.md` 挑题，复制 `templates/weekly-post.md` 为 `post.md`、`templates/meta.json` 为该期 `meta.json`，先填 title/category，status 保持 `draft`。

## 1. 写稿（post.md）

- 图片就写相对路径：`![说明](assets/xxx.png)`
- 视频写：`[视频说明|attachment](assets/demo-720p.mp4)`（注意只写一个 `|attachment`，CLI 会规范化）
- 不要出现本地绝对路径；素材全部放该期 `assets/`

推荐结构：钩子/视频 → 痛点 → 最终效果 → 方案架构 → 手把手步骤 → 踩坑经验 → FAQ → 资源与 CTA。

## 2. 素材

按 [asset-guide.md](asset-guide.md) 出图（1920×1080）和视频（内嵌版 ≤ 720p、<10MB）。

## 3. 本地预览（可选）

用 `assets/build_preview.py` 思路或直接在编辑器检查；正式以论坛草稿为准。

## 4. 存论坛私有草稿（可自动执行）

在**仓库根目录**执行（路径相对仓库根）：

```powershell
powershell -ExecutionPolicy Bypass -File tools\trae-forum.ps1 publishmd `
  -Title "标题（不要嵌中文弯引号）" -RawFile posts\2026-W45-xxx\post.md -Category 9 -Draft
```

- CLI 自动：取 CSRF → 逐个上传素材（429 自动退避；同文件 MD5 缓存不重传）→ 改写为 upload:// → 存草稿 → 生成 post.online.md
- 成功标志：`HTTP 200 {"success":"OK","draft_sequence":N}`
- 打开 https://forum.trae.cn/new-topic 看草稿；检查图片、视频、代码块、链接、无乱码

## 5. 发布（必须 Teddy 明确说“可以发”）

去掉 `-Draft` 重跑同一命令（素材走缓存，秒级完成）。成功后：

1. 回填该期 `meta.json`：status=`published`、forum_topic_id、forum_url、published_at、draft_sequence
2. 追加根目录 `PROGRESS.md` 一行
3. 更新 `README.md` 的「已发布」表格
4. git 提交：`post(YYYY-Www): publish "<标题>"`

## 6. 发布后验收

- 匿名（或无痕窗口）打开 forum_url，图文/视频正常
- post.online.md grep 一遍：无 `assets/`、`C:\`、`.mp4](assets` 等残留
- 一周后补 RETRO.md（浏览/点赞/评论/改进点）

## 故障速查

| 现象 | 处理 |
|---|---|
| Cookie 失效 / 404 not_logged_in | `tools\trae-forum.ps1 auth`（弹 UAC 点是） |
| 429 限流 | CLI 自动等；若仍失败，隔 15 秒重跑（缓存命中不会重传） |
| 视频连接重置 | 压到 720p/<10MB 再试；参考 asset-guide.md 的 ffmpeg 命令 |
| 正文乱码 | 确认 post.md 是 UTF-8；CLI 已按 UTF-8 读取，勿用旧版脚本 |
| 草稿 409 | CLI 已自动读 sequence；若手工调接口记得带最新 sequence |
| BAD CSRF | 确保 GET 页面与 POST 走同一 cookie jar（CLI 已处理） |
