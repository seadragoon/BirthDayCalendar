import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';

/// アプリのテーマ（きせかえ）状態を管理するNotifier。
///
/// 現状はオンメモリで保持している。
/// 本来は SharedPreferences 等を利用して永続化することが望ましい。
class ThemeNotifier extends Notifier<AppThemeData> {
  @override
  AppThemeData build() {
    // デフォルトテーマ
    return AppThemeData.standard;
  }

  /// 指定したテーマに変更する。
  void setTheme(AppThemeData theme) {
    state = theme;
  }
}

/// 選択中のアプリテーマを提供するProvider。
final themeProvider = NotifierProvider<ThemeNotifier, AppThemeData>(ThemeNotifier.new);
