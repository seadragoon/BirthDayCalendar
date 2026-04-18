import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';

/// アプリのテーマ（きせかえ）状態を管理・永続化するNotifier。
class ThemeNotifier extends AsyncNotifier<AppThemeData> {
  static const _keyType = 'theme_type';
  static const _keyColor = 'theme_primary_color';

  @override
  Future<AppThemeData> build() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存された型を取得（デフォルト: standard=0）
    final typeIndex = prefs.getInt(_keyType) ?? AppThemeType.standard.index;
    
    // 保存されたプライマリカラーを取得（デフォルト: ラベンダー）
    final colorValue = prefs.getInt(_keyColor) ?? const Color(0xFF7986CB).toARGB32();

    if (typeIndex == AppThemeType.standard.index) {
      // 標準テーマ + カスタムカラー
      return AppThemeData.standard.copyWith(primaryColor: Color(colorValue));
    } else {
      // きせかえテーマ (桜・夜空など)
      // 他のテーマの場合はカラー設定は無視される
      return AppThemeData.values.firstWhere(
        (theme) => theme.type.index == typeIndex,
        orElse: () => AppThemeData.standard,
      );
    }
  }

  /// 指定したテーマ（データ一式）に変更し保存する。
  Future<void> setTheme(AppThemeData theme) async {
    state = AsyncValue.data(theme);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyType, theme.type.index);
    if (theme.type == AppThemeType.standard) {
      await prefs.setInt(_keyColor, theme.primaryColor.toARGB32());
    }
  }

  /// プライマリカラーを更新して保存する（テーマは標準に切り替わる）。
  Future<void> updatePrimaryColor(Color color) async {
    final updatedTheme = AppThemeData.standard.copyWith(primaryColor: color);
    state = AsyncValue.data(updatedTheme);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyType, AppThemeType.standard.index);
    await prefs.setInt(_keyColor, color.toARGB32());
  }

  /// テーマタイプ（標準、桜、夜空）に基づいてテーマを切り替えて保存する。
  Future<void> setThemeType(AppThemeType type) async {
    final theme = AppThemeData.values.firstWhere((t) => t.type == type);
    await setTheme(theme);
  }
}

/// 選択中のアプリテーマを提供するProvider。
final themeProvider = AsyncNotifierProvider<ThemeNotifier, AppThemeData>(ThemeNotifier.new);
