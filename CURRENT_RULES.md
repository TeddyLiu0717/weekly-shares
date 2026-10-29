# Weekly Shares Current Rules

更新时间：2026-10-29T00:00:00+08:00

## 当前口径

1. **发布门**：私有草稿可自动创建；公开发布（publishmd 不带 -Draft）必须当次获得 Teddy 明确许可。
2. **凭证**：`%USERPROFILE%\.trae-forum\cookie.txt` 与 `upload-cache.json` 不入库、不外发；Cookie 失效时跑 `tools\trae-forum.ps1 auth`（会弹一次 UAC）。
3. **远程**：初始化即创建公开仓库 `TeddyLiu0717/weekly-shares` 并推送 main；未发布草稿同样可进公开仓库（内容本就计划公开）。若 Teddy 改主意，改私有或移除远程需单独确认。
4. **节奏**：每周 1 期，ISO 周编号目录；一期一提交，提交信息 `post(YYYY-Www): 标题/状态` 或 `chore: ...`。
5. **素材体积**：内嵌视频用 720p 轻量版（实测 3MB 可传；11MB 1080p 上传连接被重置，原因可能是体积/网络）；1080p 原件仅本地归档。
6. 工具/规范变更：先说明、实测、再提交；不得静默修改 tools/。
