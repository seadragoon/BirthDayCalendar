import 'dart:convert';

/// 誕生日のスケジュール表示に関する設定モデル。
class BirthdayDisplaySettings {
  /// スケジュール（カレンダー）に誕生日を表示するかどうか
  final bool isShowOnSchedule;

  /// 表示から除外するタグのリスト。
  /// 空文字列 '' を含む場合は「未設定（タグなし）」を表示しないことを意味する。
  final List<String> excludedTags;

  /// スケジュール表示時のカラーインデックス（EventColorのインデックス）
  final int colorIndex;

  const BirthdayDisplaySettings({
    this.isShowOnSchedule = true,
    this.excludedTags = const [],
    this.colorIndex = 5, // Default: Basil (Green)
  });

  BirthdayDisplaySettings copyWith({
    bool? isShowOnSchedule,
    List<String>? excludedTags,
    int? colorIndex,
  }) {
    return BirthdayDisplaySettings(
      isShowOnSchedule: isShowOnSchedule ?? this.isShowOnSchedule,
      excludedTags: excludedTags ?? this.excludedTags,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isShowOnSchedule': isShowOnSchedule,
      'excludedTags': excludedTags,
      'colorIndex': colorIndex,
    };
  }

  factory BirthdayDisplaySettings.fromMap(Map<String, dynamic> map) {
    return BirthdayDisplaySettings(
      isShowOnSchedule: map['isShowOnSchedule'] as bool? ?? true,
      excludedTags: List<String>.from(map['excludedTags'] ?? []),
      colorIndex: map['colorIndex'] as int? ?? 5,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BirthdayDisplaySettings.fromJson(String source) =>
      BirthdayDisplaySettings.fromMap(jsonDecode(source));
}
