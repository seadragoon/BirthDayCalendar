/// 繰り返し予定の編集・削除を行う際の適用範囲を定義するEnum。
enum EditScope {
  /// 全ての予定を変更・削除する
  all,
  /// 選択されたこの予定のみを変更・削除する
  thisEvent,
  /// 選択された予定およびそれ以降の予定を変更・削除する
  followingEvents,
}
