/// 端末カレンダー（Googleカレンダー/iCloudカレンダー等）から読み込んだ予定の表示・選択用エントリモデル。
class DeviceCalendarEntry {
  final String eventId;
  final String calendarId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final String? description;
  final bool isDuplicate;
  bool isSelected;

  DeviceCalendarEntry({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isAllDay = false,
    this.description,
    this.isDuplicate = false,
    bool? isSelected,
  }) : isSelected = isSelected ?? !isDuplicate;
}
