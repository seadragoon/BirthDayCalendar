import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_calendar/features/settings/models/app_settings.dart';
import 'package:birthday_calendar/shared/constants/rokuyo_util.dart';

void main() {
  group('RokuyoUtil Tests', () {
    test('Rokuyo calculation returns valid rokuyo names', () {
      final validRokuyo = {'大安', '友引', '先勝', '先負', '仏滅', '赤口'};

      // 2026年9月6日
      final date = DateTime(2026, 9, 6);
      final rokuyo = RokuyoUtil.getRokuyo(date);
      expect(validRokuyo.contains(rokuyo), isTrue);

      // キャッシュから取得
      final cachedRokuyo = RokuyoUtil.getRokuyo(date);
      expect(cachedRokuyo, equals(rokuyo));
    });

    test('isTaian and isButsumetsu accurately reflect getRokuyo', () {
      // 1ヶ月分走査して、isTaian/isButsumetsuの判定が一致することを検証
      for (int day = 1; day <= 30; day++) {
        final date = DateTime(2026, 9, day);
        final rokuyo = RokuyoUtil.getRokuyo(date);
        if (rokuyo == '大安') {
          expect(RokuyoUtil.isTaian(date), isTrue);
        } else {
          expect(RokuyoUtil.isTaian(date), isFalse);
        }

        if (rokuyo == '仏滅') {
          expect(RokuyoUtil.isButsumetsu(date), isTrue);
        } else {
          expect(RokuyoUtil.isButsumetsu(date), isFalse);
        }
      }
    });
  });

  group('AppSettings showRokuyo Tests', () {
    test('default showRokuyo should be false', () {
      const settings = AppSettings();
      expect(settings.showRokuyo, isFalse);
    });

    test('copyWith updates showRokuyo correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(showRokuyo: true);
      expect(updated.showRokuyo, isTrue);
      expect(settings.showRokuyo, isFalse); // 不変性
    });

    test('toMap and fromMap serialize and deserialize showRokuyo', () {
      const settings = AppSettings(showRokuyo: true);
      final map = settings.toMap();
      expect(map['showRokuyo'], isTrue);

      final restored = AppSettings.fromMap(map);
      expect(restored.showRokuyo, isTrue);

      // 古いJSONマップ等でshowRokuyoキーが無い場合のフォールバック（デフォルトfalse）
      final legacyMap = <String, dynamic>{
        'isNotificationsEnabled': true,
        'firstDayOfWeek': 0,
        'themeMode': 1,
      };
      final legacyRestored = AppSettings.fromMap(legacyMap);
      expect(legacyRestored.showRokuyo, isFalse);
    });
  });
}
