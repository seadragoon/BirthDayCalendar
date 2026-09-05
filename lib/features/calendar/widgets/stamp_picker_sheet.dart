import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/features/calendar/models/event_stamp.dart';

/// スタンプ・アイコンを選択するためのモーダルボトムシート。
class StampPickerSheet extends StatefulWidget {
  /// 現在選択中のアイコン（絵文字）
  final String? selectedIcon;

  /// 初期表示の最近使ったスタンプリスト
  final List<EventStamp> initialRecentStamps;

  /// 初期表示のタブインデックス（履歴が空なら1、1件以上あれば0）
  final int initialIndex;

  const StampPickerSheet({
    super.key,
    this.selectedIcon,
    this.initialRecentStamps = const [],
    this.initialIndex = 0,
  });

  /// 保存された最近使用したスタンプ一覧を取得（最大16件、未登録時は空リスト）
  static Future<List<EventStamp>> getRecentStamps() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('recent_stamp_ids') ?? [];
    final loaded = <EventStamp>[];
    for (final id in ids) {
      final s = EventStamp.findById(id);
      if (s != null && !loaded.contains(s)) {
        loaded.add(s);
      }
    }
    return loaded.take(16).toList();
  }

  /// ボトムシートを表示し、選択されたスタンプ（またはnull=解除）を返すヘルパー
  static Future<EventStamp?> show(
    BuildContext context, {
    String? selectedIcon,
  }) async {
    // 履歴を取得し、空なら1つ右（index 1: シフト・仕事）、1件でもあればindex 0（よく使う）を開く
    final recentStamps = await getRecentStamps();
    final initialIndex = recentStamps.isEmpty ? 1 : 0;
    if (!context.mounted) return null;

    return showModalBottomSheet<EventStamp?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StampPickerSheet(
        selectedIcon: selectedIcon,
        initialRecentStamps: recentStamps,
        initialIndex: initialIndex,
      ),
    );
  }

  /// スタンプの使用履歴を記録する（直近16件）
  static Future<void> recordUsage(String stampId) async {
    if (stampId == 'clear' || stampId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('recent_stamp_ids') ?? [];
    ids.remove(stampId);
    ids.insert(0, stampId);
    if (ids.length > 16) {
      ids.removeRange(16, ids.length);
    }
    await prefs.setStringList('recent_stamp_ids', ids);
  }

  /// 絵文字（icon）からスタンプの使用履歴を記録する
  static Future<void> recordUsageByIcon(String icon) async {
    final stamp = EventStamp.findByIcon(icon);
    if (stamp != null) {
      await recordUsage(stamp.id);
    }
  }

  @override
  State<StampPickerSheet> createState() => _StampPickerSheetState();
}

class _StampPickerSheetState extends State<StampPickerSheet> {
  late List<EventStamp> _recentStamps;

  @override
  void initState() {
    super.initState();
    _recentStamps = List.from(widget.initialRecentStamps);
  }

  void _selectStamp(EventStamp stamp) {
    Navigator.of(context).pop(stamp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 「よく使う（時計マーク）」＋ 5カテゴリ ＝ 計6タブ
    return DefaultTabController(
      length: 1 + EventStamp.categories.length,
      initialIndex: widget.initialIndex,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
        child: Column(
          children: [
            // ハンドルバー
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ヘッダー行
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'スタンプ・アイコンを選択',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.selectedIcon != null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(const EventStamp(
                              id: 'clear',
                              icon: '',
                              label: '',
                              category: '',
                            ));
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('解除'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: '閉じる',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // カテゴリタブ
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                // 時計マーク（よく使う）タブ（テキストなし・適度な幅を持たせ右側にグレーのボーダー）
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 16),
                      Container(
                        height: 16,
                        width: 1,
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
                // 各カテゴリタブ
                ...EventStamp.categories.map((category) {
                  return Tab(text: category);
                }),
              ],
            ),

            const Divider(height: 1),

            // スタンプグリッド表示エリア
            Expanded(
              child: TabBarView(
                children: [
                  // よく使う（上位16件、空の場合は案内表示）
                  _recentStamps.isEmpty
                      ? _buildEmptyRecentView(isDark)
                      : _buildStampGrid(_recentStamps, theme, isDark),
                  // 各カテゴリのグリッド
                  ...EventStamp.categories.map((category) {
                    final stamps = EventStamp.getStampsByCategory(category);
                    return _buildStampGrid(stamps, theme, isDark);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecentView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 48,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'よく使うスタンプはまだありません',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'スタンプを使用すると、ここに上位16件が表示されます',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampGrid(List<EventStamp> stamps, ThemeData theme, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: stamps.length,
      itemBuilder: (context, index) {
        final stamp = stamps[index];
        final isSelected = widget.selectedIcon == stamp.icon;

        return InkWell(
          onTap: () => _selectStamp(stamp),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stamp.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  stamp.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
