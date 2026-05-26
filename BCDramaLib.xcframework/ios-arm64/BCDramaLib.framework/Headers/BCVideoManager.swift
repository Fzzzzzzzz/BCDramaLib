//
//  BCVideoManager.swift
//  BCDramaLib_Swift
//
//  Created by 傅中正 on 2025/6/6.
//

import Foundation
import TXLiteAVSDK_Professional
import MJRefresh

/// 内容page页
@objc public enum BCTabPageType: Int {
    case collection = 0
    case album = 1
    case recommend = 2
}

/// 商品列表
@objc public enum BCGoodListType: Int {
    case defaults = 0 // sdk自带商品列表面板，数据从后台获取
    case half = 1 // sdk 自带商品列表面板，数据由外层传递进来
    case custom = 2 // 完全自定义商品列表面板，仅需告知支付完成结果，SDK进行支付结果的校验，进行解锁
}

/// 设置开发环境
@objc public enum BCEnvType: Int {
    
    /// 测试环境
    case debug = 0
    
    /// 生产环境
    case release = 1
}

/// 广告显示策略 1、竞价策略（不支持穿山甲） 2、轮循策略  (目前仅支持轮询)
@objc public enum BCStrategyType: Int {
    case bidding = 1
    case round = 2
}

/// 关闭SDK支付功能：0：关闭 1：开启
@objc public enum BCPaymentStatus: Int {
    case off = 0
    case on = 1
}

/// 显示插屏广告的位置页
@objc public enum BCCustomAdPageType: Int {
    case recommendPage // 推荐页
    case newRecommendPage // 新版推荐页
    case playPage // 播放页
    case favorite // 在追页
    case dramas // 剧集页
}

/// 剧单列表类型
@objc public enum BCDramaListType: Int {
    case collection = 0 // 再追列表
    case history = 1 // 历史记录
}

// 是否全屏显示
@objc public enum BCPlayerRenderMode: Int {
    case FILL_SCREEN  = 0 // 图像铺满屏幕，不留黑边，如果图像宽高比不同于屏幕宽高比，部分画面内容会被裁剪掉。
    case FILL_EDGE = 1 // 图像适应屏幕，保持画面完整，但如果图像宽高比不同于屏幕宽高比，会有黑边的存在。
}

/// 半自定义商品面板的数据返回
@objc class BCGoodListData: NSObject {
    @objc var lists: [BCGoodListModel]
    @objc var videoId: Int
    @objc var episodeNo: Int
    
    @objc init(lists: [BCGoodListModel], videoId: Int, episodeNo: Int) {
        self.lists = lists
        self.videoId = videoId
        self.episodeNo = episodeNo
        super.init()
    }
}

/// 自定义商品面板，但使用剧星收款方式支付
@objc class BCGoodPayData: NSObject {
    @objc var selectedData: BCGoodListModel // 选中的商品
    @objc var vc: UIViewController? // 展示支付面板的控制器源
    @objc init(selectedData: BCGoodListModel, vc: UIViewController?) {
        self.selectedData = selectedData
        self.vc = vc
    }
}

public class BCVideoManager: NSObject {
    static let shared = BCVideoManager()
    
    private var videoPlayCallBack = {
        return BCVideoPlayCallBack.shared
    }()
    
    // MARK: - Initialization
    private override init() {}
    
    // 为了方便自己版本的管理，也没有特殊要求，版本号就这样写。
    let sdkVersion = "1.2.0"
}

//MARK: 公共方法
extension BCVideoManager {
    
    /// 初始化SDK
    /// - Parameters:
    ///   - appId: BCVideoSDK的AppId
    ///   - packageName: 包名（bundleId）
    ///   - secret: 签名秘钥
    ///   - userId: app端用户唯一标识
    @objc public static func initSDK(appId: String,
                                     packageName: String,
                                     secret: String,
                                     userId: String,
                                     adAdapters: [BCAdAdapter],
                                     isInitSuccess: @escaping (Bool)->Void) {
        BCAdAdapterRegistry.shared.register(adAdapters)
        BCLoginManager.shared.logout()
        BCLocalizableManager.setDefaultLanguage()
        BCLoginManager.shared.appId = appId
        BCLoginManager.shared.packageName = packageName
        BCLoginManager.shared.secret = secret
        BCLoginManager.shared.userId = userId
        BCLoginManager.shared.updateAdConfig { isLogin, config in
            if (config != nil) {
                initTxVodPlayerSDK(licenceUrl: config!.licenseUrl, key: config!.licenseKey)
            }
            isInitSuccess(isLogin)
        }
        
        // 穿山甲和芒果不支持竞价，暂时写死在这里，后续拿出去
        BCLoginManager.shared.strategtType = .round
    }
    
    /// 退出登录
    @objc public static func logout() {
        BCLoginManager.shared.logout()
    }
    
    /// 进入首页
    /// - Parameters:
    ///   - vc: 来源控制器
    ///   - pageType: page 类型
    @objc public static func showSDK(from vc: UIViewController, pageType: BCTabPageType = .collection) {
        BCPictureInPictureManager.shared.removePictureInPicture()

        let watchingVC = BCDramaFavoriteListViewController()
        watchingVC.topOffset = BCDeviceUtils.getStatusBarHeight() + 44
        let playlistVC = BCDramaMenuListViewController()
        playlistVC.topOffset = BCDeviceUtils.getStatusBarHeight() + 44
        let recommendVC = BCDramaRecommendViewController()
        recommendVC.topOffset = BCDeviceUtils.getStatusBarHeight() + 44
        
        // 设置默认语言
        BCLocalizableManager.setDefaultLanguage()
        
        // 创建标签页控制器
        let tabPageVC = BCTabPageViewController(
            titles: [
                BCLocalizableManager.local("watching"),
                BCLocalizableManager.local("drama_list"),
                BCLocalizableManager.local("recommend"),
            ],
            viewControllers: [watchingVC, playlistVC, recommendVC],
            initIndex: pageType.rawValue
        )
        tabPageVC.hidesBottomBarWhenPushed = true
        
        let navigationController = BCNavigationController(rootViewController: tabPageVC)
        navigationController.modalPresentationStyle = .fullScreen
        vc.present(navigationController, animated: true)
    }
    
