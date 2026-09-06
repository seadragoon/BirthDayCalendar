/// アプリ共通のメタデータおよび定数定義クラス。
///
/// アプリ名、バージョン、サポート問い合わせ先、外部URL等を一元管理する。
class AppConstants {
  const AppConstants._();

  /// アプリ表示名
  static const String appName = 'BirthDay Calendar';

  /// アプリバージョン表記
  static const String appVersion = '1.0.0';

  /// 著作権表記
  static const String copyright = '© 2026 BirthDay Calendar Project';

  /// サポート・お問い合わせ先メールアドレス
  static const String supportEmail = 'seadragoon.apps@gmail.com';

  /// お問い合わせメールのデフォルト件名
  static const String supportEmailSubject = '【BirthDay Calendar】お問い合わせ・ご意見';

  /// プライバシーポリシーの最終改定日
  static const String privacyPolicyLastUpdated = '2026年9月6日';

  /// 利用規約の最終改定日
  static const String termsOfServiceLastUpdated = '2026年9月6日';
}
