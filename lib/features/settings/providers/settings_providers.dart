import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:birthday_calendar/features/settings/models/birthday_display_settings.dart';
import 'package:birthday_calendar/shared/constants/event_color.dart';

/// 誕生日のカレンダー表示設定を管理する Provider。
final birthdayDisplaySettingsProvider =
    AsyncNotifierProvider<BirthdayDisplaySettingsNotifier, BirthdayDisplaySettings>(
  BirthdayDisplaySettingsNotifier.new,
);

/// 誕生日のカレンダー表示設定を管理・永続化する Notifier。
class BirthdayDisplaySettingsNotifier extends AsyncNotifier<BirthdayDisplaySettings> {
  static const _key = 'birthday_display_settings';

  @override
  Future<BirthdayDisplaySettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return const BirthdayDisplaySettings();
    
    try {
      return BirthdayDisplaySettings.fromJson(json);
    } catch (_) {
      return const BirthdayDisplaySettings();
    }
  }

  /// 全体表示設定を切り替える。
  Future<void> setShowOnSchedule(bool value) async {
    final current = state.valueOrNull ?? const BirthdayDisplaySettings();
    final updated = current.copyWith(isShowOnSchedule: value);
    
    state = AsyncValue.data(updated); // 即座にUIに反映
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }

  /// 特定のタグの表示/非表示を切り替える。
  /// isVisible == true の場合は除外リストから削除する。
  Future<void> toggleTagVisibility(String tag, bool isVisible) async {
    final current = state.valueOrNull ?? const BirthdayDisplaySettings();
    final excluded = List<String>.from(current.excludedTags);
    
    if (isVisible) {
      excluded.remove(tag);
    } else {
      if (!excluded.contains(tag)) {
        excluded.add(tag);
      }
    }
    
    final updated = current.copyWith(excludedTags: excluded);
    state = AsyncValue.data(updated); // 即座にUIに反映
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }

  /// スケジュール表示時のカラーを変更する。
  Future<void> setBirthdayColor(EventColor color) async {
    final current = state.valueOrNull ?? const BirthdayDisplaySettings();
    final updated = current.copyWith(colorIndex: color.index);
    
    state = AsyncValue.data(updated); // 即座にUIに反映
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, updated.toJson());
  }
}
