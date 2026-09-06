import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/calendar/widgets/custom_month_view.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_list_view.dart';
import 'package:birthday_calendar/features/calendar/widgets/today_bar.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';

/// カレンダーとイベントリストを組み合わせた、スケジュール画面のメインビュー。
class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customBgPath = appTheme?.customBackgroundPath;

    // カレンダー部分のWidget（写真背景が設定されている場合は写真＋ホワイトアウトを背面に敷く）
    Widget calendarWidget = const CustomMonthView();

    if (customBgPath != null && customBgPath.isNotEmpty) {
      calendarWidget = Stack(
        fit: StackFit.expand,
        children: [
          // 1. カレンダー背面写真
          Image.file(
            File(customBgPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          // 2. ホワイトアウト / ブラックアウト オーバーレイ（文字の視認性を確保）
          Container(
            color: (isDark ? Colors.black : Colors.white)
                .withValues(alpha: appTheme?.backgroundOpacity ?? 0.80),
          ),
          // 3. カレンダーグリッド本体
          const CustomMonthView(),
        ],
      );
    }

    return Column(
      children: [
        // 1. カレンダー部分（写真背景の適用領域）
        Expanded(
          flex: 6,
          child: calendarWidget,
        ),

        // 2. Today Bar (例: "4月6日 (月)")
        const TodayBar(),

        // 3. 今日の予定リスト（写真なし・通常背景）
        const Expanded(
          flex: 4,
          child: EventListView(),
        ),
      ],
    );
  }
}

