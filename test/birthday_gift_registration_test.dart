import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/models/gift_model.dart';
import 'package:birthday_calendar/features/birthday/widgets/birthday_modal.dart';
import 'package:birthday_calendar/features/birthday/widgets/gift_edit_modal.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP', null);
  });

  group('BirthdayModal Gift Section Tests', () {
    testWidgets('BirthdayModal in create mode displays gift section and empty notice', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BirthdayModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // セクションヘッダーと「記録を追加」ボタンが表示されること
      expect(find.text('プレゼント・お祝い履歴'), findsOneWidget);
      expect(find.text('記録を追加'), findsOneWidget);

      // 空状態の案内テキストが表示されること
      expect(find.text('プレゼントやお祝いの記録はありません（任意）'), findsOneWidget);
    });

    testWidgets('BirthdayModal in edit mode displays gift section', (WidgetTester tester) async {
      final testBirthday = BirthdayModel(
        id: 99,
        name: '山田太郎',
        date: DateTime(1995, 5, 10),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BirthdayModal(existingBirthday: testBirthday),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('プレゼント・お祝い履歴'), findsOneWidget);
      expect(find.text('記録を追加'), findsOneWidget);
    });
  });

  group('GiftEditModal with birthdayId=0 Tests', () {
    testWidgets('GiftEditModal displays form correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GiftEditModal(birthdayId: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('プレゼントを記録'), findsOneWidget);
      expect(find.text('品名（必須）'), findsOneWidget);
      expect(find.text('金額・予算（任意）'), findsOneWidget);
      expect(find.text('メモ・相手の反応（任意）'), findsOneWidget);
      expect(find.text('記録を追加'), findsOneWidget);
    });

    testWidgets('GiftEditModal edit mode displays existing data', (WidgetTester tester) async {
      final gift = GiftModel(
        birthdayId: 0,
        year: 2026,
        type: GiftType.idea,
        name: 'リュックサック',
        price: 9800,
        memo: '防水仕様が良いとのこと',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GiftEditModal(birthdayId: 0, existingGift: gift),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('プレゼント記録の編集'), findsOneWidget);
      expect(find.text('リュックサック'), findsOneWidget);
      expect(find.text('9800'), findsOneWidget);
      expect(find.text('防水仕様が良いとのこと'), findsOneWidget);
      expect(find.text('変更を保存'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
