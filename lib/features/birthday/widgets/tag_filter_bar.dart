import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';

/// 誕生日リストの上部に表示される、タグを使った横スクロールのフィルターバー。
class TagFilterBar extends ConsumerWidget {
  const TagFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 登録されている全てのユニークタグ
    final allTagsAsync = ref.watch(allTagsProvider);
    // 現在選択中のタグ (null = すべて, '' = 未設定, それ以外 = 特定タグ)
    final selectedTag = ref.watch(selectedTagProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: allTagsAsync.when(
        loading: () => const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (err, stack) => const Center(child: Text('エラー')),
        data: (tags) {
          // 利用可能なフィルターの定義
          final filterItems = [
            _FilterItem(label: 'すべて', tagValue: null),
            ...tags.map((tag) => _FilterItem(label: tag, tagValue: tag)),
            _FilterItem(label: '未設定', tagValue: ''),
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filterItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = filterItems[index];
              final isSelected = selectedTag == item.tagValue;

              return Center(
                child: FilterChip(
                  label: Text(item.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(selectedTagProvider.notifier).state = item.tagValue;
                  },
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  showCheckmark: false,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final String label;
  final String? tagValue;
  _FilterItem({required this.label, this.tagValue});
}
