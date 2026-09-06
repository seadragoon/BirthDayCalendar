import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/features/birthday/models/gift_model.dart';
import 'package:birthday_calendar/shared/providers/repository_providers.dart';

/// 特定の誕生日に紐づくプレゼント履歴を管理するNotifier
class GiftsByBirthdayNotifier extends AutoDisposeFamilyAsyncNotifier<List<GiftModel>, int> {
  @override
  Future<List<GiftModel>> build(int arg) async {
    final repo = ref.read(giftRepositoryProvider);
    return await repo.getGiftsByBirthdayId(arg);
  }

  /// 新規プレゼント履歴を追加
  Future<void> addGift(GiftModel gift) async {
    final repo = ref.read(giftRepositoryProvider);
    await repo.insertGift(gift);
    // 最新リストを取得して状態を更新
    state = AsyncValue.data(await repo.getGiftsByBirthdayId(arg));
  }

  /// 既存プレゼント履歴を更新
  Future<void> updateGift(GiftModel gift) async {
    final repo = ref.read(giftRepositoryProvider);
    await repo.updateGift(gift);
    state = AsyncValue.data(await repo.getGiftsByBirthdayId(arg));
  }

  /// プレゼント履歴を削除
  Future<void> deleteGift(int id) async {
    final repo = ref.read(giftRepositoryProvider);
    await repo.deleteGift(id);
    state = AsyncValue.data(await repo.getGiftsByBirthdayId(arg));
  }

  /// 強制リフレッシュ
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(giftRepositoryProvider);
      return await repo.getGiftsByBirthdayId(arg);
    });
  }
}

/// 特定の誕生日に紐づくプレゼント履歴リストのProvider
final giftsByBirthdayProvider =
    AutoDisposeAsyncNotifierProviderFamily<GiftsByBirthdayNotifier, List<GiftModel>, int>(
  GiftsByBirthdayNotifier.new,
);
