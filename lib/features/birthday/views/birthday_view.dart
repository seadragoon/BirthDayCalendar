import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/widgets/birthday_list_view.dart';
import 'package:birthday_calendar/features/birthday/widgets/tag_filter_bar.dart';

/// 誕生日画面のメインビュー。
///
/// 上部のタグフィルター([TagFilterBar])と、
/// 下部の誕生日リスト([BirthdayListView])を配置する。
class BirthdayView extends ConsumerWidget {
  const BirthdayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        // 上部: タグフィルター (すべて、家族、友達、カスタム...)
        TagFilterBar(),
        // 下部: フィルタリングされた誕生日リスト
        Expanded(
          child: BirthdayListView(),
        ),
      ],
    );
  }
}
