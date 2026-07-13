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

## 安装

```ruby
source 'https://cdn.cocoapods.org/'

platform :ios, '11.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'BCDramaLib/Core', :git => 'https://github.com/Fzzzzzzzz/BCDramaLib.git', :tag => 'v1.3.4'
  pod 'BCDramaLib/AdGDT'    #可选
  pod 'BCDramaLib/AdCSJ'    #可选
  pod 'BCDramaLib/AdKS'     #可选
  pod 'BCDramaLib/AdMSaas'  #可选
  pod 'BCDramaLib/AdCustom' #可选，使用自定义广告时
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

let adapters: [BCAdAdapter] = [
    BCGDTAdAdapter(),    // 可选
    BCCSJAdAdapter(),    // 可选
    BCKSAdAdapter(),     // 可选
    BCMSaasAdAdapter(),  // 可选
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
| v1.3.1  | 重构广告框架，使用依赖注入的方式配置广告源 |
| v1.3.2  | 优化自定义广告接入；修复用户信息无法更新的问题 |
| v1.3.3  | 优化接口调用 |
| v1.3.4  | 修复优量汇广告导致视频没有声音的问题 |

## 常见问题

**`transitive dependencies that include statically linked binaries`**

Podfile 不要使用 `:linkage => :dynamic`，请改为 `:linkage => :static`。

**Undefined symbol（SnapKit / CryptoSwift）**

确认 `post_install` 中已设置 `BUILD_LIBRARY_FOR_DISTRIBUTION = YES`，且 Core 依赖版本与 podspec 锁定一致。
