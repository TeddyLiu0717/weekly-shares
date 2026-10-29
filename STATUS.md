# Weekly Shares STATUS

更新时间：2026-10-29

## 当前状态：初始化完成，第一期待发布

- 项目骨架与治理文件：已建立（D:\github\weekly-shares）
- 论坛 CLI（tools/）：8 个子命令全部可用——auth / check / categories / draft / post / reply / upload / publishmd
- 登录态：有效（用户52829, id=66969, trust_level=0）
- 第一期 2026-W44：成稿 + 素材完成，论坛私有草稿已保存（draft_sequence=8，8 个素材上传成功），**等待 Teddy 确认后正式发布到「技巧分享」(category=9)**
- 配套脚手架仓库：https://github.com/TeddyLiu0717/ai-kb-starter （public，已推送验证 HTTP 200）

## 阻塞 / 待决策

1. 第一期发布确认（Teddy 正在看草稿）
2. 周更固定日期（建议周四稿、周五发）
3. GitHub 远程仓库是否公开（默认按公开初始化推送）

## 风险

- TL0 账号真实发帖未实测过（草稿/上传均成功；正式 post 的新用户限制未知，发布即知）
- 长效 `_t` Cookie 有过期可能；失效后重跑 auth（一次 UAC）
- 大文件上传：11MB mp4 曾连接重置；已改用 3MB 720p 内嵌
