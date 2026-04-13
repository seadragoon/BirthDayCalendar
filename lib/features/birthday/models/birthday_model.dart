import 'dart:convert';

import 'package:birthday_calendar/shared/constants/notification_type.dart';

/// 誕生日のデータモデル。
///
/// sqfliteの `birthdays` テーブルと1対1で対応する。
/// [tags] はJSON文字列として保存し、読み込み時にリストに復元する。
class BirthdayModel {
  final int? id;
  final String name;
  final DateTime date;
  final bool isYearUnknown;
  final List<String> tags;
  final NotificationType notification;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BirthdayModel({
    this.id,
    required this.name,
    required this.date,
    this.isYearUnknown = false,
    this.tags = const [],
    this.notification = NotificationType.none,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? date,
        updatedAt = updatedAt ?? date;

  /// 満年齢を計算して返す。
  ///
  /// [isYearUnknown] が true の場合は null を返す。
  /// 誕生日がまだ来ていない年は1歳引いた値を返す。
  int? get age {
    if (isYearUnknown) return null;

    final now = DateTime.now();
    int calculatedAge = now.year - date.year;

    // 今年の誕生日がまだ来ていない場合は1歳引く
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      calculatedAge--;
    }

    return calculatedAge;
  }

  /// 次の誕生日までの日数を返す。
  /// 当日の場合は 0 を返す。
  int get daysUntilNextBirthday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var nextBirthday = DateTime(now.year, date.month, date.day);
    if (nextBirthday.isBefore(today)) {
      nextBirthday = DateTime(now.year + 1, date.month, date.day);
    }

    return nextBirthday.difference(today).inDays;
  }

  /// sqfliteの [Map] からインスタンスを生成する。
  factory BirthdayModel.fromMap(Map<String, dynamic> map) {
    // tagsのJSON文字列をList<String>に変換
    List<String> parsedTags = [];
    if (map['tags'] != null && (map['tags'] as String).isNotEmpty) {
      final decoded = jsonDecode(map['tags'] as String);
      parsedTags = (decoded as List<dynamic>).cast<String>();
    }

    return BirthdayModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      isYearUnknown: (map['is_year_unknown'] as int) == 1,
      tags: parsedTags,
      notification: NotificationType.fromIndex(map['notification'] as int),
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
  /// [tags] はJSON文字列として保存する。
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'date': date.millisecondsSinceEpoch,
      'is_year_unknown': isYearUnknown ? 1 : 0,
      'tags': jsonEncode(tags),
      'notification': notification.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// 一部のフィールドを変更した新しいインスタンスを返す。
  BirthdayModel copyWith({
    int? id,
    String? name,
    DateTime? date,
    bool? isYearUnknown,
    List<String>? tags,
    NotificationType? notification,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BirthdayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      isYearUnknown: isYearUnknown ?? this.isYearUnknown,
      tags: tags ?? this.tags,
      notification: notification ?? this.notification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BirthdayModel(id: $id, name: $name, '
        'date: $date, isYearUnknown: $isYearUnknown, '
        'tags: $tags, age: $age)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BirthdayModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
