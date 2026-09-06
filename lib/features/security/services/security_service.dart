import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:birthday_calendar/features/security/models/security_settings.dart';

/// 暗号化ハッシュ処理および生体認証を扱うサービス。
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// ランダムな暗号ソルト文字列を生成する（32文字）。
  String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// パスコードとソルトからSHA-256ハッシュを算出する。
  String hashPasscode(String passcode, String salt) {
    final bytes = utf8.encode('$passcode:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 入力されたパスコードが設定と一致するか検証する。
  bool verifyPasscode(String inputPasscode, SecuritySettings settings) {
    if (!settings.hasValidPasscode) return false;
    final hash = hashPasscode(inputPasscode, settings.passcodeSalt!);
    return hash == settings.passcodeHash;
  }

  /// 端末が生体認証をハードウェア的・設定的に利用可能か確認する。
  Future<bool> isBiometricSupported() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return isDeviceSupported && canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// 利用可能な生体認証リストを取得する。
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// 生体認証（指紋・Face ID）プロンプトを表示して認証を行う。
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'アプリのロックを解除するために認証してください',
  }) async {
    try {
      final isSupported = await isBiometricSupported();
      if (!isSupported) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
