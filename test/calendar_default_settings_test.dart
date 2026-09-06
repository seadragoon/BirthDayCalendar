import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/settings/models/app_settings.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/features/settings/widgets/calendar_settings_modal.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettings default settings tests', () {
    test('default values are as expected', () {
      const settings = AppSettings();
      expect(settings.defaultIsAllDay, false);
      expect(settings.defaultColorIndex, EventColor.lavender.index);
      expect(settings.defaultNotifications, [NotificationType.none]);
    });

    test('toMap and fromMap preserve default registration settings', () {
      final original = AppSettings(
        defaultIsAllDay: true,
        defaultColorIndex: EventColor.banana.index,
        defaultNotifications: const [NotificationType.atTime, NotificationType.oneDay],
      );

      final map = original.toMap();
      final restored = AppSettings.fromMap(map);

      expect(restored.defaultIsAllDay, true);
      expect(restored.defaultColorIndex, EventColor.banana.index);
      expect(restored.defaultNotifications, [NotificationType.atTime, NotificationType.oneDay]);
    });
  });

  group('CalendarSettingsModal tests', () {
    testWidgets('renders registration default settings section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CalendarSettingsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('予定登録の初期設定'), findsOneWidget);
      expect(find.text('終日をデフォルトにする'), findsOneWidget);
      expect(find.text('デフォルトの予定カラー'), findsOneWidget);
      expect(find.text('デフォルトの通知タイミング'), findsOneWidget);
      expect(find.text('ラベンダー'), findsOneWidget);
      expect(find.text('なし'), findsOneWidget);
    });
  });

  group('EventModal reflects AppSettings defaults', () {
    testWidgets('new event takes custom default settings', (WidgetTester tester) async {
      // カスタム設定を持つAppSettings
      const customSettings = AppSettings(
        defaultIsAllDay: true,
        defaultColorIndex: 3, // banana
        defaultNotifications: [NotificationType.atTime],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith(
              () => _MockAppSettingsNotifier(customSettings),
            ),
          ],
          child: MaterialApp(
            home: EventModal(
              initialDate: DateTime(2026, 9, 15),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 終日スイッチがONになっていること
      final switchFinder = find.widgetWithText(SwitchListTile, '終日');
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, true);

      // 通知に「開始時刻」が含まれていること
      expect(find.textContaining('開始時刻'), findsOneWidget);
    });
  });
}

class _MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings _initial;
  _MockAppSettingsNotifier(this._initial);

  @override
  Future<AppSettings> build() async {
    return _initial;
  }
}
