import 'package:flutter_test/flutter_test.dart';

import 'package:birthday_calendar/features/birthday/models/gift_model.dart';
import 'package:birthday_calendar/features/backup/models/backup_data.dart';

void main() {
  group('GiftType Tests', () {
    test('fromKey returns correct GiftType or default', () {
      expect(GiftType.fromKey('give'), GiftType.give);
      expect(GiftType.fromKey('receive'), GiftType.receive);
      expect(GiftType.fromKey('idea'), GiftType.idea);
      expect(GiftType.fromKey('unknown'), GiftType.give);
    });

    test('GiftType has expected labels and emojis', () {
      expect(GiftType.give.label, 'あげた');
      expect(GiftType.give.emoji, '🎁');
      expect(GiftType.receive.label, 'もらった');
      expect(GiftType.receive.emoji, '🎀');
      expect(GiftType.idea.label, '候補');
      expect(GiftType.idea.emoji, '💡');
    });
  });

  group('GiftModel Tests', () {
    final now = DateTime(2026, 9, 6, 12, 0);
    final gift = GiftModel(
      id: 1,
      birthdayId: 42,
      year: 2026,
      type: GiftType.give,
      name: 'スニーカー',
      price: 12000,
      memo: 'サイズ26.5cm、黒',
      createdAt: now,
      updatedAt: now,
    );

    test('toMap and fromMap preserves all fields', () {
      final map = gift.toMap();
      expect(map['id'], 1);
      expect(map['birthday_id'], 42);
      expect(map['year'], 2026);
      expect(map['type'], 'give');
      expect(map['name'], 'スニーカー');
      expect(map['price'], 12000);
      expect(map['memo'], 'サイズ26.5cm、黒');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['updated_at'], now.millisecondsSinceEpoch);

      final restored = GiftModel.fromMap(map);
      expect(restored.id, gift.id);
      expect(restored.birthdayId, gift.birthdayId);
      expect(restored.year, gift.year);
      expect(restored.type, gift.type);
      expect(restored.name, gift.name);
      expect(restored.price, gift.price);
      expect(restored.memo, gift.memo);
      expect(restored.createdAt, now);
      expect(restored.updatedAt, now);
    });

    test('copyWith updates specified fields', () {
      final updated = gift.copyWith(
        year: 2025,
        type: GiftType.receive,
        price: 15000,
      );

      expect(updated.id, gift.id);
      expect(updated.year, 2025);
      expect(updated.type, GiftType.receive);
      expect(updated.price, 15000);
      expect(updated.name, gift.name);
    });
  });

  group('BackupData with Gifts Tests', () {
    test('toJson and fromJson handles gifts serialization', () {
      final now = DateTime.now();
      final gift = GiftModel(
        id: 10,
        birthdayId: 5,
        year: 2025,
        type: GiftType.receive,
        name: '手帳カバー',
        price: 3500,
        memo: '革製で素敵',
      );

      final backup = BackupData(
        exportedAt: now,
        events: [],
        birthdays: [],
        tags: [],
        gifts: [gift],
      );

      final json = backup.toJson();
      final restored = BackupData.fromJson(json);

      expect(restored.gifts.length, 1);
      expect(restored.gifts.first.name, '手帳カバー');
      expect(restored.gifts.first.year, 2025);
      expect(restored.gifts.first.type, GiftType.receive);
      expect(restored.gifts.first.price, 3500);
    });

    test('fromJson handles legacy backup JSON without gifts gracefully', () {
      final legacyJson = {
        'version': 1,
        'app': 'BirthdayCalendar',
        'exported_at': '2026-09-01T10:00:00.000',
        'data': {
          'events': [],
          'birthdays': [],
          'tags': [],
          // 'gifts' is missing
        },
      };

      final restored = BackupData.fromJson(legacyJson);
      expect(restored.gifts, isEmpty);
    });
  });
}
