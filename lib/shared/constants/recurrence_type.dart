/// イベントの繰り返し種別。
///
/// sqfliteへの保存時は [index] を整数値として格納する。
enum RecurrenceType {
  none('なし'),
  daily('毎日'),
  weekly('毎週'),
  monthly('毎月'),
  yearly('毎年'),
  weekday('平日');

  const RecurrenceType(this.label);

  /// UI表示用の日本語ラベル
  final String label;

  /// 整数値（index）から [RecurrenceType] に変換する。
  /// 不正な値の場合はデフォルトとして [none] を返す。
  static RecurrenceType fromIndex(int index) {
    if (index < 0 || index >= RecurrenceType.values.length) {
      return RecurrenceType.none;
    }
    return RecurrenceType.values[index];
  }
}