    /// 进入在追
    /// - Parameter vc: 来源控制器
    @objc public static func showCollectionPage(from vc: UIViewController) {
        self.showSDK(from: vc, pageType: .collection)
    }
 
    /// 进入剧单
    /// - Parameter vc: 来源控制器
    @objc public static func showAlbumListPage(from vc: UIViewController) {
        self.showSDK(from: vc, pageType: .album)
    }
    
    /// 进入推荐
    /// - Parameter vc: 来源控制器
    @objc public static func showRecommendPage(from vc: UIViewController) {
        self.showSDK(from: vc, pageType: .recommend)
    }
    
    /// 获取首页控制器
    /// - Parameters:
    ///   - pageType: page 类型
    @objc public static func getHomePage(pageType: BCTabPageType = .collection,
                                         topOffset: CGFloat = 44) -> UIViewController {
        let watchingVC = BCDramaFavoriteListViewController()
        watchingVC.topOffset = BCDeviceUtils.getStatusBarHeight() + topOffset
        let playlistVC = BCDramaMenuListViewController()
        playlistVC.topOffset = BCDeviceUtils.getStatusBarHeight() + topOffset
        let recommendVC = BCDramaRecommendViewController()
        recommendVC.topOffset = BCDeviceUtils.getStatusBarHeight() + topOffset
        
        // 创建标签页控制器
        let tabPageVC = BCTabPageViewController(
            titles: [
                BCLocalizableManager.local("watching"),
                BCLocalizableManager.local("drama_list"),
                BCLocalizableManager.local("recommend"),
            ],
            viewControllers: [watchingVC, playlistVC, recommendVC],
            initIndex: pageType.rawValue
        )
        tabPageVC.hideCloseBtn = true
        
        return tabPageVC
    }
    
    /// 获取在追页控制器
    /// - Parameter vc: 来源控制器
    @objc public static func getCollectionPage(topOffset: CGFloat = CGFLOAT_MIN,
                                               topTabBarOffsetY: CGFloat = CGFLOAT_MIN) -> UIViewController {
        let watchingVC = BCDramaFavoriteListViewController()
        if (topOffset != CGFLOAT_MIN) {
            watchingVC.topOffset = topOffset
        }
        if (topTabBarOffsetY != CGFLOAT_MIN) {
            watchingVC.topTabBarOffsetY = topTabBarOffsetY
        }
        return watchingVC;
    }
    
    /// 跳转到在追页控制器, 并设置播放页顶部工具栏Y轴偏移量
    /// - Parameters:
    ///   - vc: 来源控制器
    ///   - topOffset: 在追页偏移量
    ///   - topTabBarOffsetY:设置播放页顶部工具栏的偏移量（优先级高于BCLoginManager.shared.playerTopBarOffsetY）
    @objc public static func toCollectionViewController(from vc: UIViewController,
                                                        topOffset: CGFloat = CGFLOAT_MIN,
                                                        topTabBarOffsetY: CGFloat = CGFLOAT_MIN) {
        let watchingVC = BCDramaFavoriteListViewController()
        if (topOffset != CGFLOAT_MIN) {
            watchingVC.topOffset = topOffset
        }
        if (topTabBarOffsetY != CGFLOAT_MIN) {
            watchingVC.topTabBarOffsetY = topTabBarOffsetY
        }
        if let navController = vc.navigationController {
            navController.pushViewController(watchingVC, animated: true)
        }else {
            watchingVC.modalPresentationStyle = .fullScreen
            vc.present(watchingVC, animated: true)
        }
    }
    
    /// 获取剧单页控制器
    ///   - topOffset: 剧单页偏移量
    ///   - hOffset: 横向偏移量
    ///   - topTabBarOffsetY: 设置播放页顶部工具栏的偏移量（优先级高于BCLoginManager.shared.playerTopBarOffsetY）
    @objc public static func getAlbumListPage(topOffset: CGFloat = CGFLOAT_MIN,
                                              hOffset: CGFloat = CGFLOAT_MIN,
                                              topTabBarOffsetY: CGFloat = CGFLOAT_MIN) -> UIViewController {
        let playlistVC = BCDramaMenuListViewController()
        if (topOffset != CGFLOAT_MIN) {
            playlistVC.topOffset = topOffset
        }
        if (hOffset != CGFLOAT_MIN) {
            playlistVC.hOffset = hOffset
        }
        if (topTabBarOffsetY != CGFLOAT_MIN) {
            playlistVC.topTabBarOffsetY = topTabBarOffsetY
        }

        return playlistVC;
    }
    
    /// 跳转到剧单页控制器, 并设置播放页顶部工具栏Y轴偏移量
    /// - Parameters:
    ///   - topOffset: 剧单页偏移量
    ///   - topTabBarOffsetY: 设置播放页顶部工具栏的偏移量（优先级高于BCLoginManager.shared.playerTopBarOffsetY）
    ///   - vc: 来源控制器
    @objc public static func toAlbumListViewController(from vc: UIViewController,
                                                       topOffset: CGFloat = CGFLOAT_MIN,
                                                       hOffset: CGFloat = CGFLOAT_MIN,
                                                       topTabBarOffsetY: CGFloat = CGFLOAT_MIN) {
        let playlistVC = BCDramaMenuListViewController()
        if (topOffset != CGFLOAT_MIN) {
            playlistVC.topOffset = topOffset
        }
        if (hOffset != CGFLOAT_MIN) {
            playlistVC.hOffset = hOffset
        }
        if (topTabBarOffsetY != CGFLOAT_MIN) {
            playlistVC.topTabBarOffsetY = topTabBarOffsetY
        }
        if let navController = vc.navigationController {
            navController.pushViewController(playlistVC, animated: true)
        }else {
            playlistVC.modalPresentationStyle = .fullScreen
            vc.present(playlistVC, animated: true)
        }
    }
    
