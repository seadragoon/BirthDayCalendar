/// 端末の連絡先から抽出した誕生日エントリー。
class ContactBirthdayEntry {
  final String contactId;
  final String name;
  final DateTime birthday;
  final bool isYearUnknown;
  final bool isAlreadyRegistered;
  bool isSelected;

  ContactBirthdayEntry({
    required this.contactId,
    required this.name,
    required this.birthday,
    required this.isYearUnknown,
    required this.isAlreadyRegistered,
    required this.isSelected,
  });
}
