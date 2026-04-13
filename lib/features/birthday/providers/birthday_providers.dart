import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/repositories/birthday_repository.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';

/// 全誕生日データを管理するProvider。
///
/// 誕生日の追加・更新・削除時にリストを再取得する。
final birthdayListProvider =
    AsyncNotifierProvider<BirthdayListNotifier, List<BirthdayModel>>(
  BirthdayListNotifier.new,
);

/// 全誕生日データを管理するNotifier。
class BirthdayListNotifier extends AsyncNotifier<List<BirthdayModel>> {
  late BirthdayRepository _repository;

  @override
  Future<List<BirthdayModel>> build() async {
    _repository = ref.watch(birthdayRepositoryProvider);
    return _repository.getAllBirthdays();
  }

  /// 誕生日を追加し、リストを再取得する。
  Future<void> addBirthday(BirthdayModel birthday) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertBirthday(birthday);
      return _repository.getAllBirthdays();
    });
  }

  /// 誕生日を更新し、リストを再取得する。
  Future<void> updateBirthday(BirthdayModel birthday) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateBirthday(birthday);
      return _repository.getAllBirthdays();
    });
  }

  /// 誕生日を削除し、リストを再取得する。
  Future<void> deleteBirthday(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteBirthday(id);
      return _repository.getAllBirthdays();
    });
  }
}

/// 現在選択中のタグフィルターを管理するProvider。
///
/// null の場合は「すべて」を表し、全件表示する。
/// 空文字列の場合は「未設定」を表し、タグなしのデータのみ表示する。
final selectedTagProvider = StateProvider<String?>((ref) {
  return null; // デフォルト:「すべて」
});

/// タグでフィルタリングされた誕生日リストを提供するProvider。
///
/// [selectedTagProvider] と [birthdayListProvider] を監視し、
/// タグの変更に応じて自動的にフィルタリング結果を更新する。
final filteredBirthdaysProvider = Provider<AsyncValue<List<BirthdayModel>>>((ref) {
  final selectedTag = ref.watch(selectedTagProvider);
  final birthdayListAsync = ref.watch(birthdayListProvider);

  return birthdayListAsync.when(
    data: (birthdays) {
      if (selectedTag == null) {
        // 「すべて」: フィルタなし
        return AsyncValue.data(birthdays);
      } else if (selectedTag.isEmpty) {
        // 「未設定」: タグが空のもの
        return AsyncValue.data(
          birthdays.where((b) => b.tags.isEmpty).toList(),
        );
      } else {
        // 特定タグでフィルタリング
        return AsyncValue.data(
          birthdays.where((b) => b.tags.contains(selectedTag)).toList(),
        );
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// 登録されている全ユニークタグを提供するProvider。
///
/// Birthday View のタグフィルターバーの表示に使用する。
/// birthdayListProvider を監視し、データ変更時に自動更新する。
final allTagsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final birthdayListAsync = ref.watch(birthdayListProvider);

  return birthdayListAsync.when(
    data: (birthdays) {
      final tags = <String>{};
      for (final birthday in birthdays) {
        tags.addAll(birthday.tags);
      }
      final sortedTags = tags.toList()..sort();
      return AsyncValue.data(sortedTags);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// 誕生日検索結果を提供するProvider。
///
/// 検索クエリが空の場合は空リストを返す。
final birthdaySearchProvider =
    FutureProvider.family<List<BirthdayModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(birthdayRepositoryProvider);
  return repository.searchBirthdays(query);
});
