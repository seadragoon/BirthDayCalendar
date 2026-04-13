import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// 誕生日の追加・編集を行うフルスクリーンモーダル。
class BirthdayModal extends ConsumerStatefulWidget {
  /// 編集対象の誕生日データ。nullの場合は新規作成モード。
  final BirthdayModel? existingBirthday;

  const BirthdayModal({
    super.key,
    this.existingBirthday,
  });

  @override
  ConsumerState<BirthdayModal> createState() => _BirthdayModalState();
}

class _BirthdayModalState extends ConsumerState<BirthdayModal> {
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();

  late DateTime _date;
  bool _isYearUnknown = false;
  NotificationType _notification = NotificationType.none;

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  void _initForm() {
    final b = widget.existingBirthday;
    if (b != null) {
      _nameController.text = b.name;
      _tagsController.text = b.tags.join(', ');
      _date = b.date;
      _isYearUnknown = b.isYearUnknown;
      _notification = b.notification;
    } else {
      final now = DateTime.now();
      _date = DateTime(now.year, now.month, now.day);
    }

    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // 簡単なカンマ区切りでのタグ入力処理
    final tagsInput = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final newBirthday = BirthdayModel(
      id: widget.existingBirthday?.id,
      name: name,
      date: _date,
      isYearUnknown: _isYearUnknown,
      tags: tagsInput,
      notification: _notification,
    );

    if (widget.existingBirthday == null) {
      await ref.read(birthdayListProvider.notifier).addBirthday(newBirthday);
    } else {
      await ref.read(birthdayListProvider.notifier).updateBirthday(newBirthday);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onDelete() async {
    if (widget.existingBirthday?.id != null) {
      await ref.read(birthdayListProvider.notifier).deleteBirthday(widget.existingBirthday!.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingBirthday != null;
    final isSaveEnabled = _nameController.text.trim().isNotEmpty;

    // 年不明の場合は年を隠す
    final dateFormat = _isYearUnknown ? DateFormat('M月d日') : DateFormat('yyyy年M月d日', 'ja_JP');

    return BaseModal(
      title: isEditMode ? '誕生日の編集' : '誕生日の追加',
      isEditMode: isEditMode,
      isSaveActionEnabled: isSaveEnabled,
      onSave: _onSave,
      onDelete: _onDelete,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名前
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '名前を入力',
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              autofocus: !isEditMode,
            ),
            const Divider(),

            // 誕生日ピッカー
            const SizedBox(height: 16),
            const Text('誕生日', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(dateFormat.format(_date), style: const TextStyle(fontSize: 20)),
              ),
            ),
            
            // 年齢不詳トグル
            SwitchListTile(
              title: const Text('生まれ年が不明'),
              value: _isYearUnknown,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _isYearUnknown = val);
              },
            ),
            const Divider(),

            // タグ (簡易的なカンマ入力)
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'タグ (複数ある場合はカンマ区切り)',
                hintText: '例: 家族, 親戚, 会社',
                border: InputBorder.none,
                icon: Icon(Icons.sell),
              ),
            ),
            const Divider(),

            // 通知
            InputDecorator(
              decoration: const InputDecoration(labelText: '通知', border: InputBorder.none, icon: Icon(Icons.notifications)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NotificationType>(
                  value: _notification,
                  isDense: true,
                  items: NotificationType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                  onChanged: (val) => setState(() => _notification = val!),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
