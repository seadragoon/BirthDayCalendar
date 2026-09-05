import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';

/// ローカル通知の制御を行うシングルトンサービス。
class NotificationService {
  // シングルトンインスタンス
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  /// 通知サービスの初期化
  Future<void> initialize() async {
    // タイムゾーンデータベースの初期化
    tz.initializeTimeZones();
    // デフォルトで東京タイムゾーンを設定
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    } catch (e) {
      debugPrint('タイムゾーン初期化エラー: $e');
    }

    // Android用の初期化設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS用の初期化設定
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('通知がタップされました: ${response.payload}');
      },
    );
  }

  /// 端末側で通知が許可されているか確認する
  Future<bool> areNotificationsGranted() async {
    try {
      // Android
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final enabled = await androidImplementation.areNotificationsEnabled();
        return enabled ?? false;
      }

      // iOS
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final permissions = await iosImplementation.checkPermissions();
        return permissions?.isEnabled ?? false;
      }
    } catch (e) {
      debugPrint('通知権限チェックエラー: $e');
    }
    return true;
  }

  /// 通知と正確なアラーム権限のリクエスト（設定画面の起動含む）
  Future<bool> requestPermissions() async {
    bool granted = false;
    // Android
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final notifGranted = await androidImplementation.requestNotificationsPermission() ?? false;
      await androidImplementation.requestExactAlarmsPermission();
      granted = notifGranted;
    }

    // iOS
    final iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final iosGranted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
      granted = iosGranted;
    }

    return granted;
  }

  /// 予定（Event）に関する通知のスケジュール登録
  Future<void> scheduleEventNotification(EventModel event) async {
    await cancelEventNotifications(event.id);

    if (event.id == null || event.notifications.isEmpty) return;

    for (final notification in event.notifications) {
      if (notification == NotificationType.none) continue;

      final scheduledTime = _calculateNotificationTime(event.startDate, notification, event.isAllDay);
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final notificationId = event.id! * 10 + notification.index;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '予定のお知らせ',
        '本日: 「${event.title}」があります。',
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_channel_id',
            '予定の通知',
            channelDescription: '登録された予定の前にリマインダー通知を送ります。',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// 予定（Event）に関する通知のキャンセル
  Future<void> cancelEventNotifications(int? eventId) async {
    if (eventId == null) return;
    for (final type in NotificationType.values) {
      final notificationId = eventId * 10 + type.index;
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  /// 誕生日（Birthday）に関する通知のスケジュール登録
  Future<void> scheduleBirthdayNotification(BirthdayModel birthday) async {
    await cancelBirthdayNotifications(birthday.id);

    if (birthday.id == null || birthday.notifications.isEmpty) return;

    for (final notification in birthday.notifications) {
      if (notification == NotificationType.none) continue;

      final notificationId = -(birthday.id! * 10 + notification.index);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        birthday.date.month,
        birthday.date.day,
        9, 0, 0,
      );

      scheduledDate = _applyBirthdayOffset(scheduledDate, notification);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year + 1,
          birthday.date.month,
          birthday.date.day,
          9, 0, 0,
        );
        scheduledDate = _applyBirthdayOffset(scheduledDate, notification);
      }

      final String bodyText = birthday.isYearUnknown
          ? '今日は「${birthday.name}」さんの誕生日です！🎂'
          : '今日は「${birthday.name}」さんの誕生日です！ (${birthday.ageThisYear}歳になりました🎂)';

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '誕生日のお知らせ🎉',
        bodyText,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'birthday_channel_id',
            '誕生日の通知',
            channelDescription: '登録された誕生日の前にリマインダー通知を送ります。',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  /// 誕生日（Birthday）に関する通知のキャンセル
  Future<void> cancelBirthdayNotifications(int? birthdayId) async {
    if (birthdayId == null) return;
    for (final type in NotificationType.values) {
      final notificationId = -(birthdayId * 10 + type.index);
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  /// 予定（Event）の通知発火時間を計算
  DateTime _calculateNotificationTime(DateTime baseTime, NotificationType type, bool isAllDay) {
    final DateTime targetBase = isAllDay
        ? DateTime(baseTime.year, baseTime.month, baseTime.day, 9, 0, 0)
        : baseTime;

    switch (type) {
      case NotificationType.atTime:
        return targetBase;
      case NotificationType.fiveMinutes:
        return targetBase.subtract(const Duration(minutes: 5));
      case NotificationType.fifteenMinutes:
        return targetBase.subtract(const Duration(minutes: 15));
      case NotificationType.thirtyMinutes:
        return targetBase.subtract(const Duration(minutes: 30));
      case NotificationType.oneHour:
        return targetBase.subtract(const Duration(hours: 1));
      case NotificationType.oneDay:
        return targetBase.subtract(const Duration(days: 1));
      case NotificationType.oneWeek:
        return targetBase.subtract(const Duration(days: 7));
      case NotificationType.none:
        return targetBase;
    }
  }

  /// 誕生日の通知発火オフセットを適用
  tz.TZDateTime _applyBirthdayOffset(tz.TZDateTime baseTime, NotificationType type) {
    switch (type) {
      case NotificationType.atTime:
        return baseTime;
      case NotificationType.oneDay:
        return baseTime.subtract(const Duration(days: 1));
      case NotificationType.oneWeek:
        return baseTime.subtract(const Duration(days: 7));
      default:
        return baseTime;
    }
  }
}
