import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/repositories/birthday_repository.dart';
import 'package:birthday_calendar/features/birthday/repositories/sqflite_birthday_repository.dart';
import 'package:birthday_calendar/features/calendar/repositories/event_repository.dart';
import 'package:birthday_calendar/features/calendar/repositories/sqflite_event_repository.dart';

/// [EventRepository] のインスタンスを提供するProvider。
///
/// 現在はsqflite実装を返す。将来Firebaseなどに切り替える場合は
/// ここの実装を差し替えるだけで済む。
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return SqfliteEventRepository();
});

/// [BirthdayRepository] のインスタンスを提供するProvider。
///
/// 現在はsqflite実装を返す。将来Firebaseなどに切り替える場合は
/// ここの実装を差し替えるだけで済む。
final birthdayRepositoryProvider = Provider<BirthdayRepository>((ref) {
  return SqfliteBirthdayRepository();
});
