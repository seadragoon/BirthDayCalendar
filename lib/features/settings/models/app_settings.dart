import 'dart:convert';
import 'package:birthday_calendar/shared/constants/notification_type.dart';

/// アプリ全体の基本設定を管理するモデル。
class AppSettings {
  /// 通知が有効かどうか
  final bool isNotificationsEnabled;

  /// 週の開始日（0: 日曜日, 1: 月曜日）
  final int firstDayOfWeek;

  /// テーマモード (0: system, 1: light, 2: dark)
  final int themeMode;

  /// 六曜（大安・友引など）を表示するかどうか
  final bool showRokuyo;

  /// 予定作成時のデフォルト終日フラグ
  final bool defaultIsAllDay;

  /// 予定作成時のデフォルトカラー番号 (0〜11, デフォルト: 8 / lavender)
  final int defaultColorIndex;

  /// 予定作成時のデフォルト通知設定
  final List<NotificationType> defaultNotifications;

  const AppSettings({
    this.isNotificationsEnabled = true,
    this.firstDayOfWeek = 0, // デフォルト: 日曜日
    this.themeMode = 1, // デフォルト: オフ（ライト）
    this.showRokuyo = false, // デフォルト: オフ
    this.defaultIsAllDay = false, // デフォルト: OFF
    this.defaultColorIndex = 8, // デフォルト: lavender (8)
    this.defaultNotifications = const [NotificationType.none], // デフォルト: なし
  });

  AppSettings copyWith({
    bool? isNotificationsEnabled,
    int? firstDayOfWeek,
    int? themeMode,
    bool? showRokuyo,
    bool? defaultIsAllDay,
    int? defaultColorIndex,
    List<NotificationType>? defaultNotifications,
  }) {
    return AppSettings(
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      themeMode: themeMode ?? this.themeMode,
      showRokuyo: showRokuyo ?? this.showRokuyo,
      defaultIsAllDay: defaultIsAllDay ?? this.defaultIsAllDay,
      defaultColorIndex: defaultColorIndex ?? this.defaultColorIndex,
      defaultNotifications: defaultNotifications ?? this.defaultNotifications,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNotificationsEnabled': isNotificationsEnabled,
      'firstDayOfWeek': firstDayOfWeek,
      'themeMode': themeMode,
      'showRokuyo': showRokuyo,
      'defaultIsAllDay': defaultIsAllDay,
      'defaultColorIndex': defaultColorIndex,
      'defaultNotifications': defaultNotifications.map((n) => n.index).toList(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    List<NotificationType> notifications = const [NotificationType.none];
    if (map['defaultNotifications'] != null) {
      final rawList = map['defaultNotifications'] as List<dynamic>;
      notifications = rawList
          .map((i) {
            final idx = (i as num).toInt();
            if (idx >= 0 && idx < NotificationType.values.length) {
              return NotificationType.values[idx];
            }
            return NotificationType.none;
          })
          .toList();
    }

    return AppSettings(
      isNotificationsEnabled: map['isNotificationsEnabled'] as bool? ?? true,
      firstDayOfWeek: (map['firstDayOfWeek'] as num?)?.toInt() ?? 0,
      themeMode: (map['themeMode'] as num?)?.toInt() ?? 1,
      showRokuyo: map['showRokuyo'] as bool? ?? false,
      defaultIsAllDay: map['defaultIsAllDay'] as bool? ?? false,
      defaultColorIndex: (map['defaultColorIndex'] as num?)?.toInt() ?? 8,
      defaultNotifications: notifications,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(jsonDecode(source));
}
