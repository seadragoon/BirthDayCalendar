import 'dart:convert';

/// アプリ全体の基本設定を管理するモデル。
class AppSettings {
  /// 通知が有効かどうか
  final bool isNotificationsEnabled;

  /// 週の開始日（0: 日曜日, 1: 月曜日）
  final int firstDayOfWeek;

  /// テーマモード (0: system, 1: light, 2: dark)
  final int themeMode;

  const AppSettings({
    this.isNotificationsEnabled = true,
    this.firstDayOfWeek = 0, // デフォルト: 日曜日
    this.themeMode = 1, // デフォルト: オフ（ライト）
  });

  AppSettings copyWith({
    bool? isNotificationsEnabled,
    int? firstDayOfWeek,
    int? themeMode,
  }) {
    return AppSettings(
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNotificationsEnabled': isNotificationsEnabled,
      'firstDayOfWeek': firstDayOfWeek,
      'themeMode': themeMode,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isNotificationsEnabled: map['isNotificationsEnabled'] as bool? ?? true,
      firstDayOfWeek: (map['firstDayOfWeek'] as num?)?.toInt() ?? 0,
      themeMode: (map['themeMode'] as num?)?.toInt() ?? 1,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source));
}
