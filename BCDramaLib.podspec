Pod::Spec.new do |s|
  s.name             = 'BCDramaLib'
  s.version          = '1.3.3'
  s.summary          = 'BC Drama iOS SDK (Core + 可选广告 Adapter 二进制)'
  s.description      = <<-DESC
    BCDramaLib Core 与各广告 Adapter 均以 XCFramework 分发。
    Core 不含第三方广告 SDK；按需集成 AdGDT / AdCSJ / AdKS / AdMSaas / AdCustom，
    并在 initSDK 时注入 BCAdAdapter 实现类。
    当前构建仅支持真机 arm64。
  DESC
  s.homepage         = 'https://github.com/Fzzzzzzzz/BCDramaLib'
  s.license          = { :type => 'Proprietary', :text => 'Copyright © BC Drama. All rights reserved.' }
  s.author           = { 'BC Drama' => 'support@example.com' }
  s.source           = { :git => 'https://github.com/Fzzzzzzzz/BCDramaLib.git', :tag => "v#{s.version}" }

  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'
  s.requires_arc     = true
  s.static_framework = true
  s.default_subspec  = 'Core'

  s.subspec 'Core' do |core|
    core.vendored_frameworks = 'BCDramaLib.xcframework'
    core.resources           = 'BCDramaLib.bundle'

    core.dependency 'SnapKit', '5.6.0'
    core.dependency 'CryptoSwift', '1.8.4'
    core.dependency 'SwiftyJSON', '5.0.1'
    core.dependency 'MJRefresh', '3.7.6'
    core.dependency 'TXLiteAVSDK_Professional', '13.2.20652'
    core.dependency 'SDWebImage', '5.21.7'

    core.pod_target_xcconfig = {
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
      'OTHER_LDFLAGS' => '-ObjC'
    }
    core.user_target_xcconfig = {
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
    }
  end

  ad_xcframework = lambda do |spec, xcframework_name, deps|
    spec.vendored_frameworks = "#{xcframework_name}.xcframework"
    spec.dependency 'BCDramaLib/Core'
    deps.each { |d| spec.dependency d }
    spec.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
    }
  end

  s.subspec 'AdGDT' do |gdt|
    ad_xcframework.call(gdt, 'BCDramaAdGDT', ['GDTMobSDK'])
  end

  s.subspec 'AdCSJ' do |csj|
    ad_xcframework.call(csj, 'BCDramaAdCSJ', ['Ads-CN'])
  end

  s.subspec 'AdKS' do |ks|
    ad_xcframework.call(ks, 'BCDramaAdKS', ['KSAdSDK'])
  end

  s.subspec 'AdMSaas' do |ms|
    ad_xcframework.call(ms, 'BCDramaAdMSaas', [
      'MediatomiOS',
      'MediatomiOS/SFAdCsjAdapter',
      'MediatomiOS/SFAdGdtAdapter',
      'MediatomiOS/SFAdKsAdapter'
    ])
  end

  s.subspec 'AdCustom' do |custom|
    ad_xcframework.call(custom, 'BCDramaAdCustom', [])
  end

  s.subspec 'AdsAll' do |all|
    all.dependency 'BCDramaLib/AdGDT'
    all.dependency 'BCDramaLib/AdCSJ'
    all.dependency 'BCDramaLib/AdKS'
    all.dependency 'BCDramaLib/AdMSaas'
    all.dependency 'BCDramaLib/AdCustom'
  end
end
