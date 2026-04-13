import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/widgets/birthday_modal.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_modal.dart';
import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';

/// アプリ共通のフローティングアクションボタン（FAB）。
///
/// 現在の [ViewType] に応じてアイコンやアクションが切り替わる。
class CustomFab extends ConsumerWidget {
  const CustomFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(viewTypeProvider);

    if (viewType == ViewType.schedule) {
      return FloatingActionButton(
        onPressed: () {
          // イベント追加モーダルを開く
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EventModal(),
              fullscreenDialog: true,
            ),
          );
        },
        tooltip: '予定を追加',
        child: const Icon(Icons.add),
      );
    } else {
      return FloatingActionButton(
        onPressed: () {
          // 誕生日追加モーダルを開く
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BirthdayModal(),
              fullscreenDialog: true,
            ),
          );
        },
        tooltip: '誕生日を追加',
        child: const Icon(Icons.cake),
      );
    }
  }
}
