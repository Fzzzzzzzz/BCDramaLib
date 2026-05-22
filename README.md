# BCDramaLib

剧星短剧 iOS SDK，通过 CocoaPods 分发：**Core 为 XCFramework 二进制**，**广告为可选子模块（源码编译）**。

## 与旧版 (≤1.2.x) 的差异

| 项目 | 旧版 | ≥1.3.0 |
|------|------|--------|
| 广告 SDK | 打进单一 `BCDramaLib.xcframework` | Core 不含广告 SDK |
| 初始化 | `initSDK` 四参数 | 必须传入 `adAdapters: [BCAdAdapter]` |
| 广告平台 | 固定内置 | `AdGDT` / `AdCSJ` / `AdKS` / `AdMSaas` / `AdCustom` 按需引入 |
| Podfile | `use_frameworks!` | 建议 `use_frameworks! :linkage => :static`（穿山甲/芒果为静态 xcframework） |

## 要求

- iOS 11.0+
- Core 仅真机 arm64（**不支持模拟器**）
- Xcode 14+
- 源码工程：`bc_drama_sdk_ios_2`（打包与 Adapter 维护）

## 发布前（维护方）

1. 在 `bc_drama_sdk_ios_2` 根目录执行 `./at.sh`，产出写入 `iOSSDK/BCDramaLib/`
2. 在本仓库执行：

```bash
./publish.sh 1.3.0
# 或仅提交本目录已有产物: SKIP_SYNC=1 ./publish.sh 1.3.0
```

环境变量：

- `SDK_DIR`：Core xcframework 目录，默认 `iOSSDK/BCDramaLib`
- `ADAPTER_SRC_DIR`：Adapter 源码根目录，默认 `bc_drama_sdk_ios_2`

## 宿主安装

```ruby
source 'https://cdn.cocoapods.org/'

platform :ios, '11.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'BCDramaLib/Core', :git => 'https://github.com/Fzzzzzzzz/BCDramaLib.git', :tag => 'v1.3.0'
  pod 'BCDramaLib/AdGDT'
  pod 'BCDramaLib/AdCSJ'
  pod 'BCDramaLib/AdKS'
  pod 'BCDramaLib/AdMSaas'
  pod 'BCDramaLib/AdCustom'   # 使用自定义广告时
  # 或一条: pod 'BCDramaLib/AdsAll', ...
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
```

```bash
pod install --repo-update
```

## 使用

```swift
import BCDramaLib
// Adapter 与 Core 同模块编译时无需额外 import；若拆分为独立 Pod target，import 后类型名不变

let adapters: [BCAdAdapter] = [
    BCGDTAdAdapter(),
    BCCSJAdAdapter(),
    BCKSAdAdapter(),
    BCMSaasAdAdapter(),
    BCCustomAdAdapter()  // 可选
]

BCVideoManager.initSDK(
    appId: "...",
    packageName: Bundle.main.bundleIdentifier ?? "",
    secret: "...",
    userId: "...",
    adAdapters: adapters
) { success in
    // ...
}
```

`adAdapters` 必须覆盖服务端 `mediums` 里会出现的 `ad_platform`，且与已安装的 `BCDramaLib/Ad*` 子模块一致。

## 版本

| Tag     | 说明 |
|---------|------|
| v1.2.x  | 单一二进制，旧版 initSDK |
| v1.3.0  | Core 二进制 + Adapter 子模块 + initSDK 注入 |

## 常见问题

**`transitive dependencies that include statically linked binaries`**

Podfile 不要使用 `:linkage => :dynamic`，请改为 `:linkage => :static`。

**Undefined symbol（SnapKit / CryptoSwift）**

确认 `post_install` 中已设置 `BUILD_LIBRARY_FOR_DISTRIBUTION = YES`，且 Core 依赖版本与 podspec 锁定一致。
