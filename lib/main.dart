import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
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
      home: const Scaffold(
        body: Center(
          child: Text('BirthDay Calendar - Phase 4 で UI を実装予定'),
        ),
      ),
    );
  }
}