    /// 获取推荐页控制器
    /// - Parameter vc: 来源控制器
    /// - Parameter topTabBarOffsetY: 设置播放页顶部工具栏的偏移量（优先级高于BCLoginManager.shared.playerTopBarOffsetY）
    @objc public static func getRecommendPage(topOffset: CGFloat = CGFLOAT_MIN,
                                              topTabBarOffsetY: CGFloat = CGFLOAT_MIN) -> UIViewController {
        let recommendVC = BCDramaRecommendViewController()
        if (topOffset != CGFLOAT_MIN) {
            recommendVC.topOffset = topOffset
        }
        if (topTabBarOffsetY != CGFLOAT_MIN) {
            recommendVC.topTabBarOffsetY = topTabBarOffsetY
        }
        return recommendVC;
    }
    
    /// 跳转到推荐页, 并设置播放页顶部工具栏Y轴偏移量
    /// - Parameters:
    ///   - vc: 来源控制器
    ///   - topOffset: 顶部偏移量
    ///   - topTabBarOffsetY: 设置播放页顶部工具栏的偏移量（优先级高于BCLoginManager.shared.playerTopBarOffsetY）
    @objc public static func toRecommendVc(from vc: UIViewController,
                                           topOffset: CGFloat = CGFLOAT_MIN,
                                           topTabBarOffsetY: CGFloat = CGFLOAT_MIN) {
        let recommendVC = BCDramaRecommendViewController()
        if (topOffset != CGFLOAT_MIN) {
            recommendVC.topOffset = topOffset
        }
        if (topTabBarOffsetY != CGFLOAT_MIN) {
            recommendVC.topTabBarOffsetY = topTabBarOffsetY
        }
        if let navController = vc.navigationController {
            navController.pushViewController(recommendVC, animated: true)
        }else {
            recommendVC.modalPresentationStyle = .fullScreen
            vc.present(recommendVC, animated: true)
        }
    }
    
    /// 设置国际化多语言
    /// - Parameter type: 语言地区类型
    @objc public static func setLanguage(type: BCLanguageType) {
        let _ = BCLocalizableManager.setLanguage(type)

    }
    
    /// 设置视频播放回调
    /// - Parameters:
    ///   - onStart: 开始的回调
    ///   - onProgress: 进度的回调: 参数1：剧集索引，参数2: pageType，参数3：获取当前播放时间 参数4：获取视频总时长 参数5：可播放时长
    ///   - onEnd: 结束的回调
    ///   - onUnlock: 解锁的回调
    ///   - onReward: 奖励的回调
    @objc public static func setVideoPlayCallBack(onStart: BCVideoPlayOnStart?,
                                            onProgress: BCVideoPlayOnProgress?,
                                            onEnd: BCVideoPlayOnEnd?,
                                            onUnlock: BCVideoPlayOnUnlock?,
                                            onReward: BCVideoPlayOnReward?) {
        shared.videoPlayCallBack.onStart = onStart
        shared.videoPlayCallBack.onProgress = onProgress
        shared.videoPlayCallBack.onEnd = onEnd
        shared.videoPlayCallBack.onUnlock = onUnlock
        shared.videoPlayCallBack.onReward = onReward
    }
    
    /// 设置开发环境
    /// 若是手动调用，需要在初始化方法前调用
    /// - Parameter type: 环境类型：0：生产环境， 1：开发环境
    @objc public static func setEnv(type: BCEnvType) {
        NetworkManager.shared.setUpBaseUrl(type)
    }
    
    /// 当短剧SDK里面选择商品点击商品时，调用对应的回调
    /// - Parameter onPayment: 商品参数JSON
    @objc public static func setPaymentCallback(onPayment: BCSetPaymentCallBack?) {
        shared.videoPlayCallBack.onPayment = onPayment
    }
    
    /// 支付设置的回调
    /// - Parameter onPaySuccess: 支付成功后的回调
    @objc public static func setPayment(onPaySuccess: BCPaySuccess?) {
        shared.videoPlayCallBack.onPaySuccess = onPaySuccess
    }
    
    /// 当付款成功后调用此方法通知短剧sdk验证订单付款状态
    /// - Parameter onPaySuccess: 支付成功后的回调
    @objc public static func paymentResultVerify(onPayVerify: BCPayResultVerify?) {
        shared.videoPlayCallBack.payResultVerify = onPayVerify
    }
    
    /// 查询订单支付状态
    /// - Parameter orderNo: 订单号
    /// - Returns: 支付状态
    @objc public static func verifyPaymentResult(orderNo: String,
                                                 retryCount: Int = 0,
                                                 complet: @escaping (Int)->Void) {
        BCPaymentManager.shared.checkPaymentOrder(orderNo, retryCount: retryCount) { checkModel in
            complet(checkModel.payState)
        } failure: { error in
            print("[sdk] query order state faulure, the error is : \(error)")
        }
    }

    /// 取消付款，当用户取消支付时调用此方法。
    /// - Parameter onPayCancle: 取消支付的回调
    @objc public static func paymentCancel(onPayCancle: BCPayCancle?) {
        shared.videoPlayCallBack.onPayCancle = onPayCancle
    }
    
    /// 设置广告加载的回调
    /// - Parameters:
    ///   - onLoaded: 加载成功后的回调
    ///   - onClicked: 广告被点击的回调
    ///   - onEffective: 广告发放奖励后的回调（仅有激励视频有奖励的回调）
    ///   - onClosed: 广告关闭后的回调
    ///   - onFiled: 广告加载失败后的回调
    @objc public static func loadVideoAdCallback(onLoaded: BCAdLoaded?,
                                           onClicked: BCAdClicked?,
                                           onEffective: BCAdDidRewardEffective?,
                                           onClosed: BCAdClosed?,
                                           onFailed: BCAdFailed?) {
        shared.videoPlayCallBack.onAdLoaded = onLoaded
        shared.videoPlayCallBack.onAdClicked = onClicked
        shared.videoPlayCallBack.onAdEffective = onEffective
        shared.videoPlayCallBack.onAdClosed = onClosed
        shared.videoPlayCallBack.onAdFailed = onFailed
    }
    
    /// 设置广告加载的回调
    /// - Parameter onLoaded: 加载成功后的回调
    @objc public static func loadAdvSuccess(onLoaded: BCAdLoaded?) {
        shared.videoPlayCallBack.onAdLoaded = onLoaded
    }
    
