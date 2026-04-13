// BirthDay Calendar の基本ウィジェットテスト。
//
// Phase 4 以降でUIの実装が進んだ段階で、
// 実際の画面に合わせたテストに書き換える。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // ProviderScope でラップしてアプリを起動
    await tester.pumpWidget(
      const ProviderScope(
        child: BirthdayCalendarApp(),
      ),
    );

    // アプリが正常に起動することを確認
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
