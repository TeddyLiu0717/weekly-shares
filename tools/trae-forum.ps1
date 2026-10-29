<#
.SYNOPSIS
    TRAE 官方中文社区 (forum.trae.cn, Discourse) 命令行客户端
    认证方式：SSO 登录后的会话 Cookie + CSRF Token（站点已禁用 User API Key）

.DESCRIPTION
    子命令：
      auth         自动从本机 Trae CN 内嵌浏览器分区提取论坛登录 Cookie（VSS 卷影拷贝，会弹一次 UAC）
      check        验证当前 Cookie 是否登录有效，并显示当前用户 / CSRF
      categories   列出所有版块（无需登录）
      draft        创建/更新【私有草稿】，不发布（推荐先用来验证写入权限）
      post         发布新主题到指定版块
      reply        回复指定主题
      upload       上传图片/视频等附件到论坛（multipart），返回线上 URL
      publishmd    发布 Markdown 文件：自动上传文中本地图片/视频并改写为线上链接（-Draft 只存草稿）

.EXAMPLE
    # 首次使用：确保已在 Trae 内置浏览器里登录过 forum.trae.cn，然后一键取 Cookie
    .\trae-forum.ps1 auth
    .\trae-forum.ps1 check
    .\trae-forum.ps1 categories
    .\trae-forum.ps1 draft -Title "测试" -Raw "内容" -Category 11
    .\trae-forum.ps1 post -Title "CLI 发帖测试" -RawFile .\body.md -Category 11
    .\trae-forum.ps1 reply -TopicId 326056 -Raw "感谢回复！"
    .\trae-forum.ps1 upload -File .\shots\arch.png
    .\trae-forum.ps1 publishmd -Title "我的帖子" -RawFile .\post.md -Category 9 -Draft
    .\trae-forum.ps1 publishmd -Title "我的帖子" -RawFile .\post.md -Category 9

.NOTES
    认证机制：站点已禁用 Discourse User API Key，登录走 www.trae.cn 统一 SSO。
    本客户端使用登录后下发的长效 _t Cookie + 同会话 CSRF（cookie jar 自动维持）。
    Cookie 三种来源（优先级从高到低）：
      a) -Cookie 参数直接传
      b) 环境变量 $env:TRAE_FORUM_COOKIE
      c) 配置文件 %USERPROFILE%\.trae-forum\cookie.txt（`auth` 子命令自动生成）
    `auth` 依赖同目录的 trae-forum-auth.py（Python 3）。
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('auth', 'check', 'categories', 'draft', 'post', 'reply', 'upload', 'publishmd')]
    [string]$Command = 'check',

    [string]$Title,
    [string]$Raw,
    [string]$RawFile,
    [int]$Category = 11,
    [int]$TopicId,
    [string]$Cookie,
    [string]$File,
    [string]$AssetsDir,
    [switch]$Draft,

    [string]$BaseUrl = 'https://forum.trae.cn'
)

$ErrorActionPreference = 'Stop'
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36'

function Resolve-Cookie {
    param([string]$Inline)
    if ($Inline) { return $Inline.Trim() }
    if ($env:TRAE_FORUM_COOKIE) { return $env:TRAE_FORUM_COOKIE.Trim() }
    $cfg = Join-Path $env:USERPROFILE '.trae-forum\cookie.txt'
    if (Test-Path $cfg) {
        $line = (Get-Content $cfg -Raw).Trim()
        if ($line -and $line -notmatch '=') { $line = "_t=$line" }
        return $line
    }
    return $null
}

function Get-Python {
    foreach ($c in @('python', 'python3', 'py')) {
        $g = Get-Command $c -ErrorAction SilentlyContinue
        if ($g) {
            if ($c -eq 'py') { return @('py', '-3') }
            return @($g.Source)
        }
    }
    return $null
}

