#!/bin/bash
# 将 BCDramaLib Core + Adapter XCFramework 发布到 GitHub Pod 仓库
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ./at.sh 默认将 xcframework / bundle 输出到本目录（BCDramaLib-pod）
BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}}"
SDK_DIR="${SDK_DIR:-/Users/a1234/Desktop/BC_Drama/iOSSDK/BCDramaLib}"
REMOTE="git@github.com:Fzzzzzzzz/BCDramaLib.git"
POD_GIT_URL="https://github.com/Fzzzzzzzz/BCDramaLib.git"
VERSION="${1:-1.3.0}"
TAG="v${VERSION}"

FRAMEWORKS=(
  BCDramaLib
  BCDramaAdGDT
  BCDramaAdCSJ
  BCDramaAdKS
  BCDramaAdMSaas
  BCDramaAdCustom
)

resolve_sdk_dir() {
  if [ -f "${BUILD_DIR}/BCDramaLib.xcframework/Info.plist" ]; then
    echo "${BUILD_DIR}"
    return
  fi
  if [ -f "${SDK_DIR}/BCDramaLib.xcframework/Info.plist" ]; then
    echo "${SDK_DIR}"
    return
  fi
  echo "Error: 未找到 BCDramaLib.xcframework，请先在 bc_drama_sdk_ios_2 执行 ./at.sh（产物输出到 BCDramaLib-pod）" >&2
  exit 1
}

if [ "${SKIP_SYNC:-0}" = "1" ]; then
  echo ">>> SKIP_SYNC=1，保留当前目录下的 xcframework / bundle"
else
  SRC="$(resolve_sdk_dir)"
  if [ "$(cd "${SRC}" && pwd)" != "$(cd "${SCRIPT_DIR}" && pwd)" ]; then
    echo ">>> 从 ${SRC} 同步 Core + Adapter xcframework 到 ${SCRIPT_DIR}..."
    for fw in "${FRAMEWORKS[@]}"; do
      if [ ! -d "${SRC}/${fw}.xcframework" ]; then
        echo "Error: 缺少 ${SRC}/${fw}.xcframework"
        exit 1
      fi
      rm -rf "${SCRIPT_DIR}/${fw}.xcframework"
      cp -R "${SRC}/${fw}.xcframework" "${SCRIPT_DIR}/"
    done
    rm -rf "${SCRIPT_DIR}/BCDramaLib.bundle"
    if [ -d "${SRC}/BCDramaLib.bundle" ]; then
      cp -R "${SRC}/BCDramaLib.bundle" "${SCRIPT_DIR}/"
    elif [ -d "${SDK_DIR}/BCDramaLib.bundle" ]; then
      cp -R "${SDK_DIR}/BCDramaLib.bundle" "${SCRIPT_DIR}/"
    else
      RES="${SDK_RESOURCES:-/Users/a1234/Desktop/BC_Drama/bc_drama_sdk_ios_2/BCDramaLib/Resources/BCDramaLib.bundle}"
      if [ -d "${RES}" ]; then
        cp -R "${RES}" "${SCRIPT_DIR}/BCDramaLib.bundle"
      else
        echo "Warning: 未找到 BCDramaLib.bundle，二进制 Pod 可能缺少图片/多语言资源" >&2
      fi
    fi
  else
    echo ">>> 产物已在 ${SCRIPT_DIR}，跳过 xcframework 同步"
    for fw in "${FRAMEWORKS[@]}"; do
      if [ ! -d "${SCRIPT_DIR}/${fw}.xcframework" ]; then
        echo "Error: 缺少 ${SCRIPT_DIR}/${fw}.xcframework，请先执行 ./at.sh"
        exit 1
      fi
    done
    if [ ! -d "${SCRIPT_DIR}/BCDramaLib.bundle" ]; then
      RES="${SDK_RESOURCES:-/Users/a1234/Desktop/BC_Drama/bc_drama_sdk_ios_2/BCDramaLib/Resources/BCDramaLib.bundle}"
      if [ -d "${RES}" ]; then
        cp -R "${RES}" "${SCRIPT_DIR}/BCDramaLib.bundle"
      else
        echo "Warning: 未找到 BCDramaLib.bundle" >&2
      fi
    fi
  fi
  rm -rf "${SCRIPT_DIR}/Sources"
fi

cd "${SCRIPT_DIR}"

if [ ! -d .git ]; then
  GIT_TEMPLATE_DIR="" git init
  git branch -M main
  git remote add origin "${REMOTE}" 2>/dev/null || git remote set-url origin "${REMOTE}"
else
  git remote set-url origin "${REMOTE}"
fi

SWIFT_IFACE="${SCRIPT_DIR}/BCDramaLib.xcframework/ios-arm64/BCDramaLib.framework/Modules/BCDramaLib.swiftmodule/arm64-apple-ios.swiftinterface"
if [ -f "${SWIFT_IFACE}" ]; then
  if ! grep -q 'adAdapters' "${SWIFT_IFACE}" 2>/dev/null; then
    echo "Warning: Core xcframework 中未发现 initSDK(adAdapters:)，请用新版 Core 重新 ./at.sh"
  fi
fi

git add -A
if git diff --cached --quiet; then
  echo ">>> 无变更，跳过 commit"
  git status -sb
else
  git diff --cached --stat
  git commit -m "feat: 发布 BCDramaLib ${VERSION}（Core + Adapter 全量 xcframework）"
fi

git tag -f "${TAG}"
echo ">>> 推送到 ${REMOTE} ..."
git push -u origin main
git push -f origin "${TAG}"

echo ">>> 完成。宿主 Podfile 示例："
cat <<EOF

platform :ios, '11.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'BCDramaLib/Core', :git => '${POD_GIT_URL}', :tag => '${TAG}'
  pod 'BCDramaLib/AdsAll', :git => '${POD_GIT_URL}', :tag => '${TAG}'
end

EOF
