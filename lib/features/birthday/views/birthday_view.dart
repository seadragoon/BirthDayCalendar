import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BirthdayView extends ConsumerWidget {
  const BirthdayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(
      child: Text('Birthday View (Phase 6 で実装)'),
    );
  }
}
