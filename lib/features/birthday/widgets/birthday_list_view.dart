import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/birthday/widgets/birthday_detail_modal.dart';
import 'package:birthday_calendar/features/birthday/widgets/contact_import_modal.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';

/// 誕生日データをリスト形式で表示するコンポーネント。
class BirthdayListView extends ConsumerWidget {
  const BirthdayListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // タグでフィルタリング済みのデータを監視
    final asyncData = ref.watch(filteredBirthdaysProvider);

    // カレンダー側で設定されている誕生日カラーを取得
    final birthdaySettingsAsync = ref.watch(birthdayDisplaySettingsProvider);
    final calendarBirthdayColor = birthdaySettingsAsync.maybeWhen(
      data: (settings) => EventColor.fromIndex(settings.colorIndex).color,
      orElse: () => EventColor.fromIndex(5).color, // デフォルト: Basil (Green)
    );

    return asyncData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      data: (birthdays) {
        if (birthdays.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cake_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '誕生日がまだ登録されていません',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ContactImportModal(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.contacts_outlined),
                    label: const Text('連絡先から誕生日を取り込む'),
                  ),
                ],
              ),
            ),
          );
        }

        // 次の誕生日が近い順にソートする（あと何日かで昇順）
        final sortedBirthdays = List<BirthdayModel>.from(birthdays)
          ..sort(
            (a, b) =>
                a.daysUntilNextBirthday.compareTo(b.daysUntilNextBirthday),
          );

        return ListView.separated(
          itemCount: sortedBirthdays.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            thickness: 0.5,
          ),
          itemBuilder: (context, index) {
            final birthday = sortedBirthdays[index];
            final dateFormat = DateFormat('M月d日');

            // 年齢の表示
            String ageText = '年齢未設定';
            if (!birthday.isYearUnknown) {
              final turningAge = birthday.ageThisYear;
              if (turningAge != null) {
                if (birthday.daysUntilNextBirthday == 0) {
                  ageText = '今日 $turningAge 歳！';
                } else {
                  ageText = '今年 $turningAge 歳';
                }
              }
            }

            // バッジのスタイル定義（未設定・通常・当日）
            final colorScheme = Theme.of(context).colorScheme;
            final isToday = birthday.daysUntilNextBirthday == 0;
            final isUnknown = birthday.isYearUnknown;

            final Color badgeBgColor;
            final Color badgeTextColor;
            final FontWeight badgeFontWeight;

            if (isUnknown) {
              badgeBgColor = colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              );
              badgeTextColor = colorScheme.onSurfaceVariant.withValues(
                alpha: 0.75,
              );
              badgeFontWeight = FontWeight.w500;
            } else if (isToday) {
              badgeBgColor = colorScheme.primary;
              badgeTextColor = colorScheme.onPrimary;
              badgeFontWeight = FontWeight.bold;
            } else {
              badgeBgColor = colorScheme.secondaryContainer;
              badgeTextColor = colorScheme.onSecondaryContainer;
              badgeFontWeight = FontWeight.bold;
            }

            return ListTile(
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: isToday
                        ? calendarBirthdayColor.withValues(alpha: 0.2)
                        : colorScheme.primaryContainer,
                    child: Icon(
                      Icons.cake,
                      color: isToday
                          ? calendarBirthdayColor
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (isToday)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: calendarBirthdayColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                birthday.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: isToday
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(birthday.date),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${dateFormat.format(birthday.date)}  (あと ${birthday.daysUntilNextBirthday} 日)',
                    ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ageText,
                  style: TextStyle(
                    fontSize: isUnknown ? 12 : 13,
                    fontWeight: badgeFontWeight,
                    color: badgeTextColor,
                  ),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BirthdayDetailModal(birthday: birthday),
                    fullscreenDialog: true,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
