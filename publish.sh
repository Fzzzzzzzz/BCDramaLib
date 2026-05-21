#!/bin/bash
# 将 BCDramaLib 发布到 GitHub Pod 仓库
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${SDK_DIR:-/Users/a1234/Desktop/BC_Drama/iOSSDK/BCDramaLib}"
REMOTE="git@github.com:Fzzzzzzzz/BCDramaLib.git"
POD_GIT_URL="https://github.com/Fzzzzzzzz/BCDramaLib.git"
VERSION="${1:-1.2.0}"
TAG="v${VERSION}"

if [ "${SKIP_SYNC:-0}" = "1" ]; then
  echo ">>> SKIP_SYNC=1，保留当前目录下的 xcframework / bundle，不从 ${SDK_DIR} 覆盖"
else
  echo ">>> 从 ${SDK_DIR} 同步 SDK 产物（会覆盖本目录已有文件）..."
  rm -rf "${SCRIPT_DIR}/BCDramaLib.xcframework" "${SCRIPT_DIR}/BCDramaLib.bundle"
  cp -R "${SDK_DIR}/BCDramaLib.xcframework" "${SCRIPT_DIR}/"
  cp -R "${SDK_DIR}/BCDramaLib.bundle" "${SCRIPT_DIR}/"
fi

cd "${SCRIPT_DIR}"

if [ ! -d .git ]; then
  GIT_TEMPLATE_DIR="" git init
  git branch -M main
  git remote add origin "${REMOTE}" 2>/dev/null || git remote set-url origin "${REMOTE}"
else
  git remote set-url origin "${REMOTE}"
fi

git add -A
if git diff --cached --quiet; then
  echo ">>> 无变更，跳过 commit"
  echo "    原因：暂存区与最近一次 commit 内容一致。"
  echo "    常见情况："
  echo "      1) 脚本已从 ${SDK_DIR} 覆盖拷贝，且该目录产物与仓库里已提交版本相同；"
  echo "      2) 你替换的 xcframework 与当前 HEAD 二进制相同（可用 shasum 对比）。"
  echo "    若只想提交本目录手动替换的文件，请用: SKIP_SYNC=1 ./publish.sh ${VERSION}"
  git status -sb
else
  echo ">>> 将提交以下变更:"
  git diff --cached --stat
  git commit -m "feat: 发布 BCDramaLib ${VERSION}"
fi

git tag -f "${TAG}"
echo ">>> 推送到 ${REMOTE} ..."
git push -u origin main
git push -f origin "${TAG}"

echo ">>> 完成。接入方式："
echo "pod 'BCDramaLib', :git => '${POD_GIT_URL}', :tag => '${TAG}'"
