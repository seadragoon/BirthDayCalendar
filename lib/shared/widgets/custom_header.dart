import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/custom_search_delegate.dart';

/// アプリ共通のヘッダー（AppBar）。
///
/// 左側にドロワーメニューのトグルボタン、
/// 中央に現在の [ViewType] に応じたタイトル、
/// 右側に検索ボタンとカレンダーの「今日」へ戻るボタンなどを配置する。
class CustomHeader extends ConsumerWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(viewTypeProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final appTheme = ref.watch(themeProvider);

    // タイトルの出し分け
    final String title = viewType == ViewType.schedule
        ? DateFormat('yyyy年M月').format(currentMonth)
        : '誕生日';

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: appTheme.onPrimaryColor,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: appTheme.backgroundImagePath.isEmpty ? appTheme.primaryColor : null,
          image: appTheme.backgroundImagePath.isNotEmpty
              ? DecorationImage(
                  image: AssetImage(appTheme.backgroundImagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.2), // ちょっと暗くして文字を見やすく
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
      ),
      iconTheme: IconThemeData(color: appTheme.onPrimaryColor),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '検索',
          onPressed: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(viewType: viewType),
            );
          },
        ),
        if (viewType == ViewType.schedule)
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '今日',
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state = now;
              ref.read(currentMonthProvider.notifier).state = DateTime(now.year, now.month);
            },
          ),
      ],
    );
  }
}
