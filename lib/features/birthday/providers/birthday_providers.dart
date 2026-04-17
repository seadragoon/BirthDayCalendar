import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';
import 'package:birthday_calendar/features/birthday/models/tag_model.dart';
import 'package:birthday_calendar/features/birthday/repositories/birthday_repository.dart';
import 'package:birthday_calendar/features/birthday/repositories/tag_repository.dart';
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

/// 管理されているタグのリストを提供するProvider。
final tagListProvider =
    AsyncNotifierProvider<TagListNotifier, List<TagModel>>(
  TagListNotifier.new,
);

/// タグのリストを管理するNotifier。
class TagListNotifier extends AsyncNotifier<List<TagModel>> {
  late TagRepository _repository;

  @override
  Future<List<TagModel>> build() async {
    _repository = ref.watch(tagRepositoryProvider);
    return _repository.getAllTags();
  }

  /// 新しいタグを追加する。
  Future<void> addTag(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertTag(name);
      return _repository.getAllTags();
    });
  }

  /// タグを削除する。
  Future<void> deleteTag(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteTag(id);
      return _repository.getAllTags();
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
/// 現在は「管理されたタグリスト（tagListProvider）」をメインソースとする。
/// 誕生日データにのみ存在するタグも含めたい場合は、ここでマージを行う。
final allTagsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final managedTagsAsync = ref.watch(tagListProvider);
  final birthdayListAsync = ref.watch(birthdayListProvider);

  return managedTagsAsync.when(
    data: (managedTags) {
      final tagsSet = managedTags.map((t) => t.name).toSet();
      
      // 念のため、既存の誕生日データに使われているタグもマージする（オプション）
      // これにより、管理画面で作成していないタグでも、過去に使っていれば選択肢に残る
      birthdayListAsync.whenData((birthdays) {
        for (final b in birthdays) {
          tagsSet.addAll(b.tags);
        }
      });

      final sortedTags = tagsSet.toList(); // 追加順（DBのオーダー）を維持
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