function Sync-AuthCookie {
    # 自动从 Trae CN 内嵌浏览器(trae-webview 分区)提取论坛登录 Cookie
    $srcDb = Join-Path $env:APPDATA 'Trae CN\Partitions\trae-webview\Network\Cookies'
    if (-not (Test-Path $srcDb)) { throw "找不到内嵌浏览器 Cookie 库：$srcDb" }
    $cfgDir = Join-Path $env:USERPROFILE '.trae-forum'
    New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
    $cfg = Join-Path $cfgDir 'cookie.txt'
    $tmpDb = [IO.Path]::GetTempFileName()

    $copied = $false
    try {
        $fs = New-Object IO.FileStream($srcDb, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]7)
        $out = [IO.File]::Create($tmpDb)
        $fs.CopyTo($out); $out.Close(); $fs.Close()
        $copied = $true
    } catch {
        Write-Host 'Cookie 库正被占用，需要通过 VSS 卷影拷贝读取，请在弹出的 UAC 中点“是”…' -ForegroundColor Yellow
        $flagFile = "$tmpDb.flag"
        Remove-Item $flagFile -Force -ErrorAction SilentlyContinue
        Remove-Item $tmpDb -Force -ErrorAction SilentlyContinue  # esentutl /d 不覆盖已存在文件
        # 用 Base64 编码命令，避免 Start-Process -Verb RunAs 在 PS5.1 下的引号/空格拆解问题
        $inner = @"
`$ErrorActionPreference='Continue'
try {
  & esentutl.exe /y /vss '$srcDb' /d '$tmpDb' | Out-Null
  if ((Test-Path '$tmpDb') -and ((Get-Item '$tmpDb').Length -gt 0)) { 'OK' | Out-File -FilePath '$flagFile' -Encoding ascii }
  else { 'esentutl produced no output' | Out-File -FilePath '$flagFile' -Encoding ascii }
} catch { `$_.Exception.Message | Out-File -FilePath '$flagFile' -Encoding ascii }
"@
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($inner))
        try {
            $p = Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -EncodedCommand $enc" -PassThru -Wait
        } catch {
            throw "提权失败：$($_.Exception.Message)"
        }
        if (-not (Test-Path $flagFile)) { throw '提权拷贝被取消或失败（未收到 UAC 确认）' }
        $flag = (Get-Content $flagFile -Raw).Trim()
        Remove-Item $flagFile -Force -ErrorAction SilentlyContinue
        if ($flag -ne 'OK') { throw "VSS 拷贝失败: $flag" }
        $copied = $true
    }
    if (-not $copied) { throw 'Cookie 库拷贝失败' }

    try {
        $pyExe = @(Get-Python)
        if ($pyExe.Count -eq 0) { throw '未找到 Python 3，请安装 Python 或手动配置 cookie.txt' }
        $authPy = Join-Path $PSScriptRoot 'trae-forum-auth.py'
        if ($pyExe.Count -eq 2 -and $pyExe[0] -eq 'py') {
            $pyOut = & py -3 $authPy --src $tmpDb --out $cfg 2>&1
        } else {
            $pyOut = & $pyExe[0] $authPy --src $tmpDb --out $cfg 2>&1
        }
        if ($LASTEXITCODE -ne 0) { throw ("Cookie 提取失败: " + ($pyOut -join ' ')) }
        Write-Host ("已写入登录凭证: {0}（{1}）" -f $cfg, ($pyOut -join ' ')) -ForegroundColor Green
    } finally {
        Remove-Item $tmpDb -Force -ErrorAction SilentlyContinue
    }
}

function New-CookieJar {
    # 把 "_t=...; _forum_session=..." 形式的 Cookie 头写成 curl 的 Netscape 格式 cookie jar
    param([string]$CookieText)
    $jar = [IO.Path]::GetTempFileName()
    $lines = @('# Netscape HTTP Cookie File')
    foreach ($pair in ($CookieText -split ';')) {
        $pair = $pair.Trim()
        if (-not $pair) { continue }
        $idx = $pair.IndexOf('=')
        if ($idx -lt 1) { continue }
        $name = $pair.Substring(0, $idx)
        $val  = $pair.Substring($idx + 1)
        # domain  include-subdomains  path  secure  expires  name  value
        $lines += ("forum.trae.cn`tFALSE`t/`tTRUE`t0`t{0}`t{1}" -f $name, $val)
    }
    [IO.File]::WriteAllLines($jar, $lines, (New-Object Text.UTF8Encoding($false)))
    return $jar
}

