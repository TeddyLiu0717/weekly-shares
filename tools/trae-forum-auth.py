#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
trae-forum-auth.py — 从本机 Trae CN 内嵌浏览器分区(trae-webview)的 Cookies 数据库
提取 forum.trae.cn 的登录 Cookie，供 trae-forum.ps1 使用。

本脚本只读取由 PowerShell 端通过普通拷贝或 VSS 卷影拷贝出的数据库副本，
不访问、不修改原始数据库。支持：
  - value 列明文（当前 Trae CN 39.x Electron 构建的实际情况）
  - encrypted_value 的 v10 (DPAPI+AES-GCM) 兜底（需要 cryptography 包）
用法:
  python trae-forum-auth.py --src <Cookies副本路径> --out <cookie.txt输出路径>
"""
import argparse
import base64
import json
import os
import sqlite3
import sys


def decrypt_v10(blob: bytes, key: bytes) -> str:
    # blob: b'v10' + 12B nonce + ciphertext(含16B tag)
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    nonce, enc = blob[3:15], blob[15:]
    return AESGCM(key).decrypt(nonce, enc, None).decode('utf-8', 'replace')


def dpapi_unprotect(data: bytes) -> bytes:
    import ctypes
    import ctypes.wintypes as wt

    class DATA_BLOB(ctypes.Structure):
        _fields_ = [('cbData', wt.DWORD), ('pbData', ctypes.POINTER(ctypes.c_char))]

    blob_in = DATA_BLOB(len(data), ctypes.cast(ctypes.create_string_buffer(data, len(data)),
                                              ctypes.POINTER(ctypes.c_char)))
    blob_out = DATA_BLOB()
    if not ctypes.windll.crypt32.CryptUnprotectData(
            ctypes.byref(blob_in), None, None, None, None, 0, ctypes.byref(blob_out)):
        raise ctypes.WinError()
    plain = ctypes.string_at(blob_out.pbData, blob_out.cbData)
    ctypes.windll.kernel32.LocalFree(blob_out.pbData)
    return plain


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', required=True)
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    con = sqlite3.connect(args.src)
    cur = con.cursor()
    cur.execute(
        "SELECT name, value, encrypted_value FROM cookies "
        "WHERE host_key='forum.trae.cn' AND name IN ('_t','_forum_session')")
    rows = cur.fetchall()

    key = None
    local_state = os.path.join(os.environ['APPDATA'], 'Trae CN', 'Local State')
    if os.path.exists(local_state):
        try:
            osc = json.load(open(local_state, encoding='utf-8')).get('os_crypt', {})
            raw = base64.b64decode(osc['encrypted_key'])
            if raw.startswith(b'DPAPI'):
                key = dpapi_unprotect(raw[5:])
        except Exception:
            key = None

    parts = []
    for name, value, enc in rows:
        val = value if value else ''
        if not val and enc:
            if enc[:3] == b'v10':
                if not key:
                    print('需要解密 encrypted_value 但 DPAPI 主密钥不可用', file=sys.stderr)
                    sys.exit(3)
                val = decrypt_v10(enc, key)
            else:
                print('不支持的加密前缀: %r' % enc[:4], file=sys.stderr)
                sys.exit(4)
        if val:
            parts.append('%s=%s' % (name, val))

    if not parts or not any(p.startswith('_t=') for p in parts):
        print('未找到 forum.trae.cn 的 _t 登录 Cookie，请先在 Trae 内置浏览器中登录论坛', file=sys.stderr)
        sys.exit(2)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, 'w', encoding='utf-8', newline='') as f:
        f.write('; '.join(parts))
    print('OK ' + ','.join(p.split('=')[0] for p in parts))


if __name__ == '__main__':
    main()
