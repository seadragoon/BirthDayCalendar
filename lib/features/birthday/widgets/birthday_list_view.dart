import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';

/// 誕生日データをリスト形式で表示するコンポーネント。
class BirthdayListView extends ConsumerWidget {
  const BirthdayListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // タグでフィルタリング済みのデータを監視
    final asyncData = ref.watch(filteredBirthdaysProvider);

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      data: (birthdays) {
        if (birthdays.isEmpty) {
          return const Center(
            child: Text(
              '誕生日リストが空です',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        // 次の誕生日が近い順にソートする（あと何日かで昇順）
        final sortedBirthdays = List<BirthdayModel>.from(birthdays)
          ..sort((a, b) => a.daysUntilNextBirthday.compareTo(b.daysUntilNextBirthday));

        return ListView.builder(
          itemCount: sortedBirthdays.length,
          itemBuilder: (context, index) {
            final birthday = sortedBirthdays[index];
            final dateFormat = DateFormat('M月d日');

            // 満年齢の表示（生まれ年不明でない場合）
            String ageText = '';
            if (!birthday.isYearUnknown) {
              final age = birthday.age;
              if (age != null) {
                // 今回迎える（または迎えた）年齢を表示
                // daysUntilNextBirthday が 0 なら「今日誕生日！」のような演出も可能
                if (birthday.daysUntilNextBirthday == 0) {
                  ageText = '今日 $age 歳！';
                } else {
                  ageText = '満 $age 歳';
                }
              }
            }

            return ListTile(
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.cake,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (birthday.daysUntilNextBirthday == 0)
                    // 当日の場合はキラキラ等をつける（暫定でオレンジ枠）
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                    ),
                ],
              ),
              title: Text(
                birthday.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${dateFormat.format(birthday.date)}  (あと ${birthday.daysUntilNextBirthday} 日)',
              ),
              trailing: ageText.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ageText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                // TODO(Phase 7): 誕生日表示モーダル or 編集モーダルを開く
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${birthday.name}」の編集は Phase 7 で実装予定です')),
                );
              },
            );
          },
        );
      },
    );
  }
}
