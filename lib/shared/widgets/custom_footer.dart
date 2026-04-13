import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';

/// アプリ全体の共通フッター（NavigationBar）。
///
/// スケジュールと誕生日のView切り替えを行う。
class CustomFooter extends ConsumerWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(viewTypeProvider);

    return NavigationBar(
      selectedIndex: viewType.index,
      onDestinationSelected: (index) {
        if (index == 0) {
          ref.read(viewTypeProvider.notifier).state = ViewType.schedule;
        } else if (index == 1) {
          ref.read(viewTypeProvider.notifier).state = ViewType.birthday;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'スケジュール',
        ),
        NavigationDestination(
          icon: Icon(Icons.cake_outlined),
          selectedIcon: Icon(Icons.cake),
          label: '誕生日',
        ),
        // PLANNING.md の指示「右側は将来の拡張用に空けておく」に従い
        // 見えないダミーのDestinationを置く、または単に余白として2つだけ並べる。
        // ここではNavigationBarのデフォルトの挙動で均等配置されるため、
        // 拡張性を考慮して一旦2つのみ配置する。
      ],
    );
  }
}
