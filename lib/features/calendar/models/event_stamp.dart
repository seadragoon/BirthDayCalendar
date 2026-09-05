/// 予定に付与できるスタンプ・アイコンのデータモデルおよびプリセット定義。
class EventStamp {
  final String id;
  final String icon; // 絵文字
  final String label; // デフォルトの予定タイトル
  final String category; // カテゴリ名

  const EventStamp({
    required this.id,
    required this.icon,
    required this.label,
    required this.category,
  });

  /// カテゴリ一覧
  static const List<String> categories = [
    'シフト・仕事',
    '暮らし・健康',
    '食事・カフェ',
    '趣味・おでかけ',
    '重要・その他',
  ];

  /// プリセットスタンプ一覧
  static const List<EventStamp> defaultStamps = [
    // シフト・仕事 (16個)
    EventStamp(id: 'work', icon: '💼', label: '仕事', category: 'シフト・仕事'),
    EventStamp(id: 'office', icon: '🏢', label: '出社', category: 'シフト・仕事'),
    EventStamp(id: 'remote', icon: '💻', label: '在宅', category: 'シフト・仕事'),
    EventStamp(id: 'meeting', icon: '👥', label: '会議', category: 'シフト・仕事'),
    EventStamp(id: 'early_shift', icon: '☀️', label: '早番', category: 'シフト・仕事'),
    EventStamp(id: 'late_shift', icon: '🌙', label: '夜勤', category: 'シフト・仕事'),
    EventStamp(id: 'day_off', icon: '💤', label: '休み', category: 'シフト・仕事'),
    EventStamp(id: 'salary', icon: '💰', label: '給料日', category: 'シフト・仕事'),
    EventStamp(id: 'overtime', icon: '⏱️', label: '残業', category: 'シフト・仕事'),
    EventStamp(id: 'interview', icon: '👔', label: '面接', category: 'シフト・仕事'),
    EventStamp(id: 'business', icon: '🤝', label: '商談', category: 'シフト・仕事'),
    EventStamp(id: 'contract', icon: '📑', label: '契約', category: 'シフト・仕事'),
    EventStamp(id: 'school', icon: '🏫', label: '学校', category: 'シフト・仕事'),
    EventStamp(id: 'study', icon: '📚', label: '勉強', category: 'シフト・仕事'),
    EventStamp(id: 'test', icon: '📝', label: 'テスト', category: 'シフト・仕事'),
    EventStamp(id: 'graduation', icon: '🎓', label: '卒業・入学', category: 'シフト・仕事'),

    // 暮らし・健康 (16個)
    EventStamp(id: 'hospital', icon: '🏥', label: '病院', category: '暮らし・健康'),
    EventStamp(id: 'dentist', icon: '🦷', label: '歯医者', category: '暮らし・健康'),
    EventStamp(id: 'medicine', icon: '💊', label: '薬', category: '暮らし・健康'),
    EventStamp(id: 'vaccine', icon: '💉', label: '予防接種', category: '暮らし・健康'),
    EventStamp(id: 'haircut', icon: '💇', label: '美容院', category: '暮らし・健康'),
    EventStamp(id: 'nail', icon: '💅', label: 'ネイル', category: '暮らし・健康'),
    EventStamp(id: 'massage', icon: '💆', label: '整体・ケア', category: '暮らし・健康'),
    EventStamp(id: 'onsen', icon: '♨️', label: '温泉・サウナ', category: '暮らし・健康'),
    EventStamp(id: 'shopping', icon: '🛍️', label: '買い物', category: '暮らし・健康'),
    EventStamp(id: 'supermarket', icon: '🛒', label: 'スーパー', category: '暮らし・健康'),
    EventStamp(id: 'cleaning', icon: '🧹', label: '掃除', category: '暮らし・健康'),
    EventStamp(id: 'laundry', icon: '🧺', label: '洗濯', category: '暮らし・健康'),
    EventStamp(id: 'bank', icon: '🏦', label: '銀行', category: '暮らし・健康'),
    EventStamp(id: 'post_office', icon: '📮', label: '郵便局', category: '暮らし・健康'),
    EventStamp(id: 'delivery', icon: '📦', label: '配達', category: '暮らし・健康'),
    EventStamp(id: 'trash', icon: '🗑️', label: 'ゴミ出し', category: '暮らし・健康'),

    // 食事・カフェ (16個)
    EventStamp(id: 'meal', icon: '🍽️', label: 'ごはん', category: '食事・カフェ'),
    EventStamp(id: 'drinking', icon: '🍻', label: '飲み会', category: '食事・カフェ'),
    EventStamp(id: 'cafe', icon: '☕', label: 'カフェ', category: '食事・カフェ'),
    EventStamp(id: 'ramen', icon: '🍜', label: 'ラーメン', category: '食事・カフェ'),
    EventStamp(id: 'lunch', icon: '🍱', label: 'ランチ', category: '食事・カフェ'),
    EventStamp(id: 'sushi', icon: '🍣', label: '寿司', category: '食事・カフェ'),
    EventStamp(id: 'bbq', icon: '🍖', label: '焼肉・BBQ', category: '食事・カフェ'),
    EventStamp(id: 'pizza', icon: '🍕', label: 'ピザ', category: '食事・カフェ'),
    EventStamp(id: 'sweets', icon: '🍰', label: 'スイーツ', category: '食事・カフェ'),
    EventStamp(id: 'bread', icon: '🥐', label: 'パン・朝食', category: '食事・カフェ'),
    EventStamp(id: 'icecream', icon: '🍦', label: 'アイス', category: '食事・カフェ'),
    EventStamp(id: 'wine', icon: '🍷', label: 'ワイン・バー', category: '食事・カフェ'),
    EventStamp(id: 'izakaya', icon: '🍶', label: '居酒屋', category: '食事・カフェ'),
    EventStamp(id: 'cooking', icon: '🍳', label: '自炊・料理', category: '食事・カフェ'),
    EventStamp(id: 'tea', icon: '🧋', label: 'お茶・カフェ', category: '食事・カフェ'),
    EventStamp(id: 'burger', icon: '🍔', label: 'ハンバーガー', category: '食事・カフェ'),

    // 趣味・おでかけ (16個)
    EventStamp(id: 'birthday', icon: '🎂', label: '誕生日', category: '趣味・おでかけ'),
    EventStamp(id: 'date', icon: '💖', label: 'デート', category: '趣味・おでかけ'),
    EventStamp(id: 'party', icon: '🎉', label: 'イベント', category: '趣味・おでかけ'),
    EventStamp(id: 'trip', icon: '✈️', label: '旅行', category: '趣味・おでかけ'),
    EventStamp(id: 'drive', icon: '🚗', label: 'ドライブ', category: '趣味・おでかけ'),
    EventStamp(id: 'train', icon: '🚃', label: 'おでかけ', category: '趣味・おでかけ'),
    EventStamp(id: 'gym', icon: '🏋️', label: 'ジム', category: '趣味・おでかけ'),
    EventStamp(id: 'run', icon: '🏃', label: 'ランニング', category: '趣味・おでかけ'),
    EventStamp(id: 'yoga', icon: '🧘', label: 'ヨガ', category: '趣味・おでかけ'),
    EventStamp(id: 'movie', icon: '🎬', label: '映画', category: '趣味・おでかけ'),
    EventStamp(id: 'game', icon: '🎮', label: 'ゲーム', category: '趣味・おでかけ'),
    EventStamp(id: 'music', icon: '🎵', label: 'ライブ', category: '趣味・おでかけ'),
    EventStamp(id: 'karaoke', icon: '🎤', label: 'カラオケ', category: '趣味・おでかけ'),
    EventStamp(id: 'camp', icon: '🏕️', label: 'キャンプ', category: '趣味・おでかけ'),
    EventStamp(id: 'golf', icon: '⛳', label: 'ゴルフ', category: '趣味・おでかけ'),
    EventStamp(id: 'pet', icon: '🐾', label: 'ペット', category: '趣味・おでかけ'),

    // 重要・その他 (16個)
    EventStamp(id: 'important', icon: '⭐', label: '重要', category: '重要・その他'),
    EventStamp(id: 'deadline', icon: '❗', label: '締切', category: '重要・その他'),
    EventStamp(id: 'pin', icon: '📌', label: '要確認', category: '重要・その他'),
    EventStamp(id: 'skull', icon: '💀', label: 'ドクロ', category: '重要・その他'),
    EventStamp(id: 'caution', icon: '⚠️', label: '注意', category: '重要・その他'),
    EventStamp(id: 'emergency', icon: '🔥', label: '緊急', category: '重要・その他'),
    EventStamp(id: 'trouble', icon: '⚡', label: 'トラブル', category: '重要・その他'),
    EventStamp(id: 'target', icon: '🎯', label: '目標', category: '重要・その他'),
    EventStamp(id: 'anniversary', icon: '💐', label: '記念日', category: '重要・その他'),
    EventStamp(id: 'ring', icon: '💍', label: '結婚式', category: '重要・その他'),
    EventStamp(id: 'present', icon: '🎁', label: 'プレゼント', category: '重要・その他'),
    EventStamp(id: 'ticket', icon: '🎫', label: 'チケット', category: '重要・その他'),
    EventStamp(id: 'home', icon: '🏠', label: '家・引越し', category: '重要・その他'),
    EventStamp(id: 'business_trip', icon: '🧳', label: '出張', category: '重要・その他'),
    EventStamp(id: 'car_maintenance', icon: '🔧', label: '点検・修理', category: '重要・その他'),
    EventStamp(id: 'lucky', icon: '🍀', label: '幸運', category: '重要・その他'),
  ];

  /// 代表的な人気スタンプID（初期の履歴フォールバック用・16個）
  static const List<String> popularStampIds = [
    'work', 'hospital', 'day_off', 'drinking',
    'birthday', 'important', 'skull', 'shopping',
    'cafe', 'date', 'trip', 'gym',
    'deadline', 'salary', 'early_shift', 'late_shift',
  ];

  /// カテゴリ別のスタンプを取得する
  static List<EventStamp> getStampsByCategory(String category) {
    return defaultStamps.where((stamp) => stamp.category == category).toList();
  }

  /// IDから該当するEventStampを取得する（存在しない場合はnull）
  static EventStamp? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return defaultStamps.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 絵文字から該当するEventStampを取得する（存在しない場合はnull）
  static EventStamp? findByIcon(String? icon) {
    if (icon == null || icon.isEmpty) return null;
    try {
      return defaultStamps.firstWhere((s) => s.icon == icon);
    } catch (_) {
      return null;
    }
  }
}
