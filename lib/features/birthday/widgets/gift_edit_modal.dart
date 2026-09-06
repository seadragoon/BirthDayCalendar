import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/models/gift_model.dart';
import 'package:birthday_calendar/features/birthday/providers/gift_providers.dart';

/// プレゼント・お祝いの記録を追加・編集するボトムシートモーダル。
class GiftEditModal extends ConsumerStatefulWidget {
  /// 対象の誕生日ID
  final int birthdayId;

  /// 編集対象のプレゼントデータ（nullの場合は新規作成）
  final GiftModel? existingGift;

  const GiftEditModal({
    super.key,
    required this.birthdayId,
    this.existingGift,
  });

  /// ボトムシートとしてモーダルを表示するヘルパーメソッド
  static Future<dynamic> show(
    BuildContext context, {
    required int birthdayId,
    GiftModel? existingGift,
  }) async {
    return await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftEditModal(
        birthdayId: birthdayId,
        existingGift: existingGift,
      ),
    );
  }

  @override
  ConsumerState<GiftEditModal> createState() => _GiftEditModalState();
}

class _GiftEditModalState extends ConsumerState<GiftEditModal> {
  late int _selectedYear;
  late GiftType _selectedType;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _memoController = TextEditingController();

  bool get _isEditing => widget.existingGift != null;

  @override
  void initState() {
    super.initState();
    final gift = widget.existingGift;
    if (gift != null) {
      _selectedYear = gift.year;
      _selectedType = gift.type;
      _nameController.text = gift.name;
      if (gift.price != null) {
        _priceController.text = gift.price.toString();
      }
      _memoController.text = gift.memo;
    } else {
      _selectedYear = DateTime.now().year;
      _selectedType = GiftType.give;
    }

    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final priceText = _priceController.text.trim();
    final price = priceText.isNotEmpty ? int.tryParse(priceText) : null;
    final memo = _memoController.text.trim();

    if (widget.birthdayId == 0) {
      // 未確定（新規誕生日作成中）の場合
      final gift = widget.existingGift != null
          ? widget.existingGift!.copyWith(
              year: _selectedYear,
              type: _selectedType,
              name: name,
              price: price,
              memo: memo,
            )
          : GiftModel(
              birthdayId: 0,
              year: _selectedYear,
              type: _selectedType,
              name: name,
              price: price,
              memo: memo,
            );
      if (mounted) {
        Navigator.of(context).pop(gift);
      }
      return;
    }

    if (_isEditing) {
      final updated = widget.existingGift!.copyWith(
        year: _selectedYear,
        type: _selectedType,
        name: name,
        price: price,
        memo: memo,
      );
      await ref.read(giftsByBirthdayProvider(widget.birthdayId).notifier).updateGift(updated);
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } else {
      final newGift = GiftModel(
        birthdayId: widget.birthdayId,
        year: _selectedYear,
        type: _selectedType,
        name: name,
        price: price,
        memo: memo,
      );
      await ref.read(giftsByBirthdayProvider(widget.birthdayId).notifier).addGift(newGift);
      if (mounted) {
        Navigator.of(context).pop(newGift);
      }
    }
  }

  Future<void> _onDelete() async {
    if (widget.existingGift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('プレゼント記録の削除'),
        content: Text('「${widget.existingGift!.name}」の記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (widget.birthdayId == 0) {
        Navigator.of(context).pop('deleted');
        return;
      }
      if (widget.existingGift?.id != null) {
        await ref
            .read(giftsByBirthdayProvider(widget.birthdayId).notifier)
            .deleteGift(widget.existingGift!.id!);
      }
      if (mounted) {
        Navigator.of(context).pop('deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;
    // 過去10年から来年までを選択可能
    final years = List.generate(15, (index) => currentYear + 1 - index);

    final canSave = _nameController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（タイトル・閉じる/削除ボタン）
            Row(
              children: [
                Text(
                  _isEditing ? 'プレゼント記録の編集' : 'プレゼントを記録',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: '削除',
                    onPressed: _onDelete,
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // 年の選択 & 種別チップ
            Row(
              children: [
                // 年選択ドロップダウン
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isDense: true,
                      items: years.map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y年', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 種別チップ
                Expanded(
                  child: SegmentedButton<GiftType>(
                    showSelectedIcon: false,
                    segments: GiftType.values.map((type) {
                      return ButtonSegment<GiftType>(
                        value: type,
                        label: Text(
                          '${type.emoji} ${type.label}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          softWrap: false,
                        ),
                      );
                    }).toList(),
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      setState(() => _selectedType = set.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 品名入力
            const Text(
              '品名（必須）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '例: スニーカー、ネクタイ、絵本',
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 16),

            // 金額・予算
            const Text(
              '金額・予算（任意）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                prefixText: '¥ ',
                hintText: '例: 5000',
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // メモ・反応
            const Text(
              'メモ・相手の反応（任意）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'サイズや相手の反応、次回の参考に…',
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: canSave ? _onSave : null,
                icon: const Icon(Icons.check),
                label: Text(
                  _isEditing ? '変更を保存' : '記録を追加',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
