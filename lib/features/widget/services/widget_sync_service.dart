import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/features/settings/models/birthday_display_settings.dart';
import 'package:birthday_calendar/features/widget/models/widget_birthday_item.dart';
import 'package:birthday_calendar/features/widget/models/widget_schedule_item.dart';
import 'package:birthday_calendar/shared/db/database_helper.dart';

/// ホーム画面ウィジェットとのデータ同期および更新管理サービス。
class WidgetSyncService {
  static const List<String> _androidBirthdayWidgetNames = [
    'BirthdayWidgetProvider',
    'BirthdayWidget2x2Provider',
    'BirthdayWidget2x3Provider',
  ];
  static const List<String> _androidScheduleWidgetNames = [
    'ScheduleWidgetProvider',
    'ScheduleWidget2x2Provider',
    'ScheduleWidget2x3Provider',
  ];
  static const String _birthdayDataKey = 'birthday_widget_data';
  static const String _scheduleDataKey = 'schedule_widget_data';
  static const String _scheduleDateHeaderKey = 'schedule_widget_date_header';

  /// プラットフォームがホーム画面ウィジェットに対応しているか判定
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// 全ウィジェット（誕生日・予定）のデータを一括更新する
  static Future<void> updateAllWidgets() async {
    if (!isSupported) return;
    await updateWidgetData();
    await updateScheduleWidgetData();
  }

  /// データベースから直近の誕生日を取得し、ホーム画面ウィジェットのデータを更新する
  static Future<void> updateWidgetData() async {
    if (!isSupported) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(DatabaseHelper.tableBirthdays);

      final birthdays = maps.map((m) => BirthdayModel.fromMap(m)).toList();

      // 直近の誕生日順（残り日数が少ない順）にソート
      birthdays.sort((a, b) => a.daysUntilNextBirthday.compareTo(b.daysUntilNextBirthday));

      // 直近上位5件を抽出
      final topBirthdays = birthdays.take(5).map((b) => WidgetBirthdayItem.fromBirthday(b)).toList();

      final jsonList = topBirthdays.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      // ウィジェット共有ストレージに保存
      await HomeWidget.saveWidgetData<String>(_birthdayDataKey, jsonString);

      // 全サイズの誕生日ウィジェットの再描画を要求
      for (final widgetName in _androidBirthdayWidgetNames) {
        await HomeWidget.updateWidget(
          name: widgetName,
          androidName: widgetName,
        );
      }
    } catch (e) {
      debugPrint('[WidgetSyncService] 誕生日ウィジェット更新エラー: $e');
    }
  }

  /// データベースから今日〜直近の予定を取得し、予定ウィジェットのデータを更新する
  static Future<void> updateScheduleWidgetData() async {
    if (!isSupported) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final futureLimit = today.add(const Duration(days: 30));

      final db = await DatabaseHelper.instance.database;

      // 1. 全予定を取得し、今日〜30日後まで展開
      final eventMaps = await db.query(DatabaseHelper.tableEvents);
      final events = eventMaps.map((m) => EventModel.fromMap(m)).toList();
      final expandedEvents = expandEvents(events, today, futureLimit);

      // 2. 誕生日のカレンダー表示設定を確認し、有効なら誕生日もマージ
      try {
        final prefs = await SharedPreferences.getInstance();
        final settingsJson = prefs.getString('birthday_display_settings');
        final settings = settingsJson != null
            ? BirthdayDisplaySettings.fromJson(settingsJson)
            : const BirthdayDisplaySettings();

        if (settings.isShowOnSchedule) {
          final birthdayMaps = await db.query(DatabaseHelper.tableBirthdays);
          final birthdays = birthdayMaps.map((m) => BirthdayModel.fromMap(m)).toList();
          final birthdayEvents = generateBirthdayEvents(
            birthdays,
            settings,
            today,
            futureLimit,
          );
          expandedEvents.addAll(birthdayEvents);
        }
      } catch (e) {
        debugPrint('[WidgetSyncService] 誕生日マージエラー (続行): $e');
      }

      // 3. 開始日時順にソート
      expandedEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      // 4. 今日の日付ヘッダー文字列の作成（例: "9月6日 (日)"）
      const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
      final weekdayStr = weekdays[now.weekday - 1];
      final dateHeader = '${now.month}月${now.day}日 ($weekdayStr)';

      // 5. 上位5件を抽出してモデル化
      final topEvents = expandedEvents
          .take(5)
          .map((e) => WidgetScheduleItem.fromEvent(e, today))
          .toList();

      final jsonList = topEvents.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      // 6. ウィジェット共有ストレージに保存
      await HomeWidget.saveWidgetData<String>(_scheduleDataKey, jsonString);
      await HomeWidget.saveWidgetData<String>(_scheduleDateHeaderKey, dateHeader);

      // 7. 全サイズの予定ウィジェットの再描画を要求
      for (final widgetName in _androidScheduleWidgetNames) {
        await HomeWidget.updateWidget(
          name: widgetName,
          androidName: widgetName,
        );
      }
    } catch (e) {
      debugPrint('[WidgetSyncService] 予定ウィジェット更新エラー: $e');
    }
  }
}
