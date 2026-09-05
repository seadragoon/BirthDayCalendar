import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';

/// カレンダーのヘッダー日付タップ時に下から表示される月選択ボトムシート。
class MonthPickerSheet extends ConsumerStatefulWidget {
  final DateTime initialMonth;

  const MonthPickerSheet({
    super.key,
    required this.initialMonth,
  });

  /// ボトムシートを表示するヘルパーメソッド
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final currentMonth = ref.read(currentMonthProvider);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MonthPickerSheet(initialMonth: currentMonth),
    );
  }

  @override
  ConsumerState<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends ConsumerState<MonthPickerSheet> {
  late int _displayedYear;

  @override
  void initState() {
    super.initState();
    _displayedYear = widget.initialMonth.year;
  }

  void _onMonthSelected(int month) {
    HapticFeedback.lightImpact();

    // 1. 表示月（currentMonthProvider）を更新
    final newMonth = DateTime(_displayedYear, month, 1);
    ref.read(currentMonthProvider.notifier).state = newMonth;

    // 2. 選択日（selectedDateProvider）も同じ年月に同期（日のオーバーフロー防止）
    final currentSelected = ref.read(selectedDateProvider);
    final lastDayOfMonth = DateTime(_displayedYear, month + 1, 0).day;
    final newDay = currentSelected.day.clamp(1, lastDayOfMonth);
    ref.read(selectedDateProvider.notifier).state = DateTime(_displayedYear, month, newDay);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentMonth = ref.watch(currentMonthProvider);
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ハンドルバー
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 年選択ヘッダー: 「＜前年」 「現在の年」 「翌年＞」
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 前年ボタン
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _displayedYear--);
                    },
                    icon: const Icon(Icons.chevron_left, size: 20),
                    label: const Text(
                      '前年',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),

                  // 現在の年表示
                  InkWell(
                    onTap: () {
                      // 年をタップすると「今年」にリセット
                      if (_displayedYear != now.year) {
                        HapticFeedback.selectionClick();
                        setState(() => _displayedYear = now.year);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Text(
                        '$_displayedYear年',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 翌年ボタン
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _displayedYear++);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '翌年',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // 1月〜12月のグリッド (4列×3行)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected =
                      _displayedYear == currentMonth.year && month == currentMonth.month;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onMonthSelected(month),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$month月',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
