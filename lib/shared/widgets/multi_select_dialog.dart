import 'package:flutter/material.dart';

/// 汎用的な複数選択ダイアログ。
/// 
/// チェックボックスのリストを表示し、選択された項目のリストを返す。
class MultiSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final List<T> initialSelectedItems;
  final String title;
  final String Function(T) labelBuilder;
  final T? noneItem;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.initialSelectedItems,
    required this.title,
    required this.labelBuilder,
    this.noneItem,
  });

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          children: widget.items.map((item) {
            final isSelected = _selectedItems.contains(item);
            return CheckboxListTile(
              title: Text(widget.labelBuilder(item)),
              value: isSelected,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    if (item == widget.noneItem) {
                      // 「なし」を選択した場合は他をすべて解除
                      _selectedItems = [item];
                    } else {
                      // 「なし」以外を選択した場合は「なし」を解除
                      if (widget.noneItem != null) {
                        _selectedItems.remove(widget.noneItem);
                      }
                      _selectedItems.add(item);
                    }
                  } else {
                    _selectedItems.remove(item);
                    // 全て解除された場合に、もし noneItem が設定されていればそれを選択状態にする
                    if (_selectedItems.isEmpty && widget.noneItem != null) {
                      _selectedItems.add(widget.noneItem as T);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedItems),
          child: const Text('決定'),
        ),
      ],
    );
  }
}
