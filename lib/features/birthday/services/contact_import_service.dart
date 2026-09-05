import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:birthday_calendar/features/birthday/models/contact_birthday_entry.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';
import 'package:birthday_calendar/features/widget/services/widget_sync_service.dart';

/// 端末の連絡先から誕生日を取得・インポートするサービス。
class ContactImportService {
  /// 連絡先読み取り権限のリクエスト
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// 端末の連絡先から誕生日が設定されている連絡先をスキャン・抽出する
  static Future<List<ContactBirthdayEntry>> fetchBirthdayContacts() async {
    final hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      throw Exception('連絡先へのアクセス権限がありません。');
    }

    // 全連絡先（詳細プロパティ付き）を取得
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    // 既存の誕生日を取得（名前と月日で重複判定）
    final db = await DatabaseHelper.instance.database;
    final existingBirthdays = await db.query(DatabaseHelper.tableBirthdays);
    final existingBirthdayKeys = existingBirthdays.map((b) {
      final name = b['name'] as String;
      final date = DateTime.fromMillisecondsSinceEpoch(b['date'] as int);
      return '$name-${date.month}-${date.day}';
    }).toSet();

    final List<ContactBirthdayEntry> results = [];

    for (final contact in contacts) {
      // 姓名の取得
      String name = contact.displayName;
      if (name.trim().isEmpty) {
        name = '${contact.name.last} ${contact.name.first}'.trim();
      }
      if (name.isEmpty) continue;

      // events から誕生日を探す
      for (final event in contact.events) {
        if (event.label == EventLabel.birthday) {
          final month = event.month;
          final day = event.day;
          if (month < 1 || month > 12 || day < 1 || day > 31) continue;

          final isYearUnknown = event.year == null || event.year! <= 0;
          final currentYear = DateTime.now().year;
          final year = isYearUnknown ? currentYear : event.year!;

          DateTime date;
          try {
            date = DateTime(year, month, day);
          } catch (_) {
            continue;
          }

          final key = '$name-$month-$day';
          final isAlreadyRegistered = existingBirthdayKeys.contains(key);

          results.add(
            ContactBirthdayEntry(
              contactId: contact.id,
              name: name,
              birthday: date,
              isYearUnknown: isYearUnknown,
              isAlreadyRegistered: isAlreadyRegistered,
              // 既に登録済みの場合は初期選択OFF、未登録ならON
              isSelected: !isAlreadyRegistered,
            ),
          );
        }
      }
    }

    // 名前順でソート
    results.sort((a, b) => a.name.compareTo(b.name));

    return results;
  }

  /// 選択された連絡先の誕生日を一括でDBへ取り込む
  static Future<int> importContacts({
    required List<ContactBirthdayEntry> entries,
    required List<String> tags,
  }) async {
    final selectedEntries = entries.where((e) => e.isSelected).toList();
    if (selectedEntries.isEmpty) return 0;

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    int count = 0;

    await db.transaction((txn) async {
      for (final entry in selectedEntries) {
        final birthday = BirthdayModel(
          name: entry.name,
          date: entry.birthday,
          isYearUnknown: entry.isYearUnknown,
          tags: tags,
          notifications: const [NotificationType.none],
          comment: '連絡先からインポート',
          createdAt: now,
          updatedAt: now,
        );

        await txn.insert(
          DatabaseHelper.tableBirthdays,
          birthday.toMap()..remove('id'),
        );
        count++;
      }
    });

    // ウィジェットデータを最新状態に同期
    WidgetSyncService.updateAllWidgets();

    return count;
  }
}