function Invoke-Curl {
    # 统一用系统自带 curl.exe 传输：
    # 1) PS 5.1 的 Invoke-WebRequest 会丢弃含 %2B 等编码字符的 Cookie 头（实测匿名 404）；
    # 2) 需要用 cookie jar 在 GET 页面 -> POST 之间保持 _forum_session（CSRF 绑定该会话）。
    param(
        [string]$Url, [string]$Method, [hashtable]$Headers, [string]$BodyText, [string]$Jar
    )
    $tmpOut = [IO.Path]::GetTempFileName()
    $tmpBody = $null
    $argList = @('-sS', '-X', $Method, '--max-redirs', '0', '-o', $tmpOut, '-w', '%{http_code}')
    if ($Jar) { $argList += @('-b', $Jar, '-c', $Jar) }
    foreach ($k in $Headers.Keys) { $argList += @('-H', "$k`: $($Headers[$k])") }
    if ($null -ne $BodyText) {
        $tmpBody = [IO.Path]::GetTempFileName()
        [IO.File]::WriteAllText($tmpBody, $BodyText, (New-Object Text.UTF8Encoding($false)))
        $argList += @('--data-binary', "@$tmpBody")
    }
    $argList += $Url
    $code = & curl.exe @argList 2>$null
    $content = ''
    if (Test-Path $tmpOut) { $content = [IO.File]::ReadAllText($tmpOut); Remove-Item $tmpOut -Force }
    if ($tmpBody) { Remove-Item $tmpBody -Force }
    $status = 0
    [void][int]::TryParse(($code | Select-Object -Last 1), [ref]$status)
    return [pscustomobject]@{ Status = $status; Content = $content }
}

function Invoke-Discourse {
    param(
        [string]$Path,
        [string]$Method = 'GET',
        [hashtable]$Params,
        [string]$CookieText,
        [string]$Csrf,
        [string]$Accept = 'application/json',
        [string]$Jar
    )
    $url = if ($Path -match '^https?://') { $Path } else { "$BaseUrl$Path" }
    $headers = @{
        'User-Agent'      = $UA
        'Accept'          = $Accept
        'Accept-Language' = 'zh-CN,zh;q=0.9'
    }
    if ($CookieText -and -not $Jar) { $headers['Cookie'] = $CookieText }
    if ($Method -ne 'GET') {
        $headers['X-Requested-With'] = 'XMLHttpRequest'
        $headers['Origin'] = $BaseUrl
        $headers['Referer'] = "$BaseUrl/"
        if ($Csrf) { $headers['X-CSRF-Token'] = $Csrf }
    }
    $body = $null
    if ($null -ne $Params) {
        $body = ($Params.GetEnumerator() | ForEach-Object {
            '{0}={1}' -f [uri]::EscapeDataString($_.Key), [uri]::EscapeDataString([string]$_.Value)
        }) -join '&'
        $headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
    }
    return Invoke-Curl -Url $url -Method $Method -Headers $headers -BodyText $body -Jar $Jar
}

function Get-CsrfToken {
    param([string]$CookieText, [string]$Jar)
    # 已实测：登录态页面 HTML 里的 <meta name="csrf-token" content="...">（86位）
    # 注意：本站 /session/current.json 不返回 csrf 字段；
    # 且 CSRF 绑定同一次 GET 由 Set-Cookie 下发的 _forum_session，必须走同一 cookie jar。
    foreach ($p in '/latest', '/new-topic', '/') {
        $h = Invoke-Discourse -Path $p -CookieText $CookieText -Accept 'text/html' -Jar $Jar
        $m = [regex]::Match($h.Content, '<meta[^>]+name=["'']csrf-token["''][^>]+content=["'']([^"'']+)')
        if (-not $m.Success) {
            $m = [regex]::Match($h.Content, '<meta[^>]+content=["'']([^"'']+)["''][^>]+name=["'']csrf-token["'']')
        }
        if ($m.Success) { return $m.Groups[1].Value }
    }
    return $null
}

function Get-BodyText {
    if ($RawFile) {
        if (-not (Test-Path $RawFile)) { throw "RawFile 不存在: $RawFile" }
        # PS5.1 默认按 ANSI(GBK) 读取无 BOM 文件，中文会乱码，显式指定 UTF-8
        return (Get-Content $RawFile -Raw -Encoding UTF8)
    }
    if ($Raw) { return $Raw }
    throw "请用 -Raw 提供正文，或用 -RawFile 指定正文文件"
}

