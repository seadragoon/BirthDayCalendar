import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/widget/models/photo_countdown_widget_settings.dart';
import 'package:birthday_calendar/features/widget/widgets/photo_countdown_settings_modal.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';

class _FakeBirthdayListNotifier extends BirthdayListNotifier {
  final List<BirthdayModel> _data;
  _FakeBirthdayListNotifier(this._data);

  @override
  Future<List<BirthdayModel>> build() async => _data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoCountdownWidgetSettings Tests', () {
    test('default settings have null id, null photo, and showAge true', () {
      const settings = PhotoCountdownWidgetSettings();
      expect(settings.birthdayId, isNull);
      expect(settings.photoPath, isNull);
      expect(settings.showAge, isTrue);
      expect(settings.accentColorIndex, 0);
    });

    test('toMap and fromMap serialize and deserialize properly', () {
      const settings = PhotoCountdownWidgetSettings(
        birthdayId: 42,
        photoPath: '/path/to/favorite.jpg',
        showAge: false,
        accentColorIndex: 2,
      );

      final map = settings.toMap();
      final restored = PhotoCountdownWidgetSettings.fromMap(map);

      expect(restored.birthdayId, 42);
      expect(restored.photoPath, '/path/to/favorite.jpg');
      expect(restored.showAge, isFalse);
      expect(restored.accentColorIndex, 2);
    });

    test('toJson and fromJson serialize and deserialize properly', () {
      const settings = PhotoCountdownWidgetSettings(
        birthdayId: 99,
        photoPath: '/custom/photo.png',
        showAge: true,
        accentColorIndex: 1,
      );

      final jsonStr = settings.toJson();
      final restored = PhotoCountdownWidgetSettings.fromJson(jsonStr);

      expect(restored.birthdayId, 99);
      expect(restored.photoPath, '/custom/photo.png');
      expect(restored.showAge, isTrue);
      expect(restored.accentColorIndex, 1);
    });

    test('copyWith updates and clears fields correctly', () {
      const settings = PhotoCountdownWidgetSettings(
        birthdayId: 10,
        photoPath: '/old/path.jpg',
        showAge: true,
      );

      final updated = settings.copyWith(
        birthdayId: 20,
        photoPath: '/new/path.jpg',
        showAge: false,
      );
      expect(updated.birthdayId, 20);
      expect(updated.photoPath, '/new/path.jpg');
      expect(updated.showAge, isFalse);

      final cleared = updated.copyWith(
        clearBirthdayId: true,
        clearPhotoPath: true,
      );
      expect(cleared.birthdayId, isNull);
      expect(cleared.photoPath, isNull);
      expect(cleared.showAge, isFalse);
    });
  });

  group('PhotoCountdownSettingsModal Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders modal with section titles and live preview', (tester) async {
      final mockBirthday = BirthdayModel(
        id: 1,
        name: '推しアイドル',
        date: DateTime.now().add(const Duration(days: 5)),
        isYearUnknown: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            birthdayListProvider.overrideWith(() => _FakeBirthdayListNotifier([mockBirthday])),
          ],

          child: const MaterialApp(
            home: Scaffold(
              body: PhotoCountdownSettingsModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // タイトルと各セクションが表示される
      expect(find.text('写真付きウィジェット設定'), findsOneWidget);
      expect(find.text('1. カウントダウンする誕生日'), findsOneWidget);
      expect(find.text('2. 写真の選択'), findsOneWidget);
      expect(find.text('3. 表示オプション'), findsOneWidget);
      expect(find.text('4. ウィジェット完成プレビュー'), findsOneWidget);

      // 自動追跡の選択肢と写真選択カードが表示される
      expect(find.text('直近の誕生日（自動追跡）'), findsOneWidget);
      expect(find.text('写真を選ぶ'), findsOneWidget);
      expect(find.text('年齢を表示する'), findsOneWidget);
    });
  });
}
