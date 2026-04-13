import 'package:flutter/material.dart';

/// イベントに割り当て可能な12色のカラーパレット。
///
/// 各色には表示用の日本語ラベルとFlutterの[Color]値を持つ。
/// sqfliteへの保存時は [index] を整数値として格納する。
enum EventColor {
  tomato(Color(0xFFD50000), 'トマト'),
  flamingo(Color(0xFFE67C73), 'フラミンゴ'),
  tangerine(Color(0xFFF4511E), 'みかん'),
  banana(Color(0xFFF6BF26), 'バナナ'),
  sage(Color(0xFF33B679), 'セージ'),
  basil(Color(0xFF0B8043), 'バジル'),
  peacock(Color(0xFF039BE5), 'ピーコック'),
  blueberry(Color(0xFF3F51B5), 'ブルーベリー'),
  lavender(Color(0xFF7986CB), 'ラベンダー'),
  grape(Color(0xFF8E24AA), 'ぶどう'),
  graphite(Color(0xFF616161), 'グラファイト'),
  cocoa(Color(0xFF795548), 'ココア');

  const EventColor(this.color, this.label);

  /// Flutterで使用するカラー値
  final Color color;

  /// UI表示用の日本語ラベル
  final String label;

  /// 整数値（index）から [EventColor] に変換する。
  /// 不正な値の場合はデフォルトとして [peacock] を返す。
  static EventColor fromIndex(int index) {
    if (index < 0 || index >= EventColor.values.length) {
      return EventColor.peacock;
    }
    return EventColor.values[index];
  }
}
