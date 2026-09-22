import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/features/widget/models/photo_countdown_widget_settings.dart';
import 'package:birthday_calendar/features/widget/services/widget_sync_service.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// 写真付きカウントダウンウィジェットの設定画面モーダル。
class PhotoCountdownSettingsModal extends ConsumerStatefulWidget {
  /// 誕生日詳細画面などから特定の人を初期選択して開く場合のID
  final int? initialBirthdayId;

  const PhotoCountdownSettingsModal({
    super.key,
    this.initialBirthdayId,
  });

  @override
  ConsumerState<PhotoCountdownSettingsModal> createState() =>
      _PhotoCountdownSettingsModalState();
}

class _PhotoCountdownSettingsModalState
    extends ConsumerState<PhotoCountdownSettingsModal> {
  int? _selectedBirthdayId;
  String? _photoPath;
  bool _showAge = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(WidgetSyncService.photoCountdownSettingsKey);
    final settings = jsonStr != null
        ? PhotoCountdownWidgetSettings.fromJson(jsonStr)
        : const PhotoCountdownWidgetSettings();

    setState(() {
      _selectedBirthdayId = widget.initialBirthdayId ?? settings.birthdayId;
      _photoPath = settings.photoPath;
      _showAge = settings.showAge;
      _isLoading = false;
    });
  }

  /// アルバムから写真を選択してアプリ内ストレージに保存
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final docsDir = await getApplicationDocumentsDirectory();
      final widgetPhotoDir = Directory(p.join(docsDir.path, 'widget_photos'));
      if (!await widgetPhotoDir.exists()) {
        await widgetPhotoDir.create(recursive: true);
      }

      // 既存の古い写真があれば削除
      if (_photoPath != null) {
        final oldFile = File(_photoPath!);
        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (_) {}
        }
      }

      final ext = p.extension(pickedFile.path).isNotEmpty
          ? p.extension(pickedFile.path)
          : '.jpg';
      final targetPath = p.join(
        widgetPhotoDir.path,
        'widget_photo_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await File(pickedFile.path).copy(targetPath);

      setState(() {
        _photoPath = targetPath;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('写真の選択に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 写真を解除
  void _clearPhoto() {
    setState(() {
      _photoPath = null;
    });
  }

  /// 設定を保存してウィジェットを即時更新
  Future<void> _saveSettings() async {
    final settings = PhotoCountdownWidgetSettings(
      birthdayId: _selectedBirthdayId,
      photoPath: _photoPath,
      showAge: _showAge,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      WidgetSyncService.photoCountdownSettingsKey,
      settings.toJson(),
    );

    // ウィジェット更新要求
    await WidgetSyncService.updatePhotoCountdownWidget();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('写真付きウィジェットの設定を更新しました'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const BaseModal(
        title: '写真付きウィジェット設定',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final birthdaysAsync = ref.watch(birthdayListProvider);
    final birthdays = birthdaysAsync.valueOrNull ?? [];

    // 現在選択されている対象の誕生日を取得
    BirthdayModel? currentTarget;
    if (_selectedBirthdayId != null) {
      final matches = birthdays.where((b) => b.id == _selectedBirthdayId);
      if (matches.isNotEmpty) currentTarget = matches.first;
    }
    if (currentTarget == null && birthdays.isNotEmpty) {
      final sorted = List<BirthdayModel>.from(birthdays)
        ..sort((a, b) => a.daysUntilNextBirthday.compareTo(b.daysUntilNextBirthday));
      currentTarget = sorted.first;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return BaseModal(
      title: '写真付きウィジェット設定',
      onSave: _saveSettings,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明
            Text(
              '推し、お子さま、ペット、大切な人の写真と一緒に、誕生日までの残り日数をホーム画面でカウントダウンできます。',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // 1. 対象の誕生日選択
            _buildSectionTitle('1. カウントダウンする誕生日'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedBirthdayId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('直近の誕生日（自動追跡）'),
                        ],
                      ),
                    ),
                    ...birthdays.map((b) {
                      final days = b.daysUntilNextBirthday;
                      final daysStr = days == 0 ? '本日誕生日！' : 'あと$days日';
                      return DropdownMenuItem<int?>(
                        value: b.id,
                        child: Text('${b.name} ($daysStr)'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedBirthdayId = val;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 2. 写真の選択
            _buildSectionTitle('2. 写真の選択'),
            const SizedBox(height: 8),
            _buildPhotoPickerCard(isDark, primaryColor),

            const SizedBox(height: 28),

            // 3. オプション設定
            _buildSectionTitle('3. 表示オプション'),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('年齢を表示する', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                '「10月15日 (30歳)」のように年齢を併記します',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              value: _showAge,
              onChanged: (val) => setState(() => _showAge = val),
            ),

            const SizedBox(height: 28),

            // 4. 完成プレビュー
            _buildSectionTitle('4. ウィジェット完成プレビュー'),
            const SizedBox(height: 12),
            _buildWidgetPreview(currentTarget, isDark),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 写真選択エリアカード
  Widget _buildPhotoPickerCard(bool isDark, Color primaryColor) {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          // 写真サムネイル
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
              border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 2),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.file(
                      File(_photoPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 32),
                    )
                  : Icon(Icons.cake_outlined, size: 36, color: primaryColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? '写真を設定済み' : '写真未設定',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto ? 'アルバムから別の写真に変更できます' : 'アルバムからお気に入りの写真を選択',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: Text(hasPhoto ? '変更' : '写真を選ぶ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearPhoto,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('解除'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ウィジェットの完成予想プレビュー（2x2）
  Widget _buildWidgetPreview(BirthdayModel? target, bool isDark) {
    final name = target?.name ?? 'お名前';
    final days = target?.daysUntilNextBirthday ?? 3;
    final isToday = days == 0;
    final daysLabel = isToday ? '本日誕生日！🎉' : 'あと$days日';
    final dateStr = target != null
        ? (_showAge && target.ageThisYear != null
            ? '${target.date.month}月${target.date.day}日 (${target.ageThisYear}歳)'
            : '${target.date.month}月${target.date.day}日')
        : '10月15日 (30歳)';

    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();

    return Center(
      child: Container(
        width: 170,
        height: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 丸型写真プレビュー
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3E5F5),
                border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
              ),
              child: ClipOval(
                child: hasPhoto
                    ? Image.file(
                        File(_photoPath!),
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.cake_outlined, size: 28, color: Color(0xFF7986CB)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF212121),
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFE91E63) : const Color(0xFF3949AB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daysLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
