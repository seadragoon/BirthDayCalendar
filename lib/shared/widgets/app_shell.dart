import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/features/birthday/views/birthday_view.dart';
import 'package:birthday_calendar/features/calendar/views/schedule_view.dart';
import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/widgets/custom_drawer.dart';
import 'package:birthday_calendar/shared/widgets/custom_fab.dart';
import 'package:birthday_calendar/shared/widgets/custom_footer.dart';
import 'package:birthday_calendar/shared/widgets/custom_header.dart';

/// アプリケーションのメインとなるScaffoldを提供するWidget。
///
/// Header (AppBar), Footer (NavigationBar), FAB, Drawer を統合し、
/// [viewTypeProvider] に応じてメインボディを切り替える。
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(viewTypeProvider);

    return Scaffold(
      appBar: const CustomHeader(),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: _buildBody(viewType),
      ),
      bottomNavigationBar: const CustomFooter(),
      floatingActionButton: const CustomFab(),
    );
  }

  /// 現在の [ViewType] に対応するViewを返す。
  Widget _buildBody(ViewType viewType) {
    switch (viewType) {
      case ViewType.schedule:
        return const ScheduleView();
      case ViewType.birthday:
        return const BirthdayView();
    }
  }
}
