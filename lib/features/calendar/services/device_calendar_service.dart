import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:birthday_calendar/features/calendar/models/device_calendar_entry.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';

/// 端末のカレンダー（GoogleカレンダーやiCloudカレンダー等）から予定をスキャン・一括取り込みするサービスクラス。
class DeviceCalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// カレンダーへのアクセス権限をリクエストする
  static Future<bool> requestPermission() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    var permissionsGranted = await _plugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data ?? false)) {
      return true;
    }

    final requestResult = await _plugin.requestPermissions();
    return requestResult.isSuccess && (requestResult.data ?? false);
  }

  /// 端末に登録されているカレンダー一覧を取得する
  static Future<List<Calendar>> getCalendars() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('カレンダーへのアクセス権限が許可されていません。設定から権限を許可してください。');
    }

    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null) {
      throw Exception(result.errors.isNotEmpty ? result.errors.first.errorMessage : 'カレンダー一覧の取得に失敗しました。');
    }

    return result.data!.toList();
  }

  /// 指定したカレンダーおよび期間から予定を取得し、既存予定との重複判定を行ってエントリ一覧を返す
  static Future<List<DeviceCalendarEntry>> fetchEvents({
    required String calendarId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('カレンダーへのアクセス権限が許可されていません。');
    }

    final params = RetrieveEventsParams(
      startDate: startDate,
      endDate: endDate,
    );

    final result = await _plugin.retrieveEvents(calendarId, params);
    if (!result.isSuccess || result.data == null) {
      throw Exception(result.errors.isNotEmpty ? result.errors.first.errorMessage : '予定の取得に失敗しました。');
    }

    // 既存の予定を取得して重複チェック用キーセットを作成
    final db = await DatabaseHelper.instance.database;
    final existingRows = await db.query(DatabaseHelper.tableEvents);
    final Set<String> existingKeys = existingRows.map((row) {
      final title = (row['title'] as String? ?? '').trim();
      final start = row['start_date'] as int;
      final end = row['end_date'] as int;
      return '$title-$start-$end';
    }).toSet();

    final List<DeviceCalendarEntry> entries = [];

    for (final event in result.data!) {
      final title = (event.title ?? '（タイトルなし）').trim();
      final start = event.start?.toLocal() ?? startDate;
      final end = event.end?.toLocal() ?? start;
      final isAllDay = event.allDay ?? false;

      final startMs = start.millisecondsSinceEpoch;
      final endMs = end.millisecondsSinceEpoch;
      final checkKey = '$title-$startMs-$endMs';

      final isDuplicate = existingKeys.contains(checkKey);

      entries.add(
        DeviceCalendarEntry(
          eventId: event.eventId ?? '',
          calendarId: calendarId,
          title: title,
          startDate: start,
          endDate: end,
          isAllDay: isAllDay,
          description: event.description,
          isDuplicate: isDuplicate,
        ),
      );
    }

    // 日時昇順でソート
    entries.sort((a, b) => a.startDate.compareTo(b.startDate));
    return entries;
  }

  /// 選択された予定を一括でアプリのローカルデータベースにインポートする
  static Future<int> importEvents(
    List<DeviceCalendarEntry> entries, {
    EventColor color = EventColor.lavender,
  }) async {
    final toImport = entries.where((e) => e.isSelected).toList();
    if (toImport.isEmpty) return 0;

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final entry in toImport) {
        final event = EventModel(
          title: entry.title,
          startDate: entry.startDate,
          endDate: entry.endDate,
          isAllDay: entry.isAllDay,
          colorIndex: color,
          recurrence: RecurrenceType.none,
          notifications: const [NotificationType.none],
          comment: entry.description ?? '',
          createdAt: now,
          updatedAt: now,
        );

        final map = event.toMap();
        map.remove('id'); // AUTOINCREMENT
        batch.insert(DatabaseHelper.tableEvents, map);
      }

      await batch.commit(noResult: true);
    });

    return toImport.length;
  }
}
