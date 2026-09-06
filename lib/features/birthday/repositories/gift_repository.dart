import 'package:birthday_calendar/features/birthday/models/gift_model.dart';

/// プレゼント・お祝い履歴のデータアクセスを抽象化するインターフェース。
abstract class GiftRepository {
  /// 指定した誕生日に紐づくプレゼント履歴を全て取得する（年度降順）
  Future<List<GiftModel>> getGiftsByBirthdayId(int birthdayId);

  /// アプリ内のすべてのプレゼント履歴を取得する（バックアップ用等）
  Future<List<GiftModel>> getAllGifts();

  /// IDでプレゼント履歴を1件取得する
  Future<GiftModel?> getGiftById(int id);

  /// 新規プレゼント履歴を追加し、生成されたIDを返す
  Future<int> insertGift(GiftModel gift);

  /// 既存のプレゼント履歴を更新し、影響を受けた行数を返す
  Future<int> updateGift(GiftModel gift);

  /// IDを指定してプレゼント履歴を削除し、影響を受けた行数を返す
  Future<int> deleteGift(int id);

  /// 指定した誕生日に紐づくプレゼント履歴を一括削除する
  Future<int> deleteGiftsByBirthdayId(int birthdayId);
}