    /// 设置广告加载的回调
    /// - Parameter onClicked: 广告被点击的回调
    @objc public static func loadAdvOnClicked(onClicked: BCAdClicked?) {
        shared.videoPlayCallBack.onAdClicked = onClicked
    }
    
    /// 设置广告加载的回调
    /// - Parameter onEffective: 广告发放奖励后的回调（仅有激励视频有奖励的回调）
    @objc public static func loadAdvEffective(onEffective: BCAdDidRewardEffective?) {
        shared.videoPlayCallBack.onAdEffective = onEffective
    }
    
    /// 设置广告加载的回调
    /// - Parameter onClosed: 广告关闭后的回调
    @objc public static func loadAdvOnClosed(onClosed: BCAdClosed?) {
        shared.videoPlayCallBack.onAdClosed = onClosed
    }
    
    /// 设置广告加载的回调
    /// - Parameter onFailed: 广告加载失败后的回调
    @objc public static func loadAdvOnFailed(onFailed: BCAdFailed?) {
        shared.videoPlayCallBack.onAdFailed = onFailed
    }
    
    /// 设置广告加载的回调
    /// - Parameter onFinished: 广告加载完成的回调
    @objc public static func loadAdvOnShowFinished(onFinished: BCAdFinish?) {
        shared.videoPlayCallBack.onAdFinish = onFinished
    }
    
    
    /// 设置广告加载的回调
    /// - Parameter onRender: 信息流广告渲染是否成功的回调
    @objc public static func loadNativeExpressRender(onRender: BCRenderStatus?) {
        shared.videoPlayCallBack.onAdRenderStatus = onRender
    }
    
    /// 自定义广告回调
    /// - Parameters:
    ///   - initAd: 初始化广告
    ///   - rewardAd: 自定义激励广告
    ///   - nativeExpressAd: 自定义信息流广告
    ///   - bannerAd: 自定义banner广告
    @objc public static func setCustomAdvCallback(initAd: BCCustomAdvInit?,
                                            rewardAd: BCCustomAdvReward?,
                                            nativeExpressAd: BCCustomAdvNativeExpress?,
                                            bannerAd: BCCustomAdvBanner?) {
        shared.videoPlayCallBack.initAdCallback = initAd
        shared.videoPlayCallBack.rewardAdCallback = rewardAd
        shared.videoPlayCallBack.nativeExpressAdCallback = nativeExpressAd
        shared.videoPlayCallBack.bannerAdCallback = bannerAd
    }
    
    /// 设置默认播放速度，正常播放传1X，默认为1.25X
    /// 支持 0.75X、1.0X、1.25X、1.5X、2.0X
    ///  - Parameter videoId: 剧ID
    /// - Parameter rate: 播放速率
    @objc public static func setVideoDefaultRate(videoId:Int,
                                                 rate: Double) {
        BCPlayVideoRecord.shared.setVideoRatePreferences(videoId, rate: rate)
    }
    
    /// 剧集解锁是否成功的回调
    /// - Parameter onUnLock: 验证剧集是否解锁后的回调
    @objc public static func onUnLock(onUnLock: BCAdUnLock?) {
        shared.videoPlayCallBack.onAdUnLock = onUnLock
    }
    
    /// 广告播放完成，奖励发放回调
    /// - Parameter onFinish: 广告播放完成后发放奖励的回调
    @objc public static func onAdDidFinish(onFinish: BCAdFinish?) {
        shared.videoPlayCallBack.onAdFinish = onFinish
    }
    
    /// 开始激励视频
    /// - Parameters:
    ///   - vc: 来源控制器
    ///   - videoId: 短剧Id
    ///   - eposodeNo: 剧集索引
    ///   - placementId: 广告位ID
    ///   - extra: 扩展信息
    ///   - onStartReward: 开始激励视频的回调
    ///   - onAdFiled: 激励视频加载失败的回调
    @objc public static func startRewardVideo(form vc: UIViewController,
                                              videoId: Int,
                                              eposodeNo: Int,
                                              placementId: String = "",
                                              extra: [String: Any] = [:],
                                              onStartReward: BCStartAdReward?) {
        BCAdMSaasManager.shared.unLockMotivationVideo(vc, videoId, eposodeNo, placementId, extra, false) { playModel in
            // 直接播放
        } success: { ecmp in
            shared.videoPlayCallBack.onStartAdReward = onStartReward
        } failure: { error in
            print("[sdk] reward video ad was failure, the error is \(error)")
        }
    }
    
    /// 进入播放页
    /// - Parameters:
    ///   - vc: 来源控制器
    ///   - videoId: 剧ID
    ///   - lastEpisodeNo: 播放的剧集索引
    ///   - offsetY: 播放页顶部工具栏的Y轴偏移量
    @objc public static func jumpToVideoPlayController(from vc: UIViewController,
                                                       videoId: Int,
                                                       lastEpisodeNo: Int,
                                                       offsetY: CGFloat = 0) {
        // 设置默认语言
        BCLocalizableManager.setDefaultLanguage()
        let episodeListVC = BCDramaEpisodeListViewController(videoId: videoId, playEpisodeNo: lastEpisodeNo)
        episodeListVC.topTabBarOffsetY = offsetY
        
        if let navController = vc.navigationController {
            episodeListVC.hidesBottomBarWhenPushed = true
            navController.pushViewController(episodeListVC, animated: true)
        }else {
            episodeListVC.modalPresentationStyle = .fullScreen
            vc.present(episodeListVC, animated: true)
        }
    }
    
    /// 进入剧单更多-剧列表
    /// - Parameters:
    ///   - vc: 来源控制器
    ///   - menuId: 剧单ID
    @objc public static func jumpToVideoMoreDetailList(from vc: UIViewController,
                                                       menuId: Int,
                                                       menuName: String) {
        // 设置默认语言
        BCLocalizableManager.setDefaultLanguage()
        
        let menuDetailVC = BCDramaMenuDetailViewController()
        menuDetailVC.menu = BCDramaMenuModel(menuId: menuId, menuName: menuName, list: [])
        if let navController = vc.navigationController {
            navController.pushViewController(menuDetailVC, animated: true)
        }else {
            menuDetailVC.modalPresentationStyle = .fullScreen
            vc.present(menuDetailVC, animated: true)
        }
    }

