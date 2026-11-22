import 'dart:io';
import 'package:flutter/foundation.dart';

/// RevenueCat 課金連携の設定定数。
///
/// APIキーはソースコードに直書きせず、ビルド時の `--dart-define` で注入します。
/// 例:
/// `flutter run --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxxx --dart-define=REVENUECAT_IOS_API_KEY=appl_xxxx`
class PurchaseConfig {
  PurchaseConfig._();

  /// RevenueCat ダッシュボードで設定する Entitlement ID
  static const String entitlementId = 'pro';

  /// Android（Google Play）用 RevenueCat 公開APIキー
  static const String androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  /// iOS（App Store）用 RevenueCat 公開APIキー
  static const String iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );

  /// 現在の実行プラットフォームがモバイル課金（Android / iOS）に対応しているか
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 現在のプラットフォーム用の公開APIキーを返す（未設定時は空文字）
  static String get currentPlatformApiKey {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return androidApiKey;
    if (Platform.isIOS) return iosApiKey;
    return '';
  }

  /// 現在のプラットフォームで有効なAPIキーが設定されているか
  static bool get hasConfiguredApiKey =>
      isSupportedPlatform && currentPlatformApiKey.isNotEmpty;
}
