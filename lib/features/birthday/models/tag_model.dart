/// タグのデータモデル。
///
/// 誕生日の分類に使用する。
class TagModel {
  final int? id;
  final String name;
  final DateTime createdAt;

  const TagModel({
    this.id,
    required this.name,
    required this.createdAt,
  });

  /// Map からインスタンスを生成する。
  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 保存用の Map に変換する。
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// 一部のフィールドを変更した新しいインスタンスを返す。
  TagModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
