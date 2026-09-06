import 'dart:convert';

/// セキュリティ（パスコードロック・生体認証）設定を管理するモデル。
class SecuritySettings {
  /// パスコードロックが有効かどうか
  final bool isPasscodeEnabled;

  /// SHA-256でハッシュ化されたパスコード
  final String? passcodeHash;

  /// ハッシュ生成時に使用した暗号ソルト
  final String? passcodeSalt;

  /// 生体認証（指紋・顔認証）が有効かどうか
  final bool isBiometricEnabled;

  /// バックグラウンド移行後の自動再ロック間隔（秒）。
  /// 0: 即時, 60: 1分, 300: 5分
  final int autoLockIntervalSeconds;

  const SecuritySettings({
    this.isPasscodeEnabled = false,
    this.passcodeHash,
    this.passcodeSalt,
    this.isBiometricEnabled = false,
    this.autoLockIntervalSeconds = 0,
  });

  /// パスコードが有効かつハッシュが存在するか
  bool get hasValidPasscode =>
      isPasscodeEnabled && passcodeHash != null && passcodeSalt != null;

  SecuritySettings copyWith({
    bool? isPasscodeEnabled,
    String? passcodeHash,
    String? passcodeSalt,
    bool? isBiometricEnabled,
    int? autoLockIntervalSeconds,
    bool clearPasscode = false,
  }) {
    return SecuritySettings(
      isPasscodeEnabled:
          clearPasscode ? false : (isPasscodeEnabled ?? this.isPasscodeEnabled),
      passcodeHash: clearPasscode ? null : (passcodeHash ?? this.passcodeHash),
      passcodeSalt: clearPasscode ? null : (passcodeSalt ?? this.passcodeSalt),
      isBiometricEnabled:
          clearPasscode ? false : (isBiometricEnabled ?? this.isBiometricEnabled),
      autoLockIntervalSeconds:
          autoLockIntervalSeconds ?? this.autoLockIntervalSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPasscodeEnabled': isPasscodeEnabled,
      'passcodeHash': passcodeHash,
      'passcodeSalt': passcodeSalt,
      'isBiometricEnabled': isBiometricEnabled,
      'autoLockIntervalSeconds': autoLockIntervalSeconds,
    };
  }

  factory SecuritySettings.fromMap(Map<String, dynamic> map) {
    return SecuritySettings(
      isPasscodeEnabled: map['isPasscodeEnabled'] as bool? ?? false,
      passcodeHash: map['passcodeHash'] as String?,
      passcodeSalt: map['passcodeSalt'] as String?,
      isBiometricEnabled: map['isBiometricEnabled'] as bool? ?? false,
      autoLockIntervalSeconds:
          (map['autoLockIntervalSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SecuritySettings.fromJson(String source) =>
      SecuritySettings.fromMap(jsonDecode(source));
}
