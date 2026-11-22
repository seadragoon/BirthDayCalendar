import 'dart:io';
import 'package:flutter/foundation.dart';

/// Google AdMob 広告連携の設定定数。
///
/// 本番用の広告ユニットIDはソースコードに直書きせず、`--dart-define` で注入します。
/// 例:
/// `flutter build appbundle --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-xxxx/yyyy`
///
/// 【ポリシー違反防止ガード】
/// - デバッグビルド（`kDebugMode == true`）では、誤クリックによるAdMobアカウント停止を防ぐため
///   常に Google 公式のテスト用バナー広告ユニットIDを使用します。
class AdConfig {
  AdConfig._();

  /// Google 公式テスト用バナー広告ユニットID（Android）
  static const String testAndroidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  /// Google 公式テスト用バナー広告ユニットID（iOS）
  static const String testIosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  /// 本番用バナー広告ユニットID（Android: `--dart-define` 注入）
  static const String prodAndroidBannerAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
  );

  /// 本番用バナー広告ユニットID（iOS: `--dart-define` 注入）
  static const String prodIosBannerAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
  );

  /// 現在の実行プラットフォームがモバイル広告（Android / iOS）に対応しているか
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 現在の環境・プラットフォームで使用するバナー広告ユニットIDを返す。
  /// 非対応プラットフォームや本番ID未設定時は空文字を返します。
  static String get bannerAdUnitId {
    if (!isSupportedPlatform) return '';

    if (kDebugMode) {
      return Platform.isAndroid
          ? testAndroidBannerAdUnitId
          : testIosBannerAdUnitId;
    }

    return Platform.isAndroid
        ? prodAndroidBannerAdUnitId
        : prodIosBannerAdUnitId;
  }

  /// バナー広告をリクエスト可能な状態か
  static bool get canLoadBannerAd => bannerAdUnitId.isNotEmpty;
}
