import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/ads/providers/ad_providers.dart';
import 'package:birthday_calendar/features/ads/services/ad_service.dart';
import 'package:birthday_calendar/features/ads/widgets/ad_banner_widget.dart';
import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/widgets/birthday_detail_modal.dart';
import 'package:birthday_calendar/features/birthday/widgets/birthday_modal.dart';
import 'package:birthday_calendar/features/calendar/models/event_model.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_detail_modal.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';
import 'package:birthday_calendar/features/premium/providers/premium_provider.dart';

class _FakeAdService implements AdService {
  @override
  final bool isAvailable;

  @override
  bool get isInitialized => isAvailable;

  const _FakeAdService({required this.isAvailable});

  @override
  Future<void> initialize() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ja_JP');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('shouldShowAdsProvider Tests', () {
    test('returns true when free user and AdService is available', () async {
      final container = ProviderContainer(
        overrides: [
          adServiceProvider.overrideWithValue(
            const _FakeAdService(isAvailable: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      // プレミアム状態が解決されるまで待機
      await container.read(isPremiumProvider.future);
      expect(container.read(shouldShowAdsProvider), isTrue);
    });

    test('returns false when user is premium', () async {
      SharedPreferences.setMockInitialValues({kDebugIsPremiumKey: true});
      final container = ProviderContainer(
        overrides: [
          adServiceProvider.overrideWithValue(
            const _FakeAdService(isAvailable: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      expect(container.read(shouldShowAdsProvider), isFalse);
    });

    test('returns false when AdService is not available', () async {
      final container = ProviderContainer(
        overrides: [
          adServiceProvider.overrideWithValue(
            const _FakeAdService(isAvailable: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      expect(container.read(shouldShowAdsProvider), isFalse);
    });

    test('switches immediately when premium status toggles', () async {
      final container = ProviderContainer(
        overrides: [
          adServiceProvider.overrideWithValue(
            const _FakeAdService(isAvailable: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isPremiumProvider.future);
      expect(container.read(shouldShowAdsProvider), isTrue);

      // プレミアム解放 -> 広告非表示
      await container.read(isPremiumProvider.notifier).setDebugPremium(true);
      expect(container.read(shouldShowAdsProvider), isFalse);

      // 無料へ戻す -> 広告再表示
      await container.read(isPremiumProvider.notifier).setDebugPremium(false);
      expect(container.read(shouldShowAdsProvider), isTrue);
    });
  });

  group('AdBannerWidget Tests', () {
    testWidgets('shows banner for free user and hides immediately when upgraded to Pro', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          adServiceProvider.overrideWithValue(
            const _FakeAdService(isAvailable: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(isPremiumProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AdBannerWidget(
                testAdBuilder: (_) => const SizedBox(
                  height: 50,
                  child: Center(child: Text('TEST_BANNER_AD')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 無料時はバナーが表示される
      expect(find.text('TEST_BANNER_AD'), findsOneWidget);

      // Pro に切り替えると即座に完全非表示になる
      await container.read(isPremiumProvider.notifier).setDebugPremium(true);
      await tester.pumpAndSettle();
      expect(find.text('TEST_BANNER_AD'), findsNothing);
    });

    testWidgets('EventModal embeds AdBannerWidget in bottomNavigationBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: EventModal()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdBannerWidget), findsOneWidget);
    });

    testWidgets('BirthdayModal embeds AdBannerWidget in bottomNavigationBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: BirthdayModal()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdBannerWidget), findsOneWidget);
    });

    testWidgets(
      'EventDetailModal embeds AdBannerWidget in bottomNavigationBar',
      (tester) async {
        final event = EventModel(
          id: 1,
          title: 'テスト予定',
          startDate: DateTime(2026, 11, 23, 10, 0),
          endDate: DateTime(2026, 11, 23, 11, 0),
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: EventDetailModal(event: event)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AdBannerWidget), findsOneWidget);
      },
    );

    testWidgets(
      'BirthdayDetailModal embeds AdBannerWidget in bottomNavigationBar',
      (tester) async {
        final birthday = BirthdayModel(
          id: 1,
          name: 'テスト太郎',
          date: DateTime(1995, 5, 10),
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: BirthdayDetailModal(birthday: birthday)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AdBannerWidget), findsOneWidget);
      },
    );
  });
}
