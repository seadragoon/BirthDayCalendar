import 'dart:convert';

/// 写真付きカウントダウンウィジェットの設定モデル。
class PhotoCountdownWidgetSettings {
  /// 対象の誕生日ID（nullの場合は「直近の誕生日」を自動追跡）
  final int? birthdayId;

  /// ウィジェットに表示する写真のファイルパス（nullの場合はデフォルトアイコン）
  final String? photoPath;

  /// 年齢を表示するかどうか（例: "30歳"）
  final bool showAge;

  /// バッジのアクセントカラーindex（0: プライマリ, 1: ピンク, 2: ブルー 等）
  final int accentColorIndex;

  const PhotoCountdownWidgetSettings({
    this.birthdayId,
    this.photoPath,
    this.showAge = true,
    this.accentColorIndex = 0,
  });

  PhotoCountdownWidgetSettings copyWith({
    int? birthdayId,
    bool clearBirthdayId = false,
    String? photoPath,
    bool clearPhotoPath = false,
    bool? showAge,
    int? accentColorIndex,
  }) {
    return PhotoCountdownWidgetSettings(
      birthdayId: clearBirthdayId ? null : (birthdayId ?? this.birthdayId),
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      showAge: showAge ?? this.showAge,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'birthday_id': birthdayId,
      'photo_path': photoPath,
      'show_age': showAge,
      'accent_color_index': accentColorIndex,
    };
  }

  factory PhotoCountdownWidgetSettings.fromMap(Map<String, dynamic> map) {
    return PhotoCountdownWidgetSettings(
      birthdayId: map['birthday_id'] as int?,
      photoPath: map['photo_path'] as String?,
      showAge: map['show_age'] as bool? ?? true,
      accentColorIndex: map['accent_color_index'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PhotoCountdownWidgetSettings.fromJson(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return PhotoCountdownWidgetSettings.fromMap(map);
    } catch (_) {
      return const PhotoCountdownWidgetSettings();
    }
  }
}
