# Weekly Shares ACCEPTANCE

## 验收原则

自述不算完成；以命令退出码、API read-back、文件产物、可打开的链接为证据。每期发布验收必须有论坛返回的 topic 链接，且该链接匿名可读。

## 2026-10-29 项目初始化验收

- 目录骨架存在：posts / templates / ideas / tools / docs（Get-ChildItem read-back）
- 第一期产物完整：post.md、post.online.md、10 张 PNG、2 个 MP4（720p=3.00MB / 1080p=11.05MB）、scenes.html、build_preview.py
- tools\trae-forum.ps1 从新位置运行 check 成功，登录态有效（证据见 STATUS.md）
- 论坛私有草稿 read-back：HTTP 200，draft_sequence 递增，8 个素材全部上传（7 图 + 1 视频）
- 脚手架仓库公开可读：https://github.com/TeddyLiu0717/ai-kb-starter （HTTP 200，public=true）

## 每期发布验收清单

- [ ] publishmd 正式发布返回 200/201 且有 topic_id
- [ ] meta.json 已回填 forum_topic_id / forum_url / published_at，status=published
- [ ] 匿名打开 forum_url：标题、正文、图片、视频均正常
- [ ] post.online.md 无本地路径残留
- [ ] PROGRESS.md 已追加；git 已提交
- [ ] 无敏感信息外泄（发布前最后一遍 diff 检查）

## 通用验收清单

- [ ] 已读 PROJECT/AGENTS/CURRENT_RULES
- [ ] git status / diff 已检查，改动范围符合授权
- [ ] 适用脚本已实测（CLI 命令 exit 0）
- [ ] 关键产物已 read-back
- [ ] 剩余风险与待 Teddy 决策项已列出
