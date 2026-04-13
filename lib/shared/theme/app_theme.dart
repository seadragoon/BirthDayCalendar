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

  /// ベースとなる背景色
  final Color backgroundColor;

  /// メインコンテンツ（カレンダー等のカード）の背景色。
  /// 透明や半透明にして背景色/画像を透けさせる場合に使用。
  final Color surfaceColor;

  const AppThemeData({
    required this.type,
    required this.label,
    required this.backgroundImagePath,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
  });

  static const standard = AppThemeData(
    type: AppThemeType.standard,
    label: '標準（シンプルホワイト）',
    backgroundImagePath: '',
    primaryColor: Color(0xFF42A5F5), // Blue 400
    onPrimaryColor: Colors.white,
    backgroundColor: Colors.white,
    surfaceColor: Colors.white,
  );

  static const sakura = AppThemeData(
    type: AppThemeType.sakura,
    label: '桜（サクラ）',
    backgroundImagePath: 'assets/images/themes/sakura.png',
    primaryColor: Color(0xFFEC407A), // Pink 400
    onPrimaryColor: Colors.white,
    backgroundColor: Color(0xFFFCE4EC), // Pink 50
    surfaceColor: Color(0xCCFFFFFF), // 80% White (slightly transparent)
  );

  static const night = AppThemeData(
    type: AppThemeType.night,
    label: '夜空（ナイト）',
    backgroundImagePath: 'assets/images/themes/night.png',
    primaryColor: Color(0xFF3949AB), // Indigo 600
    onPrimaryColor: Colors.white,
    backgroundColor: Color(0xFFE8EAF6), // Indigo 50
    surfaceColor: Color(0xDDFFFFFF), // 85% White
  );

  static final values = [standard, sakura, night];
}
