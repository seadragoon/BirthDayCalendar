import 'dart:convert';

/// 誕生日のスケジュール表示に関する設定モデル。
class BirthdayDisplaySettings {
  /// スケジュール（カレンダー）に誕生日を表示するかどうか
  final bool isShowOnSchedule;

  /// 表示から除外するタグのリスト。
  /// 空文字列 '' を含む場合は「未設定（タグなし）」を表示しないことを意味する。
  final List<String> excludedTags;

  const BirthdayDisplaySettings({
    this.isShowOnSchedule = true,
    this.excludedTags = const [],
  });

  BirthdayDisplaySettings copyWith({
    bool? isShowOnSchedule,
    List<String>? excludedTags,
  }) {
    return BirthdayDisplaySettings(
      isShowOnSchedule: isShowOnSchedule ?? this.isShowOnSchedule,
      excludedTags: excludedTags ?? this.excludedTags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isShowOnSchedule': isShowOnSchedule,
      'excludedTags': excludedTags,
    };
  }

  factory BirthdayDisplaySettings.fromMap(Map<String, dynamic> map) {
    return BirthdayDisplaySettings(
      isShowOnSchedule: map['isShowOnSchedule'] as bool? ?? true,
      excludedTags: List<String>.from(map['excludedTags'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BirthdayDisplaySettings.fromJson(String source) =>
      BirthdayDisplaySettings.fromMap(jsonDecode(source));
}
