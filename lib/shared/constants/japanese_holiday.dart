import 'package:holiday_jp/holiday_jp.dart' as holiday_jp;

/// 日本の祝日を判定するユーティリティクラス。
///
/// `holiday_jp` パッケージを使用して、指定日が祝日かどうかを判定する。
/// カレンダーの日付色分け（祝日→赤色）に使用する。
class JapaneseHoliday {
  /// 指定した日付が日本の祝日かどうかを返す。
  static bool isHoliday(DateTime date) {
    return holiday_jp.isHoliday(DateTime.utc(date.year, date.month, date.day));
  }

  /// 指定した日付の祝日名を返す。祝日でない場合は null を返す。
  static String? getHolidayName(DateTime date) {
    final holiday =
        holiday_jp.getHoliday(DateTime.utc(date.year, date.month, date.day));
    return holiday?.name;
  }
}
