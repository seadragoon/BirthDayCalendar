import 'package:birthday_calendar/features/birthday/models/birthday_model.dart';

/// 誕生日データの操作を定義する抽象クラス。
///
/// UIやProvider層はこのインターフェースを通じてデータにアクセスする。
/// 具体的なデータソース（sqflite等）への依存を排除し、
/// 将来的なデータソースの切り替え（Firebase等）を容易にする。
abstract class BirthdayRepository {
  /// すべての誕生日を取得する。
  Future<List<BirthdayModel>> getAllBirthdays();

  /// 指定したタグを持つ誕生日を取得する。
  ///
  /// タグはJSON文字列として保存されているため、部分一致で検索する。
  Future<List<BirthdayModel>> getBirthdaysByTag(String tag);

  /// タグが未設定（空リスト）の誕生日を取得する。
  Future<List<BirthdayModel>> getUntaggedBirthdays();

  /// 指定したIDの誕生日を取得する。
  /// 該当するデータが無い場合は null を返す。
  Future<BirthdayModel?> getBirthdayById(int id);

  /// 誕生日を新規に追加する。
  /// 追加した誕生日の id を返す。
  Future<int> insertBirthday(BirthdayModel birthday);

  /// 既存の誕生日を更新する。
  /// 更新された行数を返す。
  Future<int> updateBirthday(BirthdayModel birthday);

  /// 指定したIDの誕生日を削除する。
  /// 削除された行数を返す。
  Future<int> deleteBirthday(int id);

  /// 名前に [query] を含む誕生日を検索する。
  Future<List<BirthdayModel>> searchBirthdays(String query);

  /// 登録されているすべてのユニークなタグを取得する。
  ///
  /// Birthday View のタグフィルター表示に使用する。
  Future<List<String>> getAllTags();
}
