# BCDramaLib

剧星短剧 iOS SDK，通过 CocoaPods 以二进制 XCFramework 分发。

## 要求

- iOS 11.0+
- 仅支持真机（arm64），**不支持模拟器**
- Xcode 14+

## 安装

在宿主工程的 `Podfile` 中添加：

```ruby
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
use_frameworks!

target 'YourApp' do
  pod 'BCDramaLib', :git => 'https://github.com/Fzzzzzzzz/BCDramaLib.git', :tag => 'v1.2.0'
end
```

然后执行：

```bash
pod install --repo-update
```

## 使用

```swift
import BCDramaLib

BCVideoManager.initSDK(appId: "...", packageName: "...", secret: "...", userId: "...") { success in
    // ...
}
```

## 版本

| Tag     | SDK 版本 |
|---------|----------|
| v1.2.0  | 1.2.0    |

## 发布新版本

1. 在 `bc_drama_sdk_ios` 工程根目录执行 `./at.sh` 打包
2. 将 `iOSSDK/BCDramaLib` 下的 `BCDramaLib.xcframework` 与 `BCDramaLib.bundle` 复制到本仓库
3. 更新 `BCDramaLib.podspec` 中的 `s.version` 与 README
4. 提交并打 tag：`git tag vX.Y.Z && git push origin vX.Y.Z`
