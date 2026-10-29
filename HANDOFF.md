# HANDOFF

更新时间：2026-10-29

## 一句话现状

每周社区分享工程已初始化完毕；第一期《AI 知识库搭建》在论坛**私有草稿**中（素材全上传、预览已给 Teddy），等他一句“可以发”即正式发布到技巧分享版块。

## 接手后先做

1. 读本文件 → PROJECT.md → AGENTS.md → CURRENT_RULES.md
2. 跑登录检查：`powershell -ExecutionPolicy Bypass -File tools\trae-forum.ps1 check`
3. 看 STATUS.md 的待决策项与 posts/2026-W44-ai-knowledge-base/meta.json
4. 若 Teddy 确认发布：在 `D:\github\weekly-shares` 下执行
   `... trae-forum.ps1 publishmd -Title "<见 meta>" -RawFile posts\2026-W44-ai-knowledge-base\post.md -Category 9`
   成功后回填 meta.json 的 forum_topic_id/forum_url/published_at、status=published，追加 PROGRESS，git 提交

## 关键位置

- 发布工具：tools\trae-forum.ps1（发布逻辑与已踩的坑都在文件头注释和 MEMORY.md）
- 发布 SOP：docs\publishing-sop.md
- 素材规范：docs\asset-guide.md
- 帖子模板：templates\weekly-post.md；选题池：ideas\BACKLOG.md
- 凭证（不入库）：%USERPROFILE%\.trae-forum\cookie.txt、upload-cache.json

## 不要做

- 未经当次确认不要公开发布/回帖
- 不要把个人真实 KB（D:\github\knowledge-base）的业务内容搬进帖子
- 不要改 tools/ 而不测；不要把 1080p 大视频直接往论坛传