function Invoke-UploadFile {
    # multipart/form-data 上传（curl -F）。PS5.1 无法可靠构造 multipart，统一走 curl.exe。
    param(
        [string]$Path,
        [string]$CookieText,
        [string]$Csrf,
        [string]$Jar,
        [string]$UploadType = 'composer'
    )
    if (-not (Test-Path -LiteralPath $Path)) { throw "文件不存在: $Path" }
    $full = (Resolve-Path -LiteralPath $Path).Path
    $maxTry = 4
    for ($try = 1; $try -le $maxTry; $try++) {
        $tmpOut = [IO.Path]::GetTempFileName()
        $argList = @('-sS', '-X', 'POST', '-o', $tmpOut, '-w', '%{http_code}',
                     '-b', $Jar, '-c', $Jar,
                     '-H', "User-Agent: $UA",
                     '-H', 'Accept: application/json',
                     '-H', 'X-Requested-With: XMLHttpRequest',
                     '-H', "X-CSRF-Token: $Csrf",
                     '-H', "Origin: $BaseUrl",
                     '-H', "Referer: $BaseUrl/",
                     '-F', "type=$UploadType",
                     '-F', 'synchronous=true',
                     '-F', "file=@$full",
                     "$BaseUrl/uploads.json")
        $code = & curl.exe @argList 2>$null
        $content = ''
        if (Test-Path $tmpOut) { $content = [IO.File]::ReadAllText($tmpOut); Remove-Item $tmpOut -Force }
        $status = 0
        [void][int]::TryParse(($code | Select-Object -Last 1), [ref]$status)
        if ($status -eq 429 -and $try -lt $maxTry) {
            $wait = 15
            try {
                $wj = ($content | ConvertFrom-Json).extras.wait_seconds
                if ($wj) { $wait = [int]$wj + 2 }
            } catch {}
            Write-Host "上传被限流，等待 ${wait}s 后重试（$try/$maxTry）…" -ForegroundColor Yellow
            Start-Sleep -Seconds $wait
            continue
        }
        return [pscustomobject]@{ Status = $status; Content = $content }
    }
}

