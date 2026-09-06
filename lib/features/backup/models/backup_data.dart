import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/models/tag_model.dart';
import 'package:birthday_calendar/features/birthday/models/gift_model.dart';

/// アプリ全体のバックアップデータ構造。
///
/// JSONとしてシリアライズ/デシリアライズされ、
/// 機種変更時の復元やファイル保存に利用される。
class BackupData {
  /// スキーマバージョン（将来の互換性維持用）
  final int version;

  /// アプリ識別子
  final String app;

  /// エクスポート日時
  final DateTime exportedAt;

  /// 予定リスト
  final List<EventModel> events;

  /// 誕生日リスト
  final List<BirthdayModel> birthdays;

  /// タグリスト
  final List<TagModel> tags;

  /// プレゼント・お祝い履歴リスト
  final List<GiftModel> gifts;

  /// 各種設定（任意）
  final Map<String, dynamic>? settings;

  const BackupData({
    this.version = 1,
    this.app = 'BirthdayCalendar',
    required this.exportedAt,
    required this.events,
    required this.birthdays,
    required this.tags,
    this.gifts = const [],
    this.settings,
  });

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'app': app,
      'exported_at': exportedAt.toIso8601String(),
      'data': {
        'events': events.map((e) => e.toMap()).toList(),
        'birthdays': birthdays.map((b) => b.toMap()).toList(),
        'tags': tags.map((t) => t.toMap()).toList(),
        'gifts': gifts.map((g) => g.toMap()).toList(),
        if (settings != null) 'settings': settings,
      },
    };
  }

  /// JSONからの生成
  factory BackupData.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    final app = json['app'] as String? ?? 'BirthdayCalendar';
    final exportedAtStr = json['exported_at'] as String?;
    final exportedAt = exportedAtStr != null
        ? DateTime.tryParse(exportedAtStr) ?? DateTime.now()
        : DateTime.now();

    final data = json['data'] as Map<String, dynamic>? ?? {};

    final rawEvents = (data['events'] as List<dynamic>?) ?? [];
    final events = rawEvents
        .whereType<Map<String, dynamic>>()
        .map((e) => EventModel.fromMap(e))
        .toList();

    final rawBirthdays = (data['birthdays'] as List<dynamic>?) ?? [];
    final birthdays = rawBirthdays
        .whereType<Map<String, dynamic>>()
        .map((b) => BirthdayModel.fromMap(b))
        .toList();

    final rawTags = (data['tags'] as List<dynamic>?) ?? [];
    final tags = rawTags
        .whereType<Map<String, dynamic>>()
        .map((t) => TagModel.fromMap(t))
        .toList();

    final rawGifts = (data['gifts'] as List<dynamic>?) ?? [];
    final gifts = rawGifts
        .whereType<Map<String, dynamic>>()
        .map((g) => GiftModel.fromMap(g))
        .toList();

    final settings = data['settings'] as Map<String, dynamic>?;

    return BackupData(
      version: version,
      app: app,
      exportedAt: exportedAt,
      events: events,
      birthdays: birthdays,
      tags: tags,
      gifts: gifts,
      settings: settings,
    );
  }
}
