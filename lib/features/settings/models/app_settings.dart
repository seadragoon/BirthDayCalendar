import 'dart:convert';

/// アプリ全体の基本設定を管理するモデル。
class AppSettings {
  /// 通知が有効かどうか
  final bool isNotificationsEnabled;

  /// 週の開始日（0: 日曜日, 1: 月曜日）
  final int firstDayOfWeek;

  const AppSettings({
    this.isNotificationsEnabled = true,
    this.firstDayOfWeek = 0, // デフォルト: 日曜日
  });

  AppSettings copyWith({
    bool? isNotificationsEnabled,
    int? firstDayOfWeek,
  }) {
    return AppSettings(
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNotificationsEnabled': isNotificationsEnabled,
      'firstDayOfWeek': firstDayOfWeek,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isNotificationsEnabled: map['isNotificationsEnabled'] as bool? ?? true,
      firstDayOfWeek: (map['firstDayOfWeek'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source));
}
