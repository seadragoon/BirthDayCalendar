import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/backup/models/backup_data.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/models/tag_model.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';
import 'package:birthday_calendar/shared/services/notification_service.dart';
import 'package:birthday_calendar/features/widget/services/widget_sync_service.dart';

/// バックアップと復元に関するビジネスロジックを提供するサービス。
class BackupService {
  static const String _keyLastBackup = 'last_backup_datetime';

  /// バックアップファイルを作成し、OSの共有シートを開く
  static Future<File> exportBackup({BuildContext? context}) async {
    final db = await DatabaseHelper.instance.database;

    // 1. 全テーブルのデータ取得
    final eventMaps = await db.query(DatabaseHelper.tableEvents);
    final birthdayMaps = await db.query(DatabaseHelper.tableBirthdays);
    final tagMaps = await db.query(DatabaseHelper.tableTags);

    final events = eventMaps.map((m) => EventModel.fromMap(m)).toList();
    final birthdays = birthdayMaps.map((m) => BirthdayModel.fromMap(m)).toList();
    final tags = tagMaps.map((m) => TagModel.fromMap(m)).toList();

    // 2. BackupData 作成
    final now = DateTime.now();
    final backupData = BackupData(
      version: 1,
      app: 'BirthdayCalendar',
      exportedAt: now,
      events: events,
      birthdays: birthdays,
      tags: tags,
    );

    // 3. JSON文字列生成（可読性のためインデント付き）
    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData.toJson());

    // 4. 一時ディレクトリにファイル保存
    final tempDir = await getTemporaryDirectory();
    final fileName = 'birthday_calendar_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonStr, flush: true);

    // 5. 最終バックアップ日時を保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastBackup, now.toIso8601String());

    // 6. 共有シートを開く
    final xFile = XFile(file.path, mimeType: 'application/json', name: fileName);
    final sharePositionOrigin = context != null && context.mounted
        ? () {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              return box.localToGlobal(Offset.zero) & box.size;
            }
            return null;
          }()
        : null;

    await Share.shareXFiles(
      [xFile],
      subject: 'Birthday Calendar バックアップデータ',
      text: 'Birthday Calendar のバックアップデータです。',
      sharePositionOrigin: sharePositionOrigin,
    );

    return file;
  }

  /// ファイルピッカーからJSONバックアップファイルを選択・検証する
  static Future<BackupData?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.single.path;
    if (path == null) return null;

    final file = File(path);
    final content = await file.readAsString();

    final dynamic decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('無効なバックアップファイル形式です。');
    }

    if (decoded['app'] != 'BirthdayCalendar') {
      throw const FormatException('Birthday Calendar のバックアップファイルではありません。');
    }

    return BackupData.fromJson(decoded);
  }

  /// バックアップデータから復元を実行する
  ///
  /// [overwrite]: true の場合は既存データを全消去して上書き復元する。
  ///              false の場合は既存データを保持したまま重複を避けて追加する。
  /// 戻り値: (復元した予定件数, 復元した誕生日件数, 復元したタグ件数)
  static Future<({int eventsCount, int birthdaysCount, int tagsCount})> restoreBackup({
    required BackupData data,
    required bool overwrite,
  }) async {
    final db = await DatabaseHelper.instance.database;

    int restoredEvents = 0;
    int restoredBirthdays = 0;
    int restoredTags = 0;

    await db.transaction((txn) async {
      if (overwrite) {
        // 全消去
        await txn.delete(DatabaseHelper.tableEvents);
        await txn.delete(DatabaseHelper.tableBirthdays);
        await txn.delete(DatabaseHelper.tableTags);

        // タグの復元
        for (final tag in data.tags) {
          await txn.insert(
            DatabaseHelper.tableTags,
            tag.toMap(),
          );
          restoredTags++;
        }

        // 誕生日の復元
        for (final birthday in data.birthdays) {
          await txn.insert(
            DatabaseHelper.tableBirthdays,
            birthday.toMap(),
          );
          restoredBirthdays++;
        }

        // 予定の復元
        for (final event in data.events) {
          await txn.insert(
            DatabaseHelper.tableEvents,
            event.toMap(),
          );
          restoredEvents++;
        }
      } else {
        // 追加復元（重複判定）

        // 1. 既存タグの取得
        final existingTags = await txn.query(DatabaseHelper.tableTags);
        final existingTagNames = existingTags.map((t) => t['name'] as String).toSet();

        for (final tag in data.tags) {
          if (!existingTagNames.contains(tag.name)) {
            final tagMap = tag.toMap()..remove('id'); // AUTOINCREMENTに任せる
            await txn.insert(DatabaseHelper.tableTags, tagMap);
            existingTagNames.add(tag.name);
            restoredTags++;
          }
        }

        // 2. 既存誕生日の取得（名前と月日で重複判定）
        final existingBirthdays = await txn.query(DatabaseHelper.tableBirthdays);
        final existingBirthdayKeys = existingBirthdays.map((b) {
          final name = b['name'] as String;
          final date = DateTime.fromMillisecondsSinceEpoch(b['date'] as int);
          return '$name-${date.month}-${date.day}';
        }).toSet();

        for (final birthday in data.birthdays) {
          final key = '${birthday.name}-${birthday.date.month}-${birthday.date.day}';
          if (!existingBirthdayKeys.contains(key)) {
            final bMap = birthday.toMap()..remove('id');
            await txn.insert(DatabaseHelper.tableBirthdays, bMap);
            existingBirthdayKeys.add(key);
            restoredBirthdays++;
          }
        }

        // 3. 既存予定の取得（タイトル、開始日時、終了日時で重複判定）
        final existingEvents = await txn.query(DatabaseHelper.tableEvents);
        final existingEventKeys = existingEvents.map((e) {
          final title = e['title'] as String;
          final start = e['start_date'] as int;
          final end = e['end_date'] as int;
          return '$title-$start-$end';
        }).toSet();

        for (final event in data.events) {
          final key = '${event.title}-${event.startDate.millisecondsSinceEpoch}-${event.endDate.millisecondsSinceEpoch}';
          if (!existingEventKeys.contains(key)) {
            final eMap = event.toMap()..remove('id');
            await txn.insert(DatabaseHelper.tableEvents, eMap);
            existingEventKeys.add(key);
            restoredEvents++;
          }
        }
      }
    });

    // 通知の再スケジュール
    final allEventsMaps = await db.query(DatabaseHelper.tableEvents);
    final allBirthdaysMaps = await db.query(DatabaseHelper.tableBirthdays);
    final allEvents = allEventsMaps.map((m) => EventModel.fromMap(m)).toList();
    final allBirthdays = allBirthdaysMaps.map((m) => BirthdayModel.fromMap(m)).toList();

    await NotificationService.instance.rescheduleAll(allEvents, allBirthdays);

    // ウィジェットデータを最新状態に同期
    WidgetSyncService.updateAllWidgets();

    return (
      eventsCount: restoredEvents,
      birthdaysCount: restoredBirthdays,
      tagsCount: restoredTags,
    );
  }

  /// 最終バックアップ日時を取得する
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLastBackup);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
