# MEMORY —— 长期事实（跨会话有效）

## 论坛平台事实（forum.trae.cn）

- 平台：Discourse；响应头 `X-Discourse-Route`；无 User API Key（管理员禁用 `/user-api-key/new`）
- 登录：无本地登录，走 www.trae.cn SSO；唯一可用认证是长效 Cookie `_t`（约 376 字符、URL 编码含 `%2B`），存 `%USERPROFILE%\.trae-forum\cookie.txt`
- `_forum_session` 会话级不落盘；**CSRF 必须从登录 HTML 的 `<meta name="csrf-token">` 取，且 GET 与后续 POST 共用同一 curl cookie jar**（/session/current.json 不含 csrf）
- 版块 ID：互动交流=11、问题求助=7、产品建议=8、技巧分享=9、官方公告=4
- 账号：用户52829 / id=66969 / trust_level=0（can_create_topic=true）
- 上传：POST `/uploads.json`，multipart 字段 type=composer、synchronous=true、file=@…；返回 `short_url`（upload://xxx）与 CDN `url`
- 限流：连续上传触发 429（wait_seconds≈12-15），需退避；同内容重复上传服务端会去重并返回同一 short_url
- 草稿：POST `/drafts.json?draft_key=new_topic&sequence=N`，N 要先 GET 读，否则 409；清空草稿用 POST data={}
- 发帖：POST `/posts.json`（title/raw/category/archetype=regular）；视频在正文里写法 `[标题|attachment](upload://xxx.mp4)`，图片标准 `![]()`

## 本机环境

- Shell：宿主 PowerShell 7，但脚本一律用 `powershell.exe`（5.1）兼容运行；脚本文件必须 UTF-8 BOM
- Python：`C:\Users\liuya\AppData\Local\Programs\Python\Python312\python.exe`（命令名 python）
- Edge：`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`（headless=new 可渲染截图）
- git 2.56、gh 2.103（账号 TeddyLiu0717，scope: repo/gist/read:org）
- ffmpeg：本期绿色版在临时工作目录 tools 缓存（不入库）；需要时从 BtbN/FFmpeg-Builds 下载
- PS5.1 坑：`Get-Content` 无 BOM 默认 GBK；单元素数组 `+=` 会解包（用 `@($a) + $x`）；Start-Process -Verb RunAs 用 -EncodedCommand

## 内容事实

- 第一期配套开源仓库：https://github.com/TeddyLiu0717/ai-kb-starter
- 个人真实 KB（私有、勿外传路径与内容细节）：四层 raw/wiki/索引/Obsidian，4227 来源页
