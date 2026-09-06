import 'package:flutter/material.dart';
import 'package:qreki_dart/qreki_dart.dart';

/// 六曜（大安・友引・先勝・先負・仏滅・赤口）を判定・提供するユーティリティクラス。
class RokuyoUtil {
  RokuyoUtil._();

  /// メモ化キャッシュ（キー: YYYYMMDD の整数値）
  static final Map<int, String> _cache = {};

  /// 指定した日付の六曜文字列（例: "大安", "仏滅" 等）を取得する。
  ///
  /// 旧暦計算のオーバーヘッドを防ぐため、内部でメモ化キャッシュを行っています。
  static String getRokuyo(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final kyureki = Kyureki.fromYMD(date.year, date.month, date.day);
      final value = kyureki.rokuyouValue;
      _cache[key] = value;
      return value;
    } catch (_) {
      return '';
    }
  }

  /// 指定した日付が大安かどうかを判定する。
  static bool isTaian(DateTime date) => getRokuyo(date) == '大安';

  /// 指定した日付が仏滅かどうかを判定する。
  static bool isButsumetsu(DateTime date) => getRokuyo(date) == '仏滅';

  /// カレンダー表示用の六曜テキストカラーを取得する。
  ///
  /// - 当月外の日付: 薄いグレー
  /// - 大安: 赤系アクセントカラー
  /// - 通常: 控えめなグレー
  static Color getTextColor(
    BuildContext context,
    DateTime date, {
    required bool isCurrentMonth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isCurrentMonth) {
      return isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    }

    if (isTaian(date)) {
      return isDark ? const Color(0xFFFF8A80) : Colors.red.shade700;
    }

    return isDark ? Colors.white60 : Colors.grey.shade600;
  }
}
