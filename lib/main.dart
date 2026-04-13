import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:birthday_calendar/shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Web環境での初期化
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    // Windows / Linux環境での初期化
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 日付フォーマットのロケール初期化 (ja_JP用)
  await initializeDateFormatting('ja_JP');

  runApp(
    // Riverpod の ProviderScope でアプリ全体をラップ
    const ProviderScope(
      child: BirthdayCalendarApp(),
    ),
  );
}

/// アプリのルートWidget。
///
/// 今後 Phase 4 以降で本格的なUIを実装する。
/// 現時点ではProviderScope + MaterialAppの骨格のみ。
class BirthdayCalendarApp extends StatelessWidget {
  const BirthdayCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BirthDay Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
