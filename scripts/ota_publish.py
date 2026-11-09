#!/usr/bin/env python3
# 把 ad-hoc ipa 推到客户自己的 GitHub Pages，并生成 iOS 直接安装页。
import base64, json, os, pathlib, sys, urllib.request

PAT = os.environ.get('GH_PAT', '')
SITE = os.environ.get('SHOT_REPO', '')
BUNDLE = os.environ.get('BUNDLE_ID', '')
NAME = os.environ.get('APP_NAME', 'App')
VERSION = os.environ.get('APP_VERSION', '1.0')
BUILD = os.environ.get('APP_BUILD', '1')

if not PAT or not SITE:
    print('[ota] 少了 GH_PAT / SHOT_REPO，跳过')
    sys.exit(0)

ipa = next(pathlib.Path('build/ios/ipa').glob('*.ipa'), None)
if ipa is None:
    print('[ota] 没找到 ipa')
    sys.exit(1)
data = ipa.read_bytes()
print('[ota] ipa:', ipa.name, len(data) // 1024, 'KB')

def put(path, content, msg):
    body = {'message': msg, 'branch': 'main',
            'content': base64.b64encode(content).decode()}
    try:
        cur = urllib.request.urlopen(urllib.request.Request(
            'https://api.github.com/repos/' + SITE + '/contents/' + path,
            headers={'Authorization': 'Bearer ' + PAT, 'User-Agent': 'ci'}), timeout=40)
        body['sha'] = json.load(cur)['sha']
    except Exception:
        pass
    req = urllib.request.Request(
        'https://api.github.com/repos/' + SITE + '/contents/' + path,
        data=json.dumps(body).encode(), method='PUT',
        headers={'Authorization': 'Bearer ' + PAT,
                 'Content-Type': 'application/json', 'User-Agent': 'ci'})
    urllib.request.urlopen(req, timeout=240).read()

owner, repo = SITE.split('/')[0], SITE.split('/')[1]
base = 'https://' + owner.lower() + '.github.io/' + repo + '/ota'
put('docs/ota/' + ipa.name, data, 'ota: ' + ipa.name)

manifest = ('<?xml version="1.0" encoding="UTF-8"?>' + chr(10)
            + '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' + chr(10)
            + '<plist version="1.0"><dict><key>items</key><array><dict>' + chr(10)
            + '  <key>assets</key><array><dict>' + chr(10)
            + '    <key>kind</key><string>software-package</string>' + chr(10)
            + '    <key>url</key><string>' + base + '/' + ipa.name + '</string>' + chr(10)
            + '  </dict></array>' + chr(10)
            + '  <key>metadata</key><dict>' + chr(10)
            + '    <key>bundle-identifier</key><string>' + BUNDLE + '</string>' + chr(10)
            + '    <key>bundle-version</key><string>' + VERSION + '</string>' + chr(10)
            + '    <key>kind</key><string>software</string>' + chr(10)
            + '    <key>title</key><string>' + NAME + '</string>' + chr(10)
            + '  </dict></dict></array></dict></plist>')
put('docs/ota/manifest.plist', manifest.encode(), 'ota: manifest')

page = ('<!doctype html><meta charset=utf-8>' + chr(10)
        + '<meta name=viewport content="width=device-width,initial-scale=1">' + chr(10)
        + '<title>Install ' + NAME + '</title>' + chr(10)
        + '<body style="font:16px/1.7 -apple-system,sans-serif;max-width:520px;margin:60px auto;padding:0 20px">' + chr(10)
        + '<h2>Install ' + NAME + '</h2>' + chr(10)
        + '<p>Version ' + VERSION + ' (build ' + BUILD + ')</p>' + chr(10)
        + '<p><a style="display:inline-block;padding:14px 26px;border-radius:12px;background:#1d7a52;color:#fff;text-decoration:none;font-weight:600" href="'
        + 'itms-services://?action=download-manifest&url=' + base + '/manifest.plist'
        + '">Install</a></p>' + chr(10)
        + '<p style=color:#666>If it will not open: Settings - General - VPN &amp; Device Management - trust this developer.</p>' + chr(10)
        + '</body>')
put('docs/ota/index.html', page.encode(), 'ota: install page')
print('[ota] install page:', base + '/')
