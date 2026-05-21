#!/bin/bash
# 将 BCDramaLib 发布到 GitHub Pod 仓库
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${SDK_DIR:-/Users/a1234/Desktop/BC_Drama/iOSSDK/BCDramaLib}"
REMOTE="git@github.com:Fzzzzzzzz/BCDramaLib.git"
POD_GIT_URL="https://github.com/Fzzzzzzzz/BCDramaLib.git"
VERSION="${1:-1.2.0}"
TAG="v${VERSION}"

echo ">>> 从 ${SDK_DIR} 同步 SDK 产物..."
rm -rf "${SCRIPT_DIR}/BCDramaLib.xcframework" "${SCRIPT_DIR}/BCDramaLib.bundle"
cp -R "${SDK_DIR}/BCDramaLib.xcframework" "${SCRIPT_DIR}/"
cp -R "${SDK_DIR}/BCDramaLib.bundle" "${SCRIPT_DIR}/"

cd "${SCRIPT_DIR}"

if [ ! -d .git ]; then
  GIT_TEMPLATE_DIR="" git init
  git branch -M main
  git remote add origin "${REMOTE}" 2>/dev/null || git remote set-url origin "${REMOTE}"
else
  git remote set-url origin "${REMOTE}"
fi

git add .
if git diff --cached --quiet; then
  echo ">>> 无变更，跳过 commit"
else
  git commit -m "feat: 发布 BCDramaLib ${VERSION}"
fi

git tag -f "${TAG}"
echo ">>> 推送到 ${REMOTE} ..."
git push -u origin main
git push -f origin "${TAG}"

echo ">>> 完成。接入方式："
echo "pod 'BCDramaLib', :git => '${POD_GIT_URL}', :tag => '${TAG}'"
