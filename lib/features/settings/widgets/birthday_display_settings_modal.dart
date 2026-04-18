import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/features/settings/providers/settings_providers.dart';
import 'package:birthday_calendar/features/settings/models/birthday_display_settings.dart';
import 'package:birthday_calendar/features/birthday/providers/birthday_providers.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// 誕生日のスケジュール表示設定画面。
class BirthdayDisplaySettingsModal extends ConsumerWidget {
  const BirthdayDisplaySettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(birthdayDisplaySettingsProvider);

    return BaseModal(
      title: '【誕生日】スケジュール表示設定',
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 大項目: 表示設定
              _buildSectionHeader('表示設定'),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'スケジュールに表示',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                value: settings.isShowOnSchedule,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  ref.read(birthdayDisplaySettingsProvider.notifier).setShowOnSchedule(val);
                },
              ),
              const SizedBox(height: 32),

              // 大項目: タグ毎に設定 (全体設定がOFFの時はグレーアウト)
              Opacity(
                opacity: settings.isShowOnSchedule ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !settings.isShowOnSchedule,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('タグ毎に設定'),
                      const SizedBox(height: 8),
                      _buildTagList(ref, settings),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }

  /// セクションヘッダーを作成する
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const Divider(),
      ],
    );
  }

  /// タグ一覧（トグル付き）を作成する
  Widget _buildTagList(WidgetRef ref, BirthdayDisplaySettings settings) {
    final allTagsAsync = ref.watch(allTagsProvider);

    return allTagsAsync.when(
      data: (tags) {
        // 「未設定（タグなし）」をリストの先頭に追加
        final List<String> displayTags = ['', ...tags];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayTags.length,
          itemBuilder: (context, index) {
            final tag = displayTags[index];
            final isVisible = !settings.excludedTags.contains(tag);
            final label = tag.isEmpty ? '未設定' : tag;

            return SwitchListTile(
              title: Text(label),
              value: isVisible,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                ref.read(birthdayDisplaySettingsProvider.notifier).toggleTagVisibility(tag, val);
              },
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
