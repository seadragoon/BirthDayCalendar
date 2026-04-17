import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:birthday_calendar/shared/providers/theme_provider.dart';
import 'package:birthday_calendar/shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // 画面の向きを縦（Portrait）に固定（モバイル環境のみ）
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
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
class BirthdayCalendarApp extends ConsumerWidget {
  const BirthdayCalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択中のテーマを監視
    final appTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'BirthDay Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: appTheme.primaryColor,
        ),
        scaffoldBackgroundColor: appTheme.backgroundColor,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      builder: (context, child) {
        // Webでの表示崩れ（1/4サイズ、左寄せ）を防ぐため、全体を明示的に
        // 中央配置し、制約を安定させる
        return Center(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AppShell(),
    );
  }
}
