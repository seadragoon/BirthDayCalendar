import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// デバッグ用のSharedPreferences永続化キー
const String kDebugIsPremiumKey = 'debug_force_is_premium';

/// プレミアム状態（無料 or プレミアム会員）を管理する Notifier。
///
/// 【セキュリティ・安全対策】
/// - [kDebugMode] が false のリリースビルド環境では、安全のためデバッグ設定を一切参照せず
///   常に false（課金接続実装後はストアレシートの検証結果）を返します。
/// - デバッグ環境でのみ SharedPreferences を介して無料/プレミアムの切り替えを即座にシミュレート可能です。
class PremiumNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // リリースビルド時はデバッグ設定を無視して false（課金接続前）を返す
    if (!kDebugMode) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kDebugIsPremiumKey) ?? false;
  }

  /// デバッグ用：プレミアム状態を切り替える（無料 ⇄ プレミアム）
  Future<void> toggleDebugPremium() async {
    if (!kDebugMode) return;

    final current = state.value ?? false;
    await setDebugPremium(!current);
  }

  /// デバッグ用：プレミアム状態を明示的に設定する
  Future<void> setDebugPremium(bool value) async {
    if (!kDebugMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kDebugIsPremiumKey, value);
    state = AsyncData(value);
  }
}

/// ユーザーがプレミアム会員かどうかを判定する Provider。
final isPremiumProvider = AsyncNotifierProvider<PremiumNotifier, bool>(
  PremiumNotifier.new,
);
