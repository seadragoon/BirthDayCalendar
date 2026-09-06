import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_detail_modal.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/recurrence_type.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP', null);
  });

  final testEvent = EventModel(
    id: 101,
    title: '定例ミーティング',
    startDate: DateTime(2026, 9, 10, 14, 0),
    endDate: DateTime(2026, 9, 10, 15, 0),
    isAllDay: false,
    colorIndex: EventColor.sage,
    recurrence: RecurrenceType.weekly,
    comment: '議題：進捗確認',
    icon: '📝',
  );

  group('Event Copy Feature Tests', () {
    testWidgets('EventDetailModal displays copy action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EventDetailModal(event: testEvent),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 編集・コピー・削除アイコンが表示されていることを確認
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // コピーボタンのツールチップ確認
      final copyButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.copy_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(copyButton.tooltip, 'コピーして作成');
    });

    testWidgets('EventModal in copy mode has title "予定の複製" and no delete button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EventModal(
              existingEvent: testEvent,
              isCopyMode: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // タイトルが「予定の複製」であること
      expect(find.text('予定の複製'), findsOneWidget);

      // 削除ボタンが存在しないこと
      expect(find.byIcon(Icons.delete), findsNothing);

      // コピー元の値（タイトル、メモ、スタンプ）が初期値として入っていること
      expect(find.text('定例ミーティング'), findsOneWidget);
      expect(find.text('議題：進捗確認'), findsOneWidget);
      expect(find.text('📝'), findsOneWidget);
    });

    testWidgets('EventModal in normal edit mode has title "予定を編集" and delete button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EventModal(
              existingEvent: testEvent,
              isCopyMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // タイトルが「予定を編集」であること
      expect(find.text('予定を編集'), findsOneWidget);

      // 削除ボタンが存在すること
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('EventModal in copy mode with initialDate adjusts date while preserving duration', (WidgetTester tester) async {
      final newDate = DateTime(2026, 9, 15);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EventModal(
              existingEvent: testEvent,
              initialDate: newDate,
              isCopyMode: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('予定の複製'), findsOneWidget);
      expect(find.text('定例ミーティング'), findsOneWidget);
    });
  });
}
