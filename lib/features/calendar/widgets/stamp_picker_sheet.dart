import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/features/calendar/models/event_stamp.dart';

/// スタンプを選択するためのモーダルボトムシート。
class StampPickerSheet extends StatefulWidget {
  /// 現在選択中のスタンプ（絵文字）
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

  /// 指定したスタンプIDを使用履歴から削除する
  static Future<void> removeRecentStamp(String stampId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('recent_stamp_ids') ?? [];
    ids.remove(stampId);
    await prefs.setStringList('recent_stamp_ids', ids);
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
                    'スタンプを選択',
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
                  _buildRecentView(theme, isDark),
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

  /// 「よく使う」タブの表示（リスト表示＋長押し削除のヒント）
  Widget _buildRecentView(ThemeData theme, bool isDark) {
    if (_recentStamps.isEmpty) {
      return _buildEmptyRecentView(isDark);
    }

    return Column(
      children: [
        // 長押し削除のヒント
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '長押しで履歴から削除できます',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildStampGrid(_recentStamps, theme, isDark, isRecent: true),
        ),
      ],
    );
  }

  /// 「よく使う」からスタンプを削除する確認ダイアログ
  Future<void> _showDeleteRecentDialog(EventStamp stamp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Text(stamp.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '「${stamp.label}」を履歴から削除',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text('このスタンプを「よく使う」履歴から削除しますか？\n（カタログから消えるわけではありません）'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('削除する'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await StampPickerSheet.removeRecentStamp(stamp.id);
      setState(() {
        _recentStamps.removeWhere((s) => s.id == stamp.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stamp.icon}「${stamp.label}」を履歴から削除しました'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

  Widget _buildStampGrid(
    List<EventStamp> stamps,
    ThemeData theme,
    bool isDark, {
    bool isRecent = false,
  }) {
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

        return _StampItem(
          stamp: stamp,
          isSelected: isSelected,
          isRecent: isRecent,
          onTap: () => _selectStamp(stamp),
          onLongPress: isRecent ? () => _showDeleteRecentDialog(stamp) : null,
        );
      },
    );
  }
}

/// 押下フィードバック（縮小アニメーション＋触覚フィードバック＋波紋）を持つスタンプセル。
class _StampItem extends StatefulWidget {
  final EventStamp stamp;
  final bool isSelected;
  final bool isRecent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _StampItem({
    required this.stamp,
    required this.isSelected,
    required this.isRecent,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_StampItem> createState() => _StampItemState();
}

class _StampItemState extends State<_StampItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.88 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          onLongPress: widget.onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.onLongPress!();
                }
              : null,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(12),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.25),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          child: Ink(
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.18)
                  : (_isPressed
                      ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? theme.colorScheme.primary
                    : (_isPressed
                        ? theme.colorScheme.primary.withValues(alpha: 0.6)
                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                width: widget.isSelected || _isPressed ? 2 : 1,
              ),
              boxShadow: _isPressed
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.stamp.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.stamp.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: widget.isSelected || _isPressed ? FontWeight.bold : FontWeight.normal,
                    color: widget.isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
