Pod::Spec.new do |s|
  s.name             = 'BCDramaLib'
  s.version          = '1.2.0'
  s.summary          = 'BC Drama iOS SDK (binary XCFramework)'
  s.description      = <<-DESC
    BCDramaLib 为剧星短剧 iOS SDK，以 XCFramework 二进制形式分发。
    当前构建仅包含真机 arm64，不支持 iOS 模拟器。
  DESC
  s.homepage         = 'https://github.com/Fzzzzzzzz/BCDramaLib'
  s.license          = { :type => 'Proprietary', :text => 'Copyright © BC Drama. All rights reserved.' }
  s.author           = { 'BC Drama' => 'support@example.com' }
  s.source           = { :git => 'https://github.com/Fzzzzzzzz/BCDramaLib.git', :tag => "v#{s.version}" }

  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'
  s.requires_arc     = true
  s.static_framework = true

  s.vendored_frameworks = 'BCDramaLib.xcframework'
  s.resources           = 'BCDramaLib.bundle'

  # 版本须与打包 bc_drama_sdk_ios 时 Podfile.lock 一致，否则静态库会出现 Undefined symbol
  s.dependency 'SnapKit', '5.6.0'
  s.dependency 'CryptoSwift', '1.8.4'
  s.dependency 'SwiftyJSON', '5.0.1'
  s.dependency 'MJRefresh', '3.7.6'
  s.dependency 'TXLiteAVSDK_Professional', '13.2.20652'
  s.dependency 'SDWebImage', '5.21.7'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'OTHER_LDFLAGS' => '-ObjC'
  }
  s.user_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