    /// 收藏记录-(需要先初始化，确保已登录SDK)
    /// - Parameters:
    ///   - page: 页数索引
    ///   - pageSize: 每页多少条收藏记录
    ///   备注：返回值1：数据模型类，返回值2：error
    @objc public static func getCollectionRecords(page: Int,
                                                  pageSize: Int,
                                                  comolete: @escaping ([BCDramaFavoriteListModel]?, String?) -> Void) {
        BCAdAPIManager.shared.getCollectionRecords(page, pageSize, complete: comolete)
    }
    
    /// 获取播放剧集列表接口
    /// - Parameters:
    ///   - page: 页数索引
    ///   - pageSize: 每页多少条收藏记录
    ///   备注：返回值1：数据模型类，返回值2：error
    @objc public static func getHistoryList(page: Int,
                                            pageSize: Int,
                                            comolete: @escaping ([BCDramaFavoriteListModel]?, String?) -> Void) {
        BCAdAPIManager.shared.getHistoryList(page, pageSize, complete: comolete)
    }
        
    /// 是否隐藏播放页的点赞功能
    /// - Parameter isHidden: 是否隐藏（默认：不隐藏）
    @objc public static func hideTheLikeAction(isHidden: Bool) {
        BCLoginManager.shared.isHiddenLikeBtn = isHidden
    }
    
    /// 是否隐藏播放页收藏功能
    /// - Parameter isHidden: 是否隐藏（默认：不隐藏）
    @objc public static func hideTheCollectionAction(isHidden: Bool) {
        BCLoginManager.shared.isHiddenCollectionBtn = isHidden
    }
    
    /// 设置播放器顶部工具栏的Y轴偏移量， 备注：优先级低于直接进入控制器传入的topBarOffsetY
    /// 初始化的时候配置，退出登录的时候会被重置为默认
    /// - Parameter offsetY: Y轴偏移量
    @objc public static func setPlayerTopTabBarOffsetY(offsetY: CGFloat) {
        BCLoginManager.shared.playerTopBarOffsetY = offsetY
    }
    
    /// 关闭SDK支付功能 1： 开启  0：关闭
    /// 初始化的时候配置，退出登录的时候会被重置为默认
    /// - Parameter payment: 是否需要关闭SDK支付功能(默认： 开启)
    @objc public static func setPayActionStatus(payment: BCPaymentStatus) {
        BCLoginManager.shared.paymentStatus = payment
    }
    
    /// 获取SDK版本号（SDK没有特殊要求版本号，这里做便于版本管理的对外函数）
    /// - Returns: 版本号
    @objc public static func getSDKVersion() -> String {
        return BCVideoManager.shared.sdkVersion
    }
    
    /// 设置 播放页 UISlider的左右间距 (已废弃)
    /// - Parameter space: 左右间距
//    @objc public static func setPlayerSliderSpace(space: CGFloat) {
//        BCLoginManager.shared.playerSliderSpace = space
//    }
    
    /// 进入新版SDK的根控制器（默认选中首页）
    /// - Parameter vc: 导航栈
    /// - Parameter selectedIndex: 默认显示第几个导航器（默认仅支持0：首页， 1： 为你推荐页， 2： 我的剧单页）
    @objc public static func goToRootViewController(form vc: UIViewController,
                                                    selectedIndex: Int = 0) -> BCTabBarController {
        let tabBarController = BCTabBarController()
        tabBarController.hidesBottomBarWhenPushed = true
        tabBarController.index = selectedIndex
        tabBarController.onDismiss = { [weak vc] in
            guard let vc = vc else { return }
            if let navController = vc.navigationController {
                print("[sdk] home pop")
                navController.popViewController(animated: true)
            }else {
                print("[sdk] home dismiss")
                vc.dismiss(animated: true)
            }
        }
        if let navController = vc.navigationController {
            navController.pushViewController(tabBarController, animated: true)
        }else {
            tabBarController.modalPresentationStyle = .fullScreen
            vc.present(tabBarController, animated: true)
        }
        return tabBarController
    }

    /// 获取新版推荐页
    /// - Parameters:
    ///   - vc: 外层控制的导航栈
    ///   - toolOffsetY: 播放页顶部工具条的Y轴偏移量
    /// - Returns: 推荐页(备注：与老版本的推荐页是分开的，目的是防止后续推荐页更改样式，同时SDK保留和兼容老版本推荐页)
    @objc public static func getRecommendViewController(form vc: UIViewController,
                                                        toolOffsetY: CGFloat = 0) -> UIViewController {
        let recommendVc = BCRecommendViewController()
        recommendVc.topTabBarOffsetY = toolOffsetY
        recommendVc.parentVc = vc
        let navigationController = BCNavigationController(rootViewController: recommendVc)
        return navigationController
    }
  
    /// 获取新版我的剧集页
    /// - Parameters:
    ///   - vc: 导航栈控制器源
    ///   - isHiddenNav: 是否隐藏SDK自带导航条
    ///   - toolOffsetY: 播放页顶部工具条的Y轴偏移量
    ///   - contentInsert: 内边距
    /// - Returns: 我的剧集页 推荐页(备注：与老版本的剧集页是分开的，目的是防止后续剧集页更改样式，同时SDK保留和兼容老版本剧集页)
    @objc public static func getDramasViewController(form vc: UIViewController,
                                                     isHiddenNav: Bool = true,
                                                     toolOffsetY: CGFloat = 0,
                                                     isHddenEmptyAction: Bool = false,
                                                     contentInsert: UIEdgeInsets = .zero) -> UIViewController {
        let dramasListVc = BCDramasViewController()
        dramasListVc.topTabBarOffsetY = toolOffsetY
        dramasListVc.isHiddenEmptyActionBtn = isHddenEmptyAction
        dramasListVc.parentVc = vc
        dramasListVc.contentInsert = contentInsert
        dramasListVc.isHiddenNav = isHiddenNav
        let navigationController = BCNavigationController(rootViewController: dramasListVc)
        return navigationController
    }
    
