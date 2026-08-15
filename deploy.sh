#!/bin/bash
# Deploy K-OS. App.html is the ONE source file; everything else is generated.
#
#   ./deploy.sh "commit message"
#
# What it does:
#   1. stamps a build id into the generated HTML and writes version.txt to match
#      (that pair is what makes phones/desktop auto-refresh — see the auto-update
#      block at the top of App.html's script)
#   2. injects the PWA meta/link tags that only the hosted copy needs
#   3. writes index.html + web/index.html, commits, pushes to GitHub Pages
#   4. re-syncs ASCEND from ../MorningRitual/index.html into ascend/ — it's hosted
#      here (not localhost:8042) specifically so it's reachable from every device,
#      not just the Mac the local dev server happens to be running on
set -e
cd "$(dirname "$0")"

MSG="${1:-Update K-OS}"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ -f "../MorningRitual/index.html" ]; then
  mkdir -p ascend
  cp "../MorningRitual/index.html" ascend/index.html
fi

python3 - "$STAMP" <<'PY'
import sys
stamp = sys.argv[1]
src = open('App.html', encoding='utf-8').read()

anchor = '<meta name="theme-color" content="#0e1116">'
tags = (
'<meta name="apple-mobile-web-app-capable" content="yes">\n'
'<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">\n'
'<meta name="apple-mobile-web-app-title" content="K-OS">\n'
'<meta name="mobile-web-app-capable" content="yes">\n'
'<link rel="manifest" href="manifest.webmanifest">\n'
'<link rel="apple-touch-icon" href="apple-touch-icon.png">\n'
'<link rel="icon" type="image/png" href="icon-192.png">'
)
if src.count(anchor) != 1:
    raise SystemExit('theme-color anchor not found exactly once in App.html')
out = src.replace(anchor, anchor + '\n' + tags, 1)

marker = "const KOS_BUILD='DEV';"
if out.count(marker) != 1:
    raise SystemExit('KOS_BUILD marker not found exactly once in App.html')
out = out.replace(marker, "const KOS_BUILD='%s';" % stamp, 1)

for p in ('index.html', 'web/index.html'):
    open(p, 'w', encoding='utf-8').write(out)
for p in ('version.txt', 'web/version.txt'):
    open(p, 'w', encoding='utf-8').write(stamp + '\n')
print('generated build', stamp)
PY

git add -A index.html web/index.html version.txt web/version.txt ascend/index.html 2>/dev/null || true
git commit -q -m "$MSG

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>" || { echo "nothing to commit"; exit 0; }
git push -q origin HEAD
echo "pushed — build $STAMP live shortly at https://elixara2.github.io/kyrylos/"
