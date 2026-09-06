import 'package:flutter/material.dart';

/// プレゼント・お祝いの記録種別。
enum GiftType {
  /// 自分から相手にプレゼントしたもの
  give('give', 'あげた', '🎁', Colors.orange),

  /// 相手からいただいたお祝い・お返し用
  receive('receive', 'もらった', '🎀', Colors.pink),

  /// 欲しいもの・今後のプレゼント候補
  idea('idea', '候補', '💡', Colors.amber);

  const GiftType(this.key, this.label, this.emoji, this.color);

  final String key;
  final String label;
  final String emoji;
  final MaterialColor color;

  static GiftType fromKey(String key) {
    return GiftType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => GiftType.give,
    );
  }
}

/// 誕生日ごとのプレゼント・お祝い履歴モデル。
class GiftModel {
  /// 主キー（AUTOINCREMENT）
  final int? id;

  /// 紐づく誕生日のID
  final int birthdayId;

  /// 年度（例: 2026）
  final int year;

  /// 種別（あげた / もらった / 欲しいもの・候補）
  final GiftType type;

  /// 品名（例: スニーカー、ネクタイ、絵本など）
  final String name;

  /// 金額・予算（任意）
  final int? price;

  /// メモ・相手の反応（任意）
  final String memo;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;

  GiftModel({
    this.id,
    required this.birthdayId,
    required this.year,
    required this.type,
    required this.name,
    this.price,
    this.memo = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  GiftModel copyWith({
    int? id,
    int? birthdayId,
    int? year,
    GiftType? type,
    String? name,
    int? price,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GiftModel(
      id: id ?? this.id,
      birthdayId: birthdayId ?? this.birthdayId,
      year: year ?? this.year,
      type: type ?? this.type,
      name: name ?? this.name,
      price: price ?? this.price,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// sqflite / JSON 保存用 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'birthday_id': birthdayId,
      'year': year,
      'type': type.key,
      'name': name,
      'price': price,
      'memo': memo,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// sqflite / JSON 復元用 Map
  factory GiftModel.fromMap(Map<String, dynamic> map) {
    return GiftModel(
      id: map['id'] as int?,
      birthdayId: map['birthday_id'] as int,
      year: map['year'] as int,
      type: GiftType.fromKey(map['type'] as String? ?? 'give'),
      name: map['name'] as String,
      price: map['price'] as int?,
      memo: map['memo'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  @override
  String toString() {
    return 'GiftModel(id: $id, birthdayId: $birthdayId, year: $year, type: ${type.key}, name: $name, price: $price)';
  }
}
