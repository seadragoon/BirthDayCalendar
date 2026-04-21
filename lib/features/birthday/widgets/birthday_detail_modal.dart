import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/birthday/widgets/birthday_modal.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';
import 'package:birthday_calendar/shared/constants/notification_type.dart';

/// 誕生日詳細を表示する読み取り専用モーダル
class BirthdayDetailModal extends ConsumerStatefulWidget {
  final BirthdayModel birthday;

  const BirthdayDetailModal({super.key, required this.birthday});

  @override
  ConsumerState<BirthdayDetailModal> createState() => _BirthdayDetailModalState();
}

class _BirthdayDetailModalState extends ConsumerState<BirthdayDetailModal> {
  late BirthdayModel _currentBirthday;

  @override
  void initState() {
    super.initState();
    _currentBirthday = widget.birthday;
  }

  Future<void> _refreshBirthday() async {
    if (_currentBirthday.id != null) {
      final updatedBirthday = await ref.read(birthdayRepositoryProvider).getBirthdayById(_currentBirthday.id!);
      if (updatedBirthday != null && mounted) {
        setState(() {
          _currentBirthday = updatedBirthday;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerTitle = '誕生日の詳細';

    return BaseModal(
      title: headerTitle,
      isEditMode: true,
      onDelete: () async {
        if (_currentBirthday.id != null) {
          await ref.read(birthdayListProvider.notifier).deleteBirthday(_currentBirthday.id!);
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      customActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: '編集',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BirthdayModal(existingBirthday: _currentBirthday),
                fullscreenDialog: true,
              ),
            );
            // 編集から戻ったら最新情報を取得
            _refreshBirthday();
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アイコン & 名前
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.cake, color: Colors.pinkAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentBirthday.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            
            // 誕生日と年齢
            _buildDetailRow(
              icon: Icons.calendar_today,
              title: '誕生日',
              content: _buildBirthdayText(),
            ),
            const Divider(),

            // タグ
            if (_currentBirthday.tags.isNotEmpty) ...[
              _buildDetailRow(
                icon: Icons.local_offer_outlined,
                title: 'タグ',
                content: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentBirthday.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
            ],

            // 通知
            _buildDetailRow(
              icon: Icons.notifications_none,
              title: '通知',
              content: Text(
                _currentBirthday.notifications.isEmpty || (_currentBirthday.notifications.length == 1 && _currentBirthday.notifications.first == NotificationType.none)
                    ? 'なし'
                    : _currentBirthday.notifications.map((e) => e.label).join(', '),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Divider(),

            // メモ
            if (_currentBirthday.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                icon: Icons.notes,
                title: 'メモ',
                content: Text(
                  _currentBirthday.comment,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayText() {
    final dateFormat = _currentBirthday.isYearUnknown
        ? DateFormat('M月d日')
        : DateFormat('yyyy年M月d日', 'ja_JP');
    
    final dateStr = dateFormat.format(_currentBirthday.date);
    final ageStr = _currentBirthday.age != null ? '${_currentBirthday.age}歳' : '';
    
    final daysUntil = _currentBirthday.daysUntilNextBirthday;
    final countdownStr = daysUntil == 0 ? '今日が誕生日です！' : 'あと $daysUntil 日';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(dateStr, style: const TextStyle(fontSize: 16)),
            if (ageStr.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('($ageStr)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          countdownStr,
          style: TextStyle(
            fontSize: 13,
            color: daysUntil == 0 ? Colors.pinkAccent : Colors.grey.shade600,
            fontWeight: daysUntil == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
