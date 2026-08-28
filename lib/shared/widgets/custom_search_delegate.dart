import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/calendar/providers/event_providers.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';
import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/features/calendar/widgets/event_detail_modal.dart';
import 'package:birthday_calendar/features/birthday/widgets/birthday_detail_modal.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';

/// リアルタイム検索を行うためのSearchDelegate。
///
/// 現在表示している [ViewType] に応じて、スケジュール検索か誕生日検索かを切り替える。
class CustomSearchDelegate extends SearchDelegate<void> {
  final ViewType viewType;

  CustomSearchDelegate({required this.viewType});

  @override
  String get searchFieldLabel => viewType == ViewType.schedule ? '予定を検索' : '誕生日を検索';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildBody();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // リアルタイム検索のため、打つたびに結果部分を表示する
    return _buildBody();
  }

  Widget _buildBody() {
    return Consumer(
      builder: (context, ref, child) {
        if (query.trim().isEmpty) {
          return const Center(child: Text('検索キーワードを入力してください', style: TextStyle(color: Colors.grey)));
        }

        // カレンダー側の誕生日設定カラー
        final birthdaySettingsAsync = ref.watch(birthdayDisplaySettingsProvider);
        final calendarBirthdayColor = birthdaySettingsAsync.maybeWhen(
          data: (settings) => EventColor.fromIndex(settings.colorIndex).color,
          orElse: () => EventColor.fromIndex(5).color, // デフォルト: Basil (Green)
        );

        if (viewType == ViewType.schedule) {
          // 予定の検索（誕生日表示ONの場合は誕生日も含まれる）
          final resultsAsync = ref.watch(eventSearchProvider(query));
          return resultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('エラー: $err')),
            data: (events) {
              if (events.isEmpty) {
                return const Center(child: Text('該当する予定が見つかりませんでした'));
              }
              return ListView.separated(
                itemCount: events.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final dateFormat = DateFormat('yyyy年M月d日 (E)', 'ja_JP');

                  return ListTile(
                    leading: event.isBirthday
                        ? CircleAvatar(
                            backgroundColor: calendarBirthdayColor.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.cake,
                              color: calendarBirthdayColor,
                              size: 20,
                            ),
                          )
                        : Container(
                            width: 10,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: event.colorIndex.color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      event.isBirthday
                          ? DateFormat('M月d日', 'ja_JP').format(event.startDate)
                          : (event.isAllDay
                              ? '${dateFormat.format(event.startDate)} (終日)'
                              : dateFormat.format(event.startDate)),
                    ),
                    onTap: () async {
                      if (event.isBirthday && event.id != null) {
                        final originalId = (event.id!.abs() / 10000).floor();
                        final birthday = await ref.read(birthdayRepositoryProvider).getBirthdayById(originalId);
                        if (birthday != null && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BirthdayDetailModal(birthday: birthday),
                              fullscreenDialog: true,
                            ),
                          );
                          return;
                        }
                      }
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EventDetailModal(event: event),
                            fullscreenDialog: true,
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        } else {
          // 誕生日の検索
          final resultsAsync = ref.watch(birthdaySearchProvider(query));
          return resultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('エラー: $err')),
            data: (birthdays) {
              if (birthdays.isEmpty) {
                return const Center(child: Text('該当する誕生日が見つかりませんでした'));
              }
              return ListView.separated(
                itemCount: birthdays.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final birthday = birthdays[index];
                  final dateFormat = birthday.isYearUnknown
                      ? DateFormat('M月d日')
                      : DateFormat('yyyy年M月d日', 'ja_JP');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: calendarBirthdayColor.withValues(alpha: 0.2),
                      child: Icon(Icons.cake, color: calendarBirthdayColor),
                    ),
                    title: Text(birthday.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(dateFormat.format(birthday.date)),
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
      },
    );
  }
}