function ConvertTo-OnlineMarkdown {
    # 把 Markdown 里引用的本地图片/视频上传并改写为 Discourse upload:// 链接
    param(
        [string]$MdText,
        [string]$BaseDir,
        [string]$CookieText,
        [string]$Csrf,
        [string]$Jar
    )
    $videoExt = '\.(?:mp4|m4v|mov|webm)(?:\?[^)]*)?'
    $cache = @{}
    $script:uploaded = @()

    # 跨运行的上传缓存（按文件 MD5）：同一文件不重复上传，发稿幂等且避开频率限制
    $cacheFile = Join-Path $env:USERPROFILE '.trae-forum\upload-cache.json'
    $persist = @{}
    if (Test-Path $cacheFile) {
        try {
            (Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties |
                ForEach-Object { $persist[$_.Name] = $_.Value }
        } catch {}
    }
    $saveCache = {
        $json = ($persist | ConvertTo-Json -Compress)
        [IO.File]::WriteAllText($cacheFile, $json, (New-Object Text.UTF8Encoding($false)))
    }
    $fileKey = { param($p) (Get-FileHash -LiteralPath $p -Algorithm MD5).Hash }
    $resolveUpload = {
        param($path)
        if ($cache.ContainsKey($path)) { return $cache[$path] }
        $hk = & $fileKey $path
        if ($persist.ContainsKey($hk)) { $cache[$path] = $persist[$hk]; return $persist[$hk] }
        $r = Invoke-UploadFile -Path $path -CookieText $CookieText -Csrf $Csrf -Jar $Jar
        if ($r.Status -ne 200) { throw "上传失败 [$path] HTTP $($r.Status): $($r.Content)" }
        $j = $r.Content | ConvertFrom-Json
        if (-not $j.short_url) { throw "上传响应缺少 short_url [$path]: $($r.Content)" }
        $cache[$path] = $j.short_url
        $persist[$hk] = $j.short_url
        & $saveCache
        $script:uploaded = @($script:uploaded) + [pscustomobject]@{ File = $path; Url = $j.short_url }
        return $j.short_url
    }

    $ensure = {
        param([string]$ref)
        if ($ref -match '^(?:https?:)?//|^data:') { return $null }
        $cand = $ref -replace '^file:///', ''
        foreach ($base in @($BaseDir, (Get-Location).Path)) {
            $p = Join-Path $base ($cand -replace '/', '\')
            if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
        }
        return $null
    }

    # ![alt](path) 与 <img src="path">
    $patterns = @(
        @{ re = '!\[([^\]]*)\]\(([^)]+)\)'; kind = 'image' },
        @{ re = '<img\b[^>]*?\bsrc=["'']([^"'']+)["'']'; kind = 'imgtag' }
    )
    foreach ($pat in $patterns) {
        $MdText = [regex]::Replace($MdText, $pat.re, {
            param($m)
            $ref = if ($pat.kind -eq 'image') { $m.Groups[2].Value } else { $m.Groups[1].Value }
            $alt = if ($pat.kind -eq 'image') { $m.Groups[1].Value } else { '' }
            $path = & $ensure $ref
            if (-not $path) { return $m.Value }
            $short = & $resolveUpload $path
            if ($pat.kind -eq 'image') { return "![$alt]($short)" }
            return ($m.Value -replace [regex]::Escape($ref), $short)
        })
    }

    # [文字](xxx.mp4) 视频附件，以及裸的本地视频路径
    $MdText = [regex]::Replace($MdText, '\[([^\]]*)\]\(([^)]+' + $videoExt + ')\)', {
        param($m)
        $ref = $m.Groups[2].Value
        $path = & $ensure $ref
        if (-not $path) { return $m.Value }
        $short = & $resolveUpload $path
        $name = if ($m.Groups[1].Value) { $m.Groups[1].Value } else { [IO.Path]::GetFileName($path) }
        $name = $name -replace '\|attachment\s*$', ''
        return "[$name|attachment]($short)"
    })

    return [pscustomobject]@{ Text = $MdText; Uploads = $script:uploaded }
}

$cookieText = Resolve-Cookie $Cookie

switch ($Command) {

    'categories' {
        $r = Invoke-Discourse -Path '/categories.json'
        if ($r.Status -ne 200) { throw "读取版块失败 HTTP $($r.Status): $($r.Content)" }
        $j = $r.Content | ConvertFrom-Json
        $j.category_list.categories |
            Sort-Object id |
            Format-Table id, slug, name -AutoSize
    }

    'auth' {
        Sync-AuthCookie
    }

    'check' {
        if (-not $cookieText) {
            Write-Host '未配置 Cookie。请先登录 forum.trae.cn，配置文件：%USERPROFILE%\.trae-forum\cookie.txt' -ForegroundColor Yellow
            Write-Host "内容为 _t=<值>（或用 -Cookie / `$env:TRAE_FORUM_COOKIE 传入）" -ForegroundColor Yellow
            exit 1
        }
        $jar = New-CookieJar $cookieText
        try {
            $r = Invoke-Discourse -Path '/session/current.json' -CookieText $cookieText -Jar $jar
            if ($r.Status -eq 404 -or $r.Content -match 'not_logged_in') {
                Write-Host 'Cookie 无效或已过期（未登录）。请重新登录后更新 cookie.txt。' -ForegroundColor Red
                exit 2
            }
            if ($r.Status -ne 200) { throw "HTTP $($r.Status): $($r.Content)" }
            $j = $r.Content | ConvertFrom-Json
            $u = $j.current_user
            Write-Host ("登录有效: {0} (id={1}, trust_level={2})" -f $u.username, $u.id, $u.trust_level) -ForegroundColor Green
            $csrf = Get-CsrfToken $cookieText -Jar $jar
            if ($csrf) {
                Write-Host ("CSRF Token: {0}..." -f $csrf.Substring(0, [Math]::Min(16, $csrf.Length))) -ForegroundColor Green
            } else {
                Write-Host '警告：未能提取 CSRF Token，写操作可能失败' -ForegroundColor Yellow
            }
        } finally {
            Remove-Item $jar -Force -ErrorAction SilentlyContinue
        }
    }

    'draft' {
        $bodyText = Get-BodyText
        if (-not $cookieText) { throw '未配置 Cookie' }
        $jar = New-CookieJar $cookieText
        try {
            $csrf = Get-CsrfToken $cookieText -Jar $jar
            if (-not $csrf) { throw '无法获取 CSRF Token，Cookie 可能已失效' }
            # 读取当前 draft_sequence，否则重复保存会 409（“另一个窗口正在编辑”）
            $seq = 0
            $exist = Invoke-Discourse -Path '/drafts.json?draft_key=new_topic' -CookieText $cookieText -Jar $jar
            if ($exist.Status -eq 200) {
                try {
                    $ed = ($exist.Content | ConvertFrom-Json).drafts | Where-Object { $_.draft_key -eq 'new_topic' } | Select-Object -First 1
                    if ($ed) { $seq = [int]$ed.sequence }
                } catch {}
            }
            $payload = @{
                title     = $Title
                reply     = $bodyText
                category  = $Category
                archetype = 'regular'
            } | ConvertTo-Json -Compress
            $r = Invoke-Discourse -Path "/drafts.json?draft_key=new_topic&sequence=$seq" -Method POST -CookieText $cookieText -Csrf $csrf -Jar $jar `
                -Params @{ data = $payload }
            Write-Host "HTTP $($r.Status)"
            if ($r.Content) { $r.Content }
            if ($r.Status -eq 200) {
                Write-Host '私有草稿已保存（未发布）。可在论坛发帖编辑器中看到它。' -ForegroundColor Green
            }
        } finally {
            Remove-Item $jar -Force -ErrorAction SilentlyContinue
        }
    }

    'post' {
        $bodyText = Get-BodyText
        if (-not $Title) { throw '发新主题必须提供 -Title' }
        if (-not $cookieText) { throw '未配置 Cookie' }
        $jar = New-CookieJar $cookieText
        try {
            $csrf = Get-CsrfToken $cookieText -Jar $jar
            if (-not $csrf) { throw '无法获取 CSRF Token，Cookie 可能已失效' }
            $r = Invoke-Discourse -Path '/posts.json' -Method POST -CookieText $cookieText -Csrf $csrf -Jar $jar -Params @{
                title     = $Title
                raw       = $bodyText
                category  = $Category
                archetype = 'regular'
                typing_thanked_msec = '0'
                is_warning = 'false'
                nested_post = 'true'
            }
            if ($r.Status -in 200, 201) {
                $j = $r.Content | ConvertFrom-Json
                $link = "$BaseUrl/t/$($j.topic_slug)/$($j.topic_id)"
                Write-Host "发布成功: $link" -ForegroundColor Green
            } else {
                Write-Host "发布失败 HTTP $($r.Status):" -ForegroundColor Red
                Write-Host $r.Content -ForegroundColor Red
                exit 3
            }
        } finally {
            Remove-Item $jar -Force -ErrorAction SilentlyContinue
        }
    }

    'reply' {
        $bodyText = Get-BodyText
        if (-not $TopicId) { throw '回复必须提供 -TopicId' }
        if (-not $cookieText) { throw '未配置 Cookie' }
        $jar = New-CookieJar $cookieText
        try {
            $csrf = Get-CsrfToken $cookieText -Jar $jar
            if (-not $csrf) { throw '无法获取 CSRF Token，Cookie 可能已失效' }
            $r = Invoke-Discourse -Path '/posts.json' -Method POST -CookieText $cookieText -Csrf $csrf -Jar $jar -Params @{
                raw       = $bodyText
                topic_id  = $TopicId
                nested_post = 'true'
            }
            if ($r.Status -in 200, 201) {
                $j = $r.Content | ConvertFrom-Json
                Write-Host "回复成功: $BaseUrl/t/$($j.topic_slug)/$($j.topic_id)/$($j.post_number)" -ForegroundColor Green
            } else {
                Write-Host "回复失败 HTTP $($r.Status):" -ForegroundColor Red
                Write-Host $r.Content -ForegroundColor Red
                exit 3
            }
        } finally {
            Remove-Item $jar -Force -ErrorAction SilentlyContinue
        }
    }

    'upload' {
        if (-not $File) { throw '请用 -File 指定要上传的文件' }
        if (-not $cookieText) { throw '未配置 Cookie' }
        $jar = New-CookieJar $cookieText
        try {
            $csrf = Get-CsrfToken $cookieText -Jar $jar
            if (-not $csrf) { throw '无法获取 CSRF Token，Cookie 可能已失效' }
            $r = Invoke-UploadFile -Path $File -CookieText $cookieText -Csrf $csrf -Jar $Jar
            Write-Host "HTTP $($r.Status)"
            if ($r.Status -eq 200) {
                $j = $r.Content | ConvertFrom-Json
                Write-Host "上传成功: $File" -ForegroundColor Green
                Write-Host "  url       : $($j.url)"
                Write-Host "  short_url : $($j.short_url)"
            } else {
                Write-Host $r.Content -ForegroundColor Red
                exit 3
            }
        } finally {
            Remove-Item $jar -Force -ErrorAction SilentlyContinue
        }
    }

    'publishmd' {
        if (-not $RawFile) { throw '请用 -RawFile 指定 Markdown 文件' }
        if (-not (Test-Path $RawFile)) { throw "Markdown 不存在: $RawFile" }
        if (-not $Title) { throw '必须提供 -Title' }
        if (-not $cookieText) { throw '未配置 Cookie' }
        $mdFull = (Resolve-Path $RawFile).Path
        $baseDir = if ($AssetsDir) { (Resolve-Path $AssetsDir).Path } else { Split-Path $mdFull -Parent }
        $jar = New-CookieJar $cookieText
        try {
            $csrf = Get-CsrfToken $cookieText -Jar $jar
            if (-not $csrf) { throw '无法获取 CSRF Token，Cookie 可能已失效' }

            $res = ConvertTo-OnlineMarkdown -MdText (Get-Content $mdFull -Raw -Encoding UTF8) -BaseDir $baseDir `
                   -CookieText $cookieText -Csrf $csrf -Jar $jar
            foreach ($u in $res.Uploads) { Write-Host ("已上传 {0} -> {1}" -f (Split-Path $u.File -Leaf), $u.Url) -ForegroundColor Cyan }

            $onlineFile = [IO.Path]::ChangeExtension($mdFull, '.online.md')
            [IO.File]::WriteAllText($onlineFile, $res.Text, (New-Object Text.UTF8Encoding($false)))
            Write-Host "线上版 Markdown 已保存: $onlineFile" -ForegroundColor DarkGray

            if ($Draft) {
                $seq = 0
                $exist = Invoke-Discourse -Path '/drafts.json?draft_key=new_topic' -CookieText $cookieText -Jar $jar
                if ($exist.Status -eq 200) {
                    try {
                        $ed = ($exist.Content | ConvertFrom-Json).drafts | Where-Object { $_.draft_key -eq 'new_topic' } | Select-Object -First 1
                        if ($ed) { $seq = [int]$ed.sequence }
                    } catch {}
                }
                $payload = @{ title = $Title; reply = $res.Text; category = $Category; archetype = 'regular' } | ConvertTo-Json -Compress
                $r = Invoke-Discourse -Path "/drafts.json?draft_key=new_topic&sequence=$seq" -Method POST -CookieText $cookieText -Csrf $csrf -Jar $jar `
                    -Params @{ data = $payload }
                Write-Host "HTTP $($r.Status)"
                if ($r.Content) { $r.Content }
                if ($r.Status -eq 200) { Write-Host '私有草稿已保存（含已上传的图片/视频，未公开发布）。' -ForegroundColor Green }
                else { exit 3 }
            } else {
                $r = Invoke-Discourse -Path '/posts.json' -Method POST -CookieText $cookieText -Csrf $csrf -Jar $jar -Params @{
                    title     = $Title
                    raw       = $res.Text
                    category  = $Category
                    archetype = 'regular'
                    nested_post = 'true'
                }
                if ($r.Status -in 200, 201) {
                    $j = $r.Content | ConvertFrom-Json
                    Write-Host "发布成功: $BaseUrl/t/$($j.topic_slug)/$($j.topic_id)" -ForegroundColor Green
                } else {
                    Write-Host "发布失败 HTTP $($r.Status):" -ForegroundColor Red
                    Write-Host $r.Content -ForegroundColor Red
                    exit 3
                }
            }
        } finally {
            Remove-Item $jar -Force -ErrorAction SilentlyContinue
        }
    }
}
