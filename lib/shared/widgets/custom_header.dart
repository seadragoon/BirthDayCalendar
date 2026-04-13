import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';

/// アプリ全体の共通ヘッダー（AppBar）。
///
/// 表示中の [ViewType] に応じてタイトルとボタンが変化する。
class CustomHeader extends ConsumerWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(viewTypeProvider);
    final currentMonth = ref.watch(currentMonthProvider);

    // タイトルの出し分け
    String titleText;
    if (viewType == ViewType.schedule) {
      titleText = DateFormat('yyyy年M月').format(currentMonth);
    } else {
      titleText = '誕生日';
    }

    return AppBar(
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        // 今日ボタン
        IconButton(
          icon: const Icon(Icons.today),
          tooltip: '今日',
          onPressed: () {
            final now = DateTime.now();
            ref.read(selectedDateProvider.notifier).state =
                DateTime(now.year, now.month, now.day);
            ref.read(currentMonthProvider.notifier).state =
                DateTime(now.year, now.month);
          },
        ),
        // 検索ボタン
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '検索',
          onPressed: () {
            // TODO(Phase 7): 検索モーダルを開く
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('検索機能は Phase 7 で実装予定です')),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
