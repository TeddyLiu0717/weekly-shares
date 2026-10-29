# -*- coding: utf-8 -*-
"""把 post.online.md 包装成可本地预览的 HTML（素材映射回本地文件）。"""
import io, os, re, json

base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
md = io.open(os.path.join(base, 'post.online.md'), encoding='utf-8').read()

asset_map = {
    'mcxUk52Lg625eghyP0a68f8o57y.png': 'shots/scene-05.png',
    'hZqKvYMaB2as1cdUt2jY3GoLugh.jpeg': 'shots/scene-06.png',
    '48p0qzKnExviYLF4akM0x3bFUY9.png': 'shots/scene-04.png',
    'jGCNi6Hp3mMpxQx7fDH4Y5orQI4.jpeg': 'shots/scene-02.png',
    'bfzPuc8z7Sr0kVp8L2z7aNxerSe.png': 'shots/scene-03.png',
    'yv6sJMB8xiU55SDpyF5tl7YBNi3.jpeg': 'shots/scene-07.png',
    '5lxK8WwBqFNpYSevoOXLgcFvmgW.jpeg': 'shots/scene-08.png',
    'euKKsofckg9nyPjuCw2zOUTDN1A.mp4': 'kb-demo-720p.mp4',
}
def repl(m):
    return asset_map.get(m.group(1), m.group(0))
md_local = re.sub(r'upload://([^\)\s]+)', repl, md)

tpl = '''<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
<title>草稿预览 · AI 知识库搭建帖</title>
<script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
<style>
 body{background:#eef0f4;margin:0;padding:40px 0;font-family:"Microsoft YaHei UI","Segoe UI",sans-serif;color:#1f2937}
 .bar{max-width:880px;margin:0 auto 18px;padding:12px 20px;background:#fff7ed;border:1px solid #fdba74;color:#9a3412;border-radius:12px;font-size:14px}
 article{max-width:880px;margin:0 auto;background:#fff;padding:56px 64px;border-radius:16px;box-shadow:0 10px 40px -20px rgba(0,0,0,.25);line-height:1.85;font-size:17px}
 h1{font-size:30px;margin:38px 0 16px;padding-bottom:8px;border-bottom:1px solid #e5e7eb}
 h2{font-size:23px;margin:30px 0 12px} img{max-width:100%;border-radius:10px;border:1px solid #e5e7eb;display:block;margin:18px 0}
 video{max-width:100%;border-radius:10px;display:block;margin:18px 0}
 pre{background:#0f172a;color:#e2e8f0;padding:18px 22px;border-radius:10px;overflow:auto;font-size:14px;line-height:1.6}
 code{font-family:Consolas,monospace;font-size:14px} p code,li code{background:#f1f5f9;padding:2px 7px;border-radius:6px;color:#7c3aed}
 blockquote{border-left:4px solid #a78bfa;background:#f5f3ff;margin:16px 0;padding:10px 20px;color:#4c1d95}
 table{border-collapse:collapse;width:100%;font-size:15px;margin:14px 0} td,th{border:1px solid #d1d5db;padding:8px 12px}
 a{color:#4f46e5}
</style></head><body>
<div class="bar">📝 本地草稿预览（与论坛发帖效果一致）· 目标版块：技巧分享 · 确认无误后告诉我即可一键发布</div>
<article id="out"></article>
<script id="md" type="text/markdown">__MD__</script>
<script>
 const src = document.getElementById('md').textContent;
 document.getElementById('out').innerHTML = marked.parse(src);
 document.querySelectorAll('article a').forEach(a=>{
   if(/\\.mp4(\\?|$)/i.test(a.getAttribute('href'))){
     const v=document.createElement('video'); v.controls=true; v.src=a.getAttribute('href');
     v.style.maxWidth='100%'; a.parentNode.replaceChild(v,a);
   }
 });
</script></body></html>'''
# 防止 </script> 提前闭合
out = tpl.replace('__MD__', md_local.replace('</script>', '<\\/script>'))
io.open(os.path.join(base, 'preview.html'), 'w', encoding='utf-8').write(out)
print('preview.html ok')
