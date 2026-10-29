# 配图与视频规范

目标：每期帖子有统一的视觉风格，素材可由 AI + 浏览器/ffmpeg 无人值守生成。

## 配图

- 尺寸：1920×1080（封面可同尺寸），用 Edge headless 以 2x 渲染（实际像素 3840×2160，显示清晰）
- 格式：PNG（界面/图表）；照片类可 JPG
- 风格基线（参考第一期 `posts/2026-W44-ai-knowledge-base/assets/scenes.html`）：
  - 深色场景：背景 `#0b1020→#1e1b4b` 径向渐变，强调色紫 `#7c3aed`、蓝 `#4f46e5`、青绿 `#34d399`
  - 浅色场景：底 `#f8fafc`，卡片白 + 1px `#e2e8f0` 边 + 柔和投影
  - 中文字体栈 `"Microsoft YaHei UI","Microsoft YaHei","Segoe UI"`
- 类型常备 6 张：封面、架构/分层、流程步骤、对话/用法、界面截图（可用 HTML 高仿）、终端输出；结尾 CTA 可选
- 截图里的内容必须是**真实可复现**的脱敏示例，不伪造数据

渲染命令（HTML 用 `?scene=N` 切场景）：

```powershell
$edge="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
& $edge --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 `
  --window-size=1920,1080 --virtual-time-budget=4000 `
  --user-data-dir="$env:TEMP\edge-shot-N" `
  --screenshot="assets/scene-N.png" "file:///绝对路径/scenes.html?scene=N"
```

## 视频

- 内嵌版：1280×720、H.264(yuv420p)、CRF 26、+faststart，**控制在 10MB 内**（第一期 45 秒 = 3MB，上传成功）
- 1080p 母版仅本地归档（论坛 11MB 实测连接重置）
- 形式：静态场景图 + 缓慢推近（zoompan）+ 淡入淡出，每镜约 4.5 秒；无需配音也能看懂，关键文字在画面内
- 生成：逐镜 `-loop 1 -i scene.png -vf "scale=3840:2160,zoompan=...,fade=..."` 出 mp4 片段，再 concat（第一期命令可查 PROGRESS / 复用 build 脚本）

720p 转码：

```powershell
ffmpeg -i master.mp4 -vf scale=1280:720 -c:v libx264 -preset medium -crf 26 -movflags +faststart out-720p.mp4
```

ffmpeg 获取（不入库）：https://github.com/BtbN/FFmpeg-Builds/releases （win64 gpl 静态版）。

## 命名与归档

- `assets/scene-NN.png` 按出现顺序；视频 `assets/<slug>-720p.mp4` + `<slug>.mp4`
- 渲染源（scenes.html、build_preview.py）与素材同目录保存，保证下期可改可复现
- meta.json 登记全部 assets（发布用）与 extra_assets（仅归档）
