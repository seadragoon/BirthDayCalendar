import 'dart:convert';

import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';

/// カレンダーに表示するイベント（予定）のデータモデル。
///
/// sqfliteの `events` テーブルと1対1で対応する。
/// [isBirthday] が true の場合は誕生日に紐づくイベントであることを示す。
class EventModel {
  final int? id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final EventColor colorIndex;
  final RecurrenceType recurrence;
  final List<NotificationType> notifications;
  final String comment;
  final bool isBirthday;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isAllDay = false,
    this.colorIndex = EventColor.peacock,
    this.recurrence = RecurrenceType.none,
    this.notifications = const [NotificationType.none],
    this.comment = '',
    this.isBirthday = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? startDate,
        updatedAt = updatedAt ?? startDate;

  /// sqfliteの [Map] からインスタンスを生成する。
  factory EventModel.fromMap(Map<String, dynamic> map) {
    // notifications の解析
    List<NotificationType> parsedNotifications = [NotificationType.none];
    if (map['notification'] != null && (map['notification'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['notification'] as String) as List<dynamic>;
        parsedNotifications = decoded.map((e) => NotificationType.fromIndex(e as int)).toList();
      } catch (_) {
        // フォールバック
        parsedNotifications = [NotificationType.none];
      }
    }

    return EventModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      isAllDay: (map['is_all_day'] as int) == 1,
      colorIndex: EventColor.fromIndex(map['color_index'] as int),
      recurrence: RecurrenceType.fromIndex(map['recurrence'] as int),
      notifications: parsedNotifications,
      comment: (map['comment'] as String?) ?? '',
      isBirthday: (map['is_birthday'] as int) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// sqflite保存用の [Map] に変換する。
  ///
  /// [id] が null の場合（新規作成）はMapに含めず、
  /// sqfliteの AUTOINCREMENT に任せる。
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'is_all_day': isAllDay ? 1 : 0,
      'color_index': colorIndex.index,
      'recurrence': recurrence.index,
      'notification': jsonEncode(notifications.map((e) => e.index).toList()),
      'comment': comment,
      'is_birthday': isBirthday ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// 一部のフィールドを変更した新しいインスタンスを返す。
  EventModel copyWith({
    int? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    EventColor? colorIndex,
    RecurrenceType? recurrence,
    List<NotificationType>? notifications,
    String? comment,
    bool? isBirthday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      colorIndex: colorIndex ?? this.colorIndex,
      recurrence: recurrence ?? this.recurrence,
      notifications: notifications ?? this.notifications,
      comment: comment ?? this.comment,
      isBirthday: isBirthday ?? this.isBirthday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, '
        'startDate: $startDate, endDate: $endDate, '
        'isAllDay: $isAllDay, colorIndex: $colorIndex, '
        'isBirthday: $isBirthday)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
