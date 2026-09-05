import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';

/// iCalendar（.ics）形式の生成およびエクスポートを行うサービス。
///
/// Googleカレンダー、Yahoo!カレンダー、Appleカレンダー、Outlook等の
/// 外部カレンダーサービスに予定や誕生日を取り込むための標準規格を生成する。
class ICalendarService {
  /// DBから全データを取得し、.icsファイルを生成して共有シートを開く
  static Future<File> exportIcs({BuildContext? context}) async {
    final db = await DatabaseHelper.instance.database;

    final eventMaps = await db.query(DatabaseHelper.tableEvents);
    final birthdayMaps = await db.query(DatabaseHelper.tableBirthdays);

    final events = eventMaps.map((m) => EventModel.fromMap(m)).toList();
    final birthdays = birthdayMaps.map((m) => BirthdayModel.fromMap(m)).toList();

    // ICSコンテンツ生成
    final icsContent = generateIcsContent(events, birthdays);

    // 一時ファイルに書き出し
    final now = DateTime.now();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'birthday_calendar_export_${DateFormat('yyyyMMdd_HHmmss').format(now)}.ics';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(icsContent, flush: true);

    // 共有シートを開く
    final xFile = XFile(file.path, mimeType: 'text/calendar', name: fileName);
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
      subject: 'カレンダー予定データ (.ics)',
      text: 'Birthday Calendar からエクスポートしたカレンダーデータです。',
      sharePositionOrigin: sharePositionOrigin,
    );

    return file;
  }

  /// 予定と誕生日をiCalendar形式（RFC 5545）の文字列に変換する
  static String generateIcsContent(List<EventModel> events, List<BirthdayModel> birthdays) {
    final buffer = StringBuffer();
    const crlf = '\r\n';

    // VCALENDAR ヘッダー
    buffer.write('BEGIN:VCALENDAR$crlf');
    buffer.write('VERSION:2.0$crlf');
    buffer.write('PRODID:-//Birthday Calendar//JA$crlf');
    buffer.write('CALSCALE:GREGORIAN$crlf');
    buffer.write('METHOD:PUBLISH$crlf');
    buffer.write('X-WR-CALNAME:Birthday Calendar$crlf');

    final dateStamp = _formatIcsDateTime(DateTime.now());

    // 1. 予定（events）の変換
    for (final event in events) {
      // 誕生日連動の仮想予定は除外（誕生日側で直接出力するため）
      if (event.isBirthday) continue;

      buffer.write('BEGIN:VEVENT$crlf');
      buffer.write('UID:${event.id ?? DateTime.now().millisecondsSinceEpoch}-event@birthdaycalendar.app$crlf');
      buffer.write('DTSTAMP:$dateStamp$crlf');

      final title = _escapeText(event.icon != null ? '${event.icon} ${event.title}' : event.title);
      buffer.write('SUMMARY:$title$crlf');

      if (event.comment.isNotEmpty) {
        buffer.write('DESCRIPTION:${_escapeText(event.comment)}$crlf');
      }

      if (event.isAllDay) {
        // 終日イベント: VALUE=DATE
        final dtStart = _formatIcsDate(event.startDate);
        // iCalendar仕様では終日終了日は翌日を指定
        final dtEnd = _formatIcsDate(event.endDate.add(const Duration(days: 1)));
        buffer.write('DTSTART;VALUE=DATE:$dtStart$crlf');
        buffer.write('DTEND;VALUE=DATE:$dtEnd$crlf');
      } else {
        // 時間指定イベント
        buffer.write('DTSTART:${_formatIcsDateTime(event.startDate)}$crlf');
        buffer.write('DTEND:${_formatIcsDateTime(event.endDate)}$crlf');
      }

      // 繰り返しルールの変換
      final rrule = _buildRrule(event.recurrence);
      if (rrule != null) {
        buffer.write('RRULE:$rrule$crlf');
      }

      buffer.write('END:VEVENT$crlf');
    }

    // 2. 誕生日（birthdays）の変換
    for (final birthday in birthdays) {
      buffer.write('BEGIN:VEVENT$crlf');
      buffer.write('UID:${birthday.id ?? DateTime.now().millisecondsSinceEpoch}-bday@birthdaycalendar.app$crlf');
      buffer.write('DTSTAMP:$dateStamp$crlf');

      final summary = _escapeText('🎂 ${birthday.name}の誕生日');
      buffer.write('SUMMARY:$summary$crlf');

      final descBuffer = StringBuffer();
      if (!birthday.isYearUnknown) {
        descBuffer.write('生まれ年: ${birthday.date.year}年\\n');
      }
      if (birthday.tags.isNotEmpty) {
        descBuffer.write('タグ: ${birthday.tags.join(', ')}\\n');
      }
      if (birthday.comment.isNotEmpty) {
        descBuffer.write('メモ: ${birthday.comment}\\n');
      }
      if (descBuffer.isNotEmpty) {
        buffer.write('DESCRIPTION:${descBuffer.toString()}$crlf');
      }

      // 終日イベントとして設定（開始年は登録されている年、未設定なら当年）
      final dtStart = _formatIcsDate(birthday.date);
      final dtEnd = _formatIcsDate(birthday.date.add(const Duration(days: 1)));
      buffer.write('DTSTART;VALUE=DATE:$dtStart$crlf');
      buffer.write('DTEND;VALUE=DATE:$dtEnd$crlf');

      // 毎年繰り返し
      buffer.write('RRULE:FREQ=YEARLY$crlf');

      buffer.write('END:VEVENT$crlf');
    }

    // VCALENDAR フッター
    buffer.write('END:VCALENDAR$crlf');

    return buffer.toString();
  }

  /// RecurrenceType を iCalendar の RRULE に変換
  static String? _buildRrule(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'FREQ=DAILY';
      case RecurrenceType.weekly:
        return 'FREQ=WEEKLY';
      case RecurrenceType.monthly:
        return 'FREQ=MONTHLY';
      case RecurrenceType.yearly:
        return 'FREQ=YEARLY';
      case RecurrenceType.weekday:
        return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
      case RecurrenceType.custom:
      case RecurrenceType.none:
        return null;
    }
  }

  /// 日時を YYYYMMDDTHHMMSS 形式に変換
  static String _formatIcsDateTime(DateTime dt) {
    return DateFormat('yyyyMMdd\'T\'HHmmss').format(dt);
  }

  /// 日付を YYYYMMDD 形式に変換
  static String _formatIcsDate(DateTime dt) {
    return DateFormat('yyyyMMdd').format(dt);
  }

  /// iCalendarの特殊文字（改行、カンマ、セミコロン、バックスラッシュ）をエスケープ
  static String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\r\n', '\\n')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\n');
  }
}
