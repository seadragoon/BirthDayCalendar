import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/features/security/models/security_settings.dart';
import 'package:birthday_calendar/features/security/services/security_service.dart';

/// セキュリティ設定を管理する Provider。
final securitySettingsProvider =
    AsyncNotifierProvider<SecuritySettingsNotifier, SecuritySettings>(
  SecuritySettingsNotifier.new,
);

/// セキュリティ設定を管理・永続化する Notifier。
class SecuritySettingsNotifier extends AsyncNotifier<SecuritySettings> {
  static const _key = 'app_security_settings';

  @override
  Future<SecuritySettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return const SecuritySettings();

    try {
      return SecuritySettings.fromJson(json);
    } catch (_) {
      return const SecuritySettings();
    }
  }

  /// 新しいパスコードを設定し、ロックを有効化する。
  Future<void> setPasscode(String pin) async {
    final service = SecurityService.instance;
    final salt = service.generateSalt();
    final hash = service.hashPasscode(pin, salt);

    final current = state.valueOrNull ?? const SecuritySettings();
    final updated = current.copyWith(
      isPasscodeEnabled: true,
      passcodeHash: hash,
      passcodeSalt: salt,
    );

    state = AsyncValue.data(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }

  /// パスコードロックを無効化する。
  Future<void> disablePasscode() async {
    final current = state.valueOrNull ?? const SecuritySettings();
    final updated = current.copyWith(clearPasscode: true);

    state = AsyncValue.data(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }

  /// 生体認証のON/OFFを設定する。
  Future<void> setBiometricEnabled(bool enabled) async {
    final current = state.valueOrNull ?? const SecuritySettings();
    final updated = current.copyWith(isBiometricEnabled: enabled);

    state = AsyncValue.data(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }

  /// 自動再ロック間隔（秒）を設定する。
  Future<void> setAutoLockInterval(int seconds) async {
    final current = state.valueOrNull ?? const SecuritySettings();
    final updated = current.copyWith(autoLockIntervalSeconds: seconds);

    state = AsyncValue.data(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }
}

/// 現在アプリがロック状態かどうかを管理する Notifier。
class AppLockNotifier extends StateNotifier<bool> {
  final Ref ref;
  DateTime? _backgroundTime;
  bool _hasCheckedInitialLock = false;

  AppLockNotifier(this.ref) : super(false) {
    _init();
  }

  void _init() {
    // 初回起動時（コールドスタート時）のみ設定を読み込んでロック判定
    ref.listen<AsyncValue<SecuritySettings>>(securitySettingsProvider, (_, next) {
      if (!_hasCheckedInitialLock && next.hasValue) {
        _hasCheckedInitialLock = true;
        final settings = next.value!;
        if (settings.hasValidPasscode) {
          // アプリコールドスタート時のロック
          state = true;
        }
      }
    }, fireImmediately: true);
  }

  /// ロックを解除する
  void unlock() {
    state = false;
    _backgroundTime = null;
  }

  /// 手動でロックする
  void lock() {
    final settings = ref.read(securitySettingsProvider).valueOrNull;
    if (settings != null && settings.hasValidPasscode) {
      state = true;
    }
  }

  /// アプリがバックグラウンドに移動した時の処理
  void onAppPaused() {
    _backgroundTime = DateTime.now();
  }

  /// アプリがフォアグラウンドに復帰した時の処理
  void onAppResumed() {
    final settings = ref.read(securitySettingsProvider).valueOrNull;
    if (settings == null || !settings.hasValidPasscode) {
      return;
    }

    if (_backgroundTime != null) {
      final elapsed = DateTime.now().difference(_backgroundTime!).inSeconds;
      if (elapsed >= settings.autoLockIntervalSeconds) {
        state = true;
      }
    }
  }
}

/// アプリのロック状態を提供する Provider。
final appLockStateProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  return AppLockNotifier(ref);
});