    /// 获取新版首页
    /// - Returns: 首页样式改版
    /// - Parameters:
    ///   - vc: 导航栈控制器源
    @objc public static func getHomeViewController(form vc: UIViewController) -> UIViewController {
        let homeVc = BCHomeViewController()
        homeVc.parentVc = vc
        homeVc.onDismiss = { [weak vc] in
            guard let vc = vc else { return }
            if let navController = vc.navigationController {
                print("[sdk] home pop")
                navController.popViewController(animated: true)
            }else {
                print("[sdk] home dismiss")
                vc.dismiss(animated: true)
            }
        }
        let navigationController = BCNavigationController(rootViewController: homeVc)
        return navigationController
    }
    
    /// 自定义播放页剧集封面图占位图 (默认： 不显示占位图)
    /// - Parameter imageName: 播放器封面占位图URL（若imageName为空：则不显示默认占位图,  若imageName不为空，则显示自定义占位图）
    /// 备注：需要将自定义占位图片添加到BCDramaLib的images目录下
    @objc public static func setPlayerCustomCoverPlaceholderImage(imageName: String?) {
        BCLoginManager.shared.playerPlaceholderImageUrl = imageName
    }
    
    /// 进入搜索页
    /// - Parameter vc: 导航栈
    @objc public static func toSearchViewController(form vc: UIViewController) {
        let searchVc = BCSearchViewController()
        if let navController = vc.navigationController {
            navController.pushViewController(searchVc, animated: true)
        }else {
            searchVc.modalPresentationStyle = .fullScreen
            vc.present(searchVc, animated: true)
        }
    }

    /// 点击商品列表的支付回调；备注：若使用自定义的支付方式实现，支付完成后必须调用onPayComplete函数进行订单的查询校验，否则无法解锁剧集
    /// - Parameters:
    ///   - isCustomPayment: 是否使用自定义支付方式（默认：SDK的支付宝、微信等现金支付）, 备注：自定义支付方式一定要设置为true
    ///   - onPay: 点击商品的回调
    @objc public static func onPaymentListener(isCustomPayment: Bool,
                                               onPay: BCGoogListItemCallBack?) {
        BCLoginManager.shared.isCustomPayment = isCustomPayment
        shared.videoPlayCallBack.onCustomPayment = onPay
    }
    
    /// 自定义支付方式支付完成后的订单校验；备注：自定义支付方式支付完成后必须调用该函数进行订单的校验，否则无法解锁剧集
    /// - Parameters:
    ///   - orderNo: 订单号
    ///   - videoId: 剧ID
    ///   - episodeNo: 剧集索引
    @objc public static func onPayComplete(orderNo: String,
                                           videoId: Int,
                                           episodeNo: Int) {
        BCLoginManager.shared.checkPayOrderInfos(orderNo: orderNo, videoId: videoId, episodeNo: episodeNo)
    }
    
    // 停止播放
    /// 防止外层即使离开播放页，没有调用viewDidDisappear这个生命周期函数，导致短剧没有暂停的问题
    @objc public static func pause() {
        BCLoginManager.shared.pausePlayer(true)
    }
    
    // 播放短剧
    @objc public static func play() {
        BCLoginManager.shared.pausePlayer(false)
    }
    
    /// 自定义广告-横幅广告初始化监听
    /// - Parameter onCustomBannerAd: 横幅广告监听的回调
    @objc public static func loadCustomBannerAd(onCustomBannerAd: BCCustomBannerAdsCallBack?) {
        shared.videoPlayCallBack.onCustomBannerAds = onCustomBannerAd
    }
    
    /// 自定义广告-激励视频广告初始化监听
    /// - Parameter onCustomRewardAd: 激励视频监听回调
    @objc public static func loadCustomRewardAd(onCustomRewardAd: BCCustomRewardAdsCallBack?) {
        shared.videoPlayCallBack.onCustomRewardAds = onCustomRewardAd
    }
    
    /// 自定义广告-全屏视频广告初始化监听
    /// - Parameter onCustomFullScreen: 全屏广告监听回调
    @objc public static func loadCustomFullScreenAd(onCustomFullScreen: BCCustomFullScreenAdsCallBack?) {
        shared.videoPlayCallBack.onCustomFullScreenAds = onCustomFullScreen
    }
    
    /// 自定义广告-插屏视频广告初始化监听
    /// - Parameter onCustomFullScreen: 插屏广告监听回调
    @objc public static func initCustomNativeAd(onCustomNative: BCCustomNativeViewAdsCallBack?) {
        shared.videoPlayCallBack.onCustomNativeAds = onCustomNative
    }
    
    /// 加载插屏广告
    /// - Parameters:
    ///   - placementId: 广告位ID
    ///   - adType: 广告类型
    ///   - status: 加载状态
    ///   - pageType: 来源页
    ///   - adView: 广告
    ///   - adContainerView: 展示广告的容器
    ///   - onCustomNative: 监听回调
    @objc public static func loadCustomNativeAd(/*placementId: String, adType: BCAdType, status: BCAdStatues, pageType: BCCustomAdPageType, adView: UIView = UIView(), adContainerView: UIView = UIView(), */onCustomNative: BCCustomNativeViewAdsCallBack?) {
        shared.videoPlayCallBack.onCustomNativeAds = onCustomNative
//        BCLoginManager.shared.customAdsStatusChanged(placementId: placementId, adType: adType, status: status, pageType: pageType, adView: adView, adContainerView: adContainerView)
    }
    
    /// 自定义广告的状态改变监听
    /// - Parameters:
    ///   - adType: 广告类型
    ///   - status: 广告状态
    ///   - pageType: 来源页
    ///   - isEffective: 是否获得奖励（激励视频专属）
    ///   - placementId: 代码位
    ///   - adView: 广告View（不需要的就不传，具体看示例）
    ///   - adContainerView: 展示广告的容器
    @objc public static func customAdStatusChanged(placementId: String, adType: BCAdType, status: BCAdStatues, pageType: BCCustomAdPageType, isEffective: Bool = false, adView: UIView = UIView(), adContainerView: UIView = UIView()) {
        BCLoginManager.shared.customAdsStatusChanged(placementId: placementId, adType: adType, status: status, pageType: pageType, isEffective: isEffective, adView: adView, adContainerView: adContainerView)
    }
    
