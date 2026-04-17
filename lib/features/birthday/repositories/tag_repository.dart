import 'package:birthday_calendar/features/birthday/models/tag_model.dart';

/// タグのデータ操作を抽象化するインターフェース。
abstract class TagRepository {
  /// 全てのタグを名前順で取得する。
  Future<List<TagModel>> getAllTags();

  /// タグを新規登録する。
  Future<int> insertTag(String name);

  /// 指定したIDのタグを削除する。
  Future<void> deleteTag(int id);
}
