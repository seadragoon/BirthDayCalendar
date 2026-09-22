import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/shared/theme/app_theme.dart';

/// アプリのテーマ（きせかえ）状態を管理・永続化するNotifier。
class ThemeNotifier extends AsyncNotifier<AppThemeData> {
  static const _keyType = 'theme_type';
  static const _keyColor = 'theme_primary_color';
  static const _keyCustomBgPath = 'theme_custom_bg_path';
  static const _keyBgOpacity = 'theme_bg_opacity';

  @override
  Future<AppThemeData> build() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 保存された型を取得（デフォルト: standard=0）
    final typeIndex = prefs.getInt(_keyType) ?? AppThemeType.standard.index;
    
    // 保存されたプライマリカラーを取得（デフォルト: ラベンダー）
    final colorValue = prefs.getInt(_keyColor) ?? const Color(0xFF7986CB).toARGB32();

    // 保存されたカスタム背景写真パスと透過度を取得
    final customBgPath = prefs.getString(_keyCustomBgPath);
    final bgOpacity = prefs.getDouble(_keyBgOpacity) ?? 0.80;

    // ファイルが実際に存在するか確認
    String? validCustomBgPath;
    if (customBgPath != null && customBgPath.isNotEmpty) {
      final file = File(customBgPath);
      if (await file.exists()) {
        validCustomBgPath = customBgPath;
      } else {
        // ファイルが見つからない場合はprefsもクリア
        await prefs.remove(_keyCustomBgPath);
      }
    }

    AppThemeData baseTheme;
    if (typeIndex == AppThemeType.standard.index) {
      // 標準テーマ + カスタムカラー
      baseTheme = AppThemeData.standard.copyWith(primaryColor: Color(colorValue));
    } else {
      // きせかえテーマ (桜・夜空など)
      baseTheme = AppThemeData.values.firstWhere(
        (theme) => theme.type.index == typeIndex,
        orElse: () => AppThemeData.standard,
      );
    }

    return baseTheme.copyWith(
      customBackgroundPath: validCustomBgPath,
      backgroundOpacity: bgOpacity,
    );
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

  /// プライマリカラーを更新して保存する（テーマは標準・シンプルホワイトに切り替わる）。
  Future<void> updatePrimaryColor(Color color) async {
    final current = state.valueOrNull ?? AppThemeData.standard;
    final updatedTheme = AppThemeData.standard.copyWith(
      primaryColor: color,
      customBackgroundPath: current.customBackgroundPath,
      backgroundOpacity: current.backgroundOpacity,
    );
    state = AsyncValue.data(updatedTheme);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyType, AppThemeType.standard.index);
    await prefs.setInt(_keyColor, color.toARGB32());
  }

  /// テーマタイプ（標準、桜、夜空など）に基づいてテーマを切り替えて保存する。
  Future<void> setThemeType(AppThemeType type) async {
    final current = state.valueOrNull ?? AppThemeData.standard;
    var theme = AppThemeData.values.firstWhere((t) => t.type == type);

    // 標準テーマに戻す場合は、保存されていたカスタムカラーがあれば反映
    if (type == AppThemeType.standard) {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_keyColor);
      if (colorValue != null) {
        theme = theme.copyWith(primaryColor: Color(colorValue));
      }
    }

    final updatedTheme = theme.copyWith(
      customBackgroundPath: current.customBackgroundPath,
      backgroundOpacity: current.backgroundOpacity,
    );
    await setTheme(updatedTheme);
  }

  /// 端末のアルバムから選択された画像ファイルをアプリの内部ストレージに保存し、背景写真として設定する。
  Future<void> setCustomBackgroundImage(File sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final bgDir = Directory(p.join(docsDir.path, 'theme_bg'));
    if (!await bgDir.exists()) {
      await bgDir.create(recursive: true);
    }

    // 既存の古い写真があれば削除
    final current = state.valueOrNull ?? AppThemeData.standard;
    if (current.customBackgroundPath != null) {
      final oldFile = File(current.customBackgroundPath!);
      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {}
      }
    }

    // 新しい保存先パスを生成してコピー
    final extension = p.extension(sourceFile.path).isNotEmpty ? p.extension(sourceFile.path) : '.jpg';
    final targetPath = p.join(bgDir.path, 'bg_${DateTime.now().millisecondsSinceEpoch}$extension');
    await sourceFile.copy(targetPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomBgPath, targetPath);

    final updated = current.copyWith(customBackgroundPath: targetPath);
    state = AsyncValue.data(updated);
  }

  /// カスタム背景写真を解除（削除）し、元のテーマ背景に戻す。
  Future<void> clearCustomBackgroundImage() async {
    final current = state.valueOrNull ?? AppThemeData.standard;
    if (current.customBackgroundPath != null) {
      final file = File(current.customBackgroundPath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCustomBgPath);

    final updated = current.copyWith(clearCustomBackground: true);
    state = AsyncValue.data(updated);
  }

  /// 背景オーバーレイの不透明度（0.5〜0.95）を更新して保存する。
  Future<void> setBackgroundOpacity(double opacity) async {
    final current = state.valueOrNull ?? AppThemeData.standard;
    final clampedOpacity = opacity.clamp(0.40, 0.95);
    final updated = current.copyWith(backgroundOpacity: clampedOpacity);
    state = AsyncValue.data(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBgOpacity, clampedOpacity);
  }
}

/// 選択中のアプリテーマを提供するProvider。
final themeProvider = AsyncNotifierProvider<ThemeNotifier, AppThemeData>(ThemeNotifier.new);