    /// 监听短剧的收藏状态
    /// - Parameter videoFavorite: 收藏状态（回调参数1：VideoId  回调参数2：收藏状态（ 1-收藏，0-取消收藏））
    @objc public static func getVideoFavoriteStatus(videoFavorite: BCVideoFavoriteCallBack?) {
        shared.videoPlayCallBack.onVideoFavoriteCallBack = videoFavorite
    }
    
    /// 监听短剧的点赞状态
    /// - Parameter videoFavorite: 收藏状态（回调参数1：VideoId  回调参数2：收藏状态（ 1-点赞，0-取消点赞））
    @objc public static func getVideoLikesStatus(videoLikes: BCVideoLikesCallBack?) {
        shared.videoPlayCallBack.onVideoLikesCallBack = videoLikes
    }
    
    /// 获取用户信息
    /// - Parameter comolete: 参数1：用户信息的回调 参数2：错误信息error
    @objc public static func getUserInfos(comolete: @escaping (BCUserInfosModel?, String?) -> Void) {
        BCAdAPIManager.shared.getUserInfs(complete: comolete)
    }
    
    /// 获取已解锁的剧集列表
    /// - Parameter comolete: 参数1：已解锁的剧集列表 参数2：错误信息error
    /// - Parameter page: 页码
    /// - Parameter pageSize: 页数
    @objc public static func getUnlockVideoList(page: Int, pageSize: Int, comolete: @escaping (BCUnlockVideoModel?, String?) -> Void) {
        BCAdAPIManager.shared.getUnlockVideoList(page, pageSize, complete: comolete)
    }
    
    /// 暂停播放器继续缓冲和播放
    @objc public static func pausePlayerBufferingAndPlay() {
        BCLoginManager.shared.pausePlayerBufferingAndPlay()
    }
    
    /// 监听播放器的状态
    /// - Parameter onPlayerStatus: 播放器的状态回调（仅有播放和暂停，若需要其他，请反馈给我）
    @objc public static func playStatus(onPlayerStatus: BCPlayerStatusCallBack?) {
        shared.videoPlayCallBack.onPlayerStatusCallBack = onPlayerStatus
    }
    
    /// 设置短剧是否静音
    /// - Parameter isMute: 是否静音
    @objc public static func setPlayerIsMute(isMute: Bool) {
        BCLoginManager.shared.setPlayerIsMute(isMute: isMute)
    }
    
    /// 监听播放器是否加载成功的回调
    /// - Parameter onPlayerLoadStatus: 回调状态 - 参数1：剧ID（VideoId），参数2：剧索引（episodeNo），参数3：剧是否加载成功（eventId=-1000（剧列表获取失败，一般都是剧下架导致播放失败），eventId=2004（播放事件: 已经开始播放），负数值（除了（-1000））（点播错误: 当eventId值小于0就是播放器点播失败的错误））
    @objc public static func playerLoadStatusListener(onPlayerLoadStatus: BCPlayerLoadStatusCallBack?) {
        shared.videoPlayCallBack.onPlayerLoadStatusCallBack = onPlayerLoadStatus
    }
    
    /// 是否显示分享操作
    /// - Parameter isHidden: 是否显示分享操作（默认隐藏）
    @objc public static func hiddenTheShareAction(isHidden: Bool) {
        BCLoginManager.shared.isHiddenShareBtn = isHidden
    }
    
    /// 监听分享操作的回调
    /// - Parameter onShareVideoCallBack: 分享操作回调
    @objc public static func shareActionListener(onShareVideoCallBack: BCShareVideoCallBack?) {
        shared.videoPlayCallBack.onShareVideoCallBack = onShareVideoCallBack
    }

    /// 获取充值记录列表
    /// - Parameters:
    ///   - page: 页数
    ///   - pageSize: 页码
    ///   - comolete: 回调
    @objc public static func getOrderLists(page: Int, pageSize: Int,  comolete: @escaping (BCPayOrderModel?, String?) -> Void) {
        BCAdAPIManager.shared.getOrderList(page: page, pageSize: pageSize, complete: comolete)
    }
    
    /// 是否隐藏首页导航条上的返回按钮（默认：隐藏）
    /// - Parameter isHidden: 是否隐藏（true: 隐藏， false: 不隐藏）
    @objc public static func hideHomeNavBack(isHidden: Bool) {
        BCLoginManager.shared.isHiddenHomeNavBack = isHidden
    }
 
    /// 强制恢复SDK内部TabBar显示
    /// - Parameter animated: 是否动画
    @objc public static func forceRestoreInternalTabBar(animated: Bool = false) {
        BCTabBarManager.shared.forceRestoreInternalTabBar(animated: animated)
    }
    
    @objc public static func setExternalTabBarController(tabBarVc: UITabBarController) {
        BCTabBarManager.shared.setExternalTabBarController(tabBarVc)
    }
    
    /// 启用/禁用完全隔离模式(默认是隔离的)
    /// - Parameter enabled: 是否启用完全隔离模式
    @objc public static func setCompleteIsolationMode(_ enabled: Bool) {
        BCTabBarManager.shared.isCompleteIsolationMode = enabled
    }
    
    /// 显示SDK内部TabBar
    /// - Parameter animated: 是否动画
    @objc public static func showInternalTabBar(animated: Bool = false) {
        BCTabBarManager.shared.showInternalTabBar(animated: animated)
    }
    
    /// 隐藏SDK内部TabBar
    /// - Parameter animated: 是否动画
    @objc public static func hideInternalTabBar(animated: Bool = false) {
        BCTabBarManager.shared.hideInternalTabBar(animated: animated)
    }
    
