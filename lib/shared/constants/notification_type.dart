/// 通知タイミングの設定値。
///
/// sqfliteへの保存時は [index] を整数値として格納する。
enum NotificationType {
  none('なし'),
  atTime('開始時刻'),
  fiveMinutes('5分前'),
  fifteenMinutes('15分前'),
  thirtyMinutes('30分前'),
  oneHour('1時間前'),
  oneDay('1日前'),
  oneWeek('1週間前');

  const NotificationType(this.label);

  /// UI表示用の日本語ラベル
  final String label;

  /// 整数値（index）から [NotificationType] に変換する。
  /// 不正な値の場合はデフォルトとして [none] を返す。
  static NotificationType fromIndex(int index) {
    if (index < 0 || index >= NotificationType.values.length) {
      return NotificationType.none;
    }
    return NotificationType.values[index];
  }
}
