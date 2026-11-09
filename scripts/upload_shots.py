"""把模拟器截的图直接推到 GitHub（别走 Codemagic 产物那一层）。

为什么这么干：2026-11-09 那次构建步骤全绿、日志里明明写了
"Wrote screenshot to .../shots/shot_1.png"，但构建产物是 0 个，
截图拿不出来。产物这条路不可靠，就改成"截完自己上传"。

构建时用到的环境变量（由我们触发构建时注入，客户不用配）：
    GH_PAT     有 contents 写权限的 token
    SHOT_REPO  目标仓库，如 owner/DrillTap-site
"""
import base64
import json
import os
import urllib.error
import urllib.request
from pathlib import Path

TOKEN = os.environ.get("GH_PAT", "").strip()
REPO = os.environ.get("SHOT_REPO", "").strip()
SHOTS = Path("shots")

if not (TOKEN and REPO):
    print("没给 GH_PAT / SHOT_REPO，跳过上传")
    raise SystemExit(0)


def api(path, method="GET", payload=None):
    url = "https://api.github.com" + path
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": "Bearer " + TOKEN,
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            body = r.read()
            return json.loads(body) if body.strip().startswith(b"{") else {}
    except urllib.error.HTTPError as e:
        return {"_error": e.code, "_body": e.read()[:200].decode("utf-8", "replace")}


n = 0
for p in sorted(SHOTS.glob("*.png")):
    target = f"docs/shots/{p.name}"
    old = api(f"/repos/{REPO}/contents/{target}")
    sha = old.get("sha") if isinstance(old, dict) else None
    payload = {"message": "capture: " + p.name,
               "content": base64.b64encode(p.read_bytes()).decode(),
               "branch": "main"}
    if sha:
        payload["sha"] = sha
    res = api(f"/repos/{REPO}/contents/{target}", "PUT", payload)
    if res.get("_error"):
        print("上传失败", p.name, res.get("_error"), res.get("_body", "")[:120])
    else:
        print("已上传", target)
        n += 1
print("共上传", n, "张")