    /// 是否自定义商品列表面板
    /// - Parameters:
    ///   - type: 商品列表面板类型（默认：defaults, SDK自带面板，且数据是sdk自己获取, 最原始的样式）; half: 半自定义，商品列表面板使用SDK自带，但数据由外层给SDK；custom: 完全自定义，支付完成后需告知SDK进行校验,
    ///   - onCustomGoodListViewCallBack: 商品列表面板相关数据回调
    @objc public static func customGoodListView(type: BCGoodListType, onCustomGoodListViewCallBack: BCCustomGoodListViewCallBack?) {
        if type == .defaults {
            print("[sdk] 如果您不需要完全自定义或者半自定义，不需要调用该函数，默认模式的意思是商品列表面板和支付都使用SDK自带的")
            return
        }
        BCLoginManager.shared.goodListType = type
        shared.videoPlayCallBack.onCustomGoodListViewCallBack = onCustomGoodListViewCallBack
    }
    
    /// 获取支付商品订单的订单号（自定义支付，在付费前需要创建订单，后续会传给SDK，进行订单的校验）
    /// - Parameters:
    ///   - goodsId: 商品ID
    ///   - videoId:剧ID
    ///   - episodeNo: 剧索引
    ///   - payStrategyId: 支付策略ID
    @objc public static func getGoodOrderNo(goodsId: Int, videoId: Int, episodeNo: Int, payStrategyId: Int, complete: @escaping (String?, String?) -> Void) {
        BCAdAPIManager.shared.getOrderNo(goodsId: goodsId, videoId: videoId, episodeNo: episodeNo, payStrategyId: payStrategyId, complete: complete)
    }
    
    /// 半自定义模式显示商品列表自定义列表
    /// - Parameter goodList: 商品列表模型列表数组
    @objc public static func showGoodListView(goodList: [BCGoodListModel], videoId: Int, episodeNo: Int) {
        if BCLoginManager.shared.goodListType != .half {
            print("[sdk] 仅有半自定义模式才需要调用该函数，半自定义的意思是，商品列表面板使用SDK自带的，但数据外层可能需要进行改造，最后将改造后的数据返回给SDK进行展示和支付使用")
            return
        }
        
        BCLoginManager.shared.wrapGoodListData(list: goodList, videoId: videoId, episodeNo: episodeNo)
    }
    
    /// 完全自定义商品面板，但支付使用剧星收款方式进行解锁视频
    /// - Parameters:
    ///   - goodModel: 选中的商品模型
    ///   - vc: 展示支付面板的控制器源（就是customGoodListView监听函数中SDK传递给您的VC）
    @objc public static func payToUnlockVideo(goodModel: BCGoodListModel, vc: UIViewController?) {
        DispatchQueue.main.async {
            if BCLoginManager.shared.goodListType != .custom {
                print("[sdk] 半自定义或者使用SDK默认面板，则默认是使用剧星支付，如果是完全自定义商品面板，可以选择是否需要使用剧星收款，备注：如果不使用剧星收款，请不要使用该方法")
                return
            }
            BCLoginManager.shared.sdkPay(goodModel: goodModel, vc: vc)
        }
    }
    
    /// 是否启动闪退监控（在初始化之前调用，默认是开启的）
    @objc public static func openCrashMonitoring(isOpenMonitoring: Bool) {
        BCLoginManager.shared.openLogMonitoring = isOpenMonitoring
    }
    
    /// 获取所有的闪退日志
    @objc public static func getAllCrashLogs() -> [String] {
      return  BCCrashManager.shared.getAllCrashLogs()
    }

    /// 获取闪退日志数量
    @objc public static func getCrashLogCount() -> Int {
        return BCCrashManager.shared.getCrashLogCount()
    }

    /// 清除所有闪退日志
    @objc public static func clearAllCrashLogs() {
        BCCrashManager.shared.clearAllCrashLogs()
    }

    /// 上传闪退日志到服务器
    /// - Parameters:
    ///   - logs: 日志内容
    ///   - completion: 完成后的回调(参数1： 上传成功的数量，参数2：上传失败后的回调)
    @objc public static func uploadLogToServer(logs: [String], completion: @escaping (Int, Int) -> Void) {
        BCCrashManager.shared.uploadLogToServer(logs: logs, completion: completion)
    }

    /// 控制小窗口播放器视频是否静音
    /// - Parameter isMute: 是否允许静音（默认: false）
    @objc public static func setPipPlayerMute(isMute: Bool) {
        BCPictureInPictureManager.shared.setPipVideoMute(isMute: isMute)
    }
    
    /// 手动移除小窗播放器的悬浮窗口
    @objc public static func removePipPlayerFloatView() {
        BCPictureInPictureManager.shared.removePictureInPicture()
    }
    
    /// 监听开通会员的回调
    /// - Parameter onPay: 支付的回调
    @objc public static func onRenewListener(onPay: BCGoogListItemCallBack?) {
        shared.videoPlayCallBack.onCustomPayment = onPay
    }
    
    /// 更新用户信息
    @objc public static func updateUserInformations() {
        BCLoginManager.shared.updateUserInfos()
    }
    
    /// 视频播放渲染模式
    /// - Parameter mode: 展示模式
    @objc public static func setPlayerRenderMode(mode: BCPlayerRenderMode) {
        BCLoginManager.shared.playerRenderMode = mode
    }
    
    @objc public static func hideMeSettingBtn(_ isHidden: Bool) {
        BCLoginManager.shared.isHiddenSettingBtn = isHidden
    }
    
    @objc public static func hideMeVipBtn(_ isHidden: Bool) {
        BCLoginManager.shared.isHiddenVipBtn  = isHidden
    }
    
    @objc public static func setCustomUserAvater(_ avater: String?) {
        BCLoginManager.shared.customUserAvater = avater
    }
    
    @objc public static func setCustomUserNickname(_ nickname: String?) {
        BCLoginManager.shared.customUserNickname = nickname
    }
}


//MARK: 私有方法
extension BCVideoManager {
    private static func initTxVodPlayerSDK(licenceUrl: String, key: String) {
        
        TXLiveBase.setConsoleEnabled(false)
        TXLiveBase.setLogLevel(.LOGLEVEL_DEBUG)
        TXLiveBase.setLicenceURL(licenceUrl,key: key)
        
        // 设置视频缓存地址和大小
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let path = paths.first {
            let cachePath = path.appending("/TXCache")
            TXPlayerGlobalSetting.setCacheFolderPath(cachePath)
            TXPlayerGlobalSetting.setMaxCacheSize(500)
        }
    }
}
