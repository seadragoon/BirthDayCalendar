/// メインビューの表示タイプ。
///
/// Footer のタブ切り替えで使用する。
enum ViewType {
  schedule('スケジュール'),
  birthday('誕生日');

  const ViewType(this.label);

  /// UI表示用の日本語ラベル
  final String label;
}
