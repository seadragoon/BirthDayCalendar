import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:birthday_calendar/features/ads/models/ad_config.dart';

/// 広告SDKサービスの抽象インターフェース（テスト時のDI差し替え用）
abstract class AdService {
  /// モバイル広告に対応した環境かつユニットIDが利用可能か
  bool get isAvailable;

  /// SDK初期化済みか
  bool get isInitialized;

  /// 広告SDKを初期化する
  Future<void> initialize();
}

/// Google AdMob (`google_mobile_ads`) の初期化・管理サービス。
class AdMobService implements AdService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();

  bool _isInitialized = false;

  @override
  bool get isAvailable => AdConfig.canLoadBannerAd;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!AdConfig.isSupportedPlatform) {
      debugPrint('[AdMob] 非対応プラットフォームのため初期化をスキップしました。');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('[AdMob] 初期化エラー: $e');
      _isInitialized = false;
    }
  }
}
