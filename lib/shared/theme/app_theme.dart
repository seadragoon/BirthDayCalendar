import 'package:flutter/material.dart';

/// きせかえ機能用のテーマタイプ。
enum AppThemeType {
  standard,
  sakura,
  night,
  mint,
  cafe,
  sunset,
  rose,
  ocean,
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

  /// ユーザーがフォトライブラリから設定したカスタム背景写真のファイルパス（nullの場合はなし）
  final String? customBackgroundPath;

  /// カレンダー背景のオーバーレイ不透明度（0.5〜0.95、デフォルト: 0.80）
  final double backgroundOpacity;

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
    this.customBackgroundPath,
    this.backgroundOpacity = 0.80,
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
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
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
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  /// このテーマがプレミアム限定テーマかどうかを判定
  bool get isPremium =>
      type == AppThemeType.mint ||
      type == AppThemeType.cafe ||
      type == AppThemeType.sunset ||
      type == AppThemeType.rose ||
      type == AppThemeType.ocean;

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
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  static const mint = AppThemeData(
    type: AppThemeType.mint,
    label: 'ミント（ボタニカル）',
    backgroundImagePath: 'assets/images/themes/mint.jpg',
    primaryColor: Color(0xFF26A69A), // Teal 400
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFE0F2F1), // Teal 50
    darkBackgroundColor: Color(0xFF004D40), // Teal 900
    surfaceColor: Color(0xCCFFFFFF), // 80% White
    darkSurfaceColor: Color(0xCC000000), // 80% Black
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  static const cafe = AppThemeData(
    type: AppThemeType.cafe,
    label: 'モカ（カフェ）',
    backgroundImagePath: 'assets/images/themes/cafe.jpg',
    primaryColor: Color(0xFF8D6E63), // Brown 400
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFEFEBE9), // Brown 50
    darkBackgroundColor: Color(0xFF3E2723), // Brown 900
    surfaceColor: Color(0xCCFFFFFF), // 80% White
    darkSurfaceColor: Color(0xCC000000), // 80% Black
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  static const sunset = AppThemeData(
    type: AppThemeType.sunset,
    label: '夕暮れ（サンセット）',
    backgroundImagePath: 'assets/images/themes/sunset.jpg',
    primaryColor: Color(0xFFFF7043), // Deep Orange 400
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFFBE9E7), // Deep Orange 50
    darkBackgroundColor: Color(0xFF311B92), // Deep Purple 900 (Twilight)
    surfaceColor: Color(0xCCFFFFFF), // 80% White
    darkSurfaceColor: Color(0xCC000000), // 80% Black
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  static const rose = AppThemeData(
    type: AppThemeType.rose,
    label: 'ローズ（エレガント）',
    backgroundImagePath: 'assets/images/themes/rose.jpg',
    primaryColor: Color(0xFFC2185B), // Pink 700
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFFCE4EC), // Pink 50
    darkBackgroundColor: Color(0xFF880E4F), // Pink 900
    surfaceColor: Color(0xCCFFFFFF), // 80% White
    darkSurfaceColor: Color(0xCC000000), // 80% Black
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  static const ocean = AppThemeData(
    type: AppThemeType.ocean,
    label: '海（オーシャン）',
    backgroundImagePath: 'assets/images/themes/ocean.jpg',
    primaryColor: Color(0xFF00ACC1), // Cyan 600
    onPrimaryColor: Colors.white,
    darkOnPrimaryColor: Colors.white70,
    backgroundColor: Color(0xFFE0F7FA), // Cyan 50
    darkBackgroundColor: Color(0xFF006064), // Cyan 900
    surfaceColor: Color(0xCCFFFFFF), // 80% White
    darkSurfaceColor: Color(0xCC000000), // 80% Black
    customBackgroundPath: null,
    backgroundOpacity: 0.80,
  );

  static final values = [
    standard,
    sakura,
    night,
    mint,
    cafe,
    sunset,
    rose,
    ocean,
  ];

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
    String? customBackgroundPath,
    bool clearCustomBackground = false,
    double? backgroundOpacity,
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
      customBackgroundPath: clearCustomBackground ? null : (customBackgroundPath ?? this.customBackgroundPath),
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }
}

