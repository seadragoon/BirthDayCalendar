import 'package:flutter/material.dart';

/// きせかえ機能用のテーマタイプ。
enum AppThemeType {
  standard,
  sakura,
  night,
}

/// きせかえ機能に必要なデザインデータ（画像パスやメインカラーなど）を定義するモデル。
class AppThemeData {
  final AppThemeType type;
  final String label;

  /// ヘッダーやフッターの背景に使用する画像アセットパス（空文字の場合は画像なし）
  final String backgroundImagePath;

  /// アプリのプライマリカラー
  final Color primaryColor;

  /// ヘッダーテキストなどの文字色
  final Color onPrimaryColor;

  /// ダークモード時のヘッダーテキストなどの文字色
  final Color darkOnPrimaryColor;

  /// ベースとなる背景色
  final Color backgroundColor;

  /// ダークモード時のベースとなる背景色
  final Color darkBackgroundColor;

  /// メインコンテンツ（カレンダー等のカード）の背景色。
  /// 透明や半透明にして背景色/画像を透けさせる場合に使用。
  final Color surfaceColor;

  /// ダークモード時のメインコンテンツの背景色。
  final Color darkSurfaceColor;

  const AppThemeData({
    required this.type,
    required this.label,
    required this.backgroundImagePath,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.darkOnPrimaryColor,
    required this.backgroundColor,
    required this.darkBackgroundColor,
    required this.surfaceColor,
    required this.darkSurfaceColor,
  });

  static const standard = AppThemeData(
    type: AppThemeType.standard,
    label: '標準（シンプルホワイト）',
    backgroundImagePath: '',
    primaryColor: Color(0xFF7986CB), // Lavender (Default: 薄紫)
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Colors.white,
    darkBackgroundColor: Color(0xFF121212),
    surfaceColor: Colors.white,
    darkSurfaceColor: Color(0xFF1E1E1E),
  );

  static const sakura = AppThemeData(
    type: AppThemeType.sakura,
    label: '桜（サクラ）',
    backgroundImagePath: 'assets/images/themes/sakura.png',
    primaryColor: Color(0xFFEC407A), // Pink 400
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFFCE4EC), // Pink 50
    darkBackgroundColor: Color(0xFFAD1457), // Pink 800 (Base for 80% Black overlay)
    surfaceColor: Color(0xCCFFFFFF), // 80% White (slightly transparent)
    darkSurfaceColor: Color(0xCC000000), // 80% Black
  );

  static const night = AppThemeData(
    type: AppThemeType.night,
    label: '夜空（ナイト）',
    backgroundImagePath: 'assets/images/themes/night.png',
    primaryColor: Color(0xFF3949AB), // Indigo 600
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFE8EAF6), // Indigo 50
    darkBackgroundColor: Color(0xFF1A237E), // Indigo 900
    surfaceColor: Color(0xDDFFFFFF), // 85% White
    darkSurfaceColor: Color(0xDD000000), // 85% Black
  );

  static final values = [standard, sakura, night];

  AppThemeData copyWith({
    AppThemeType? type,
    String? label,
    String? backgroundImagePath,
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? darkOnPrimaryColor,
    Color? backgroundColor,
    Color? darkBackgroundColor,
    Color? surfaceColor,
    Color? darkSurfaceColor,
  }) {
    return AppThemeData(
      type: type ?? this.type,
      label: label ?? this.label,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      darkOnPrimaryColor: darkOnPrimaryColor ?? this.darkOnPrimaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      darkSurfaceColor: darkSurfaceColor ?? this.darkSurfaceColor,
    );
  }
}
