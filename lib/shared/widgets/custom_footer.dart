import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:birthday_calendar/shared/constants/view_type.dart';
import 'package:birthday_calendar/shared/providers/app_state_providers.dart';
import 'package:birthday_calendar/shared/providers/theme_provider.dart';

/// アプリ共通のフッター（NavigationBar）。
///
/// カレンダー表示と誕生日リスト表示を切り替える役割を持つ。
class CustomFooter extends ConsumerWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewType = ref.watch(viewTypeProvider);
    final appTheme = ref.watch(themeProvider).requireValue;

    return Container(
      decoration: BoxDecoration(
        color: appTheme.backgroundImagePath.isEmpty ? appTheme.primaryColor : null,
        image: appTheme.backgroundImagePath.isNotEmpty
            ? DecorationImage(
                image: AssetImage(appTheme.backgroundImagePath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.2), // 文字やアイコンを見やすくするため少し暗く
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          // 背景を透明にして Container の色/画像を透過させる
          backgroundColor: Colors.transparent,
          indicatorColor: appTheme.onPrimaryColor.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(color: appTheme.onPrimaryColor, fontWeight: FontWeight.bold);
            }
            return TextStyle(color: appTheme.onPrimaryColor.withValues(alpha: 0.7));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: appTheme.onPrimaryColor);
            }
            return IconThemeData(color: appTheme.onPrimaryColor.withValues(alpha: 0.7));
          }),
        ),
        child: NavigationBar(
          selectedIndex: viewType == ViewType.schedule ? 0 : 1,
          onDestinationSelected: (index) {
            final newType = index == 0 ? ViewType.schedule : ViewType.birthday;
            ref.read(viewTypeProvider.notifier).state = newType;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'スケジュール',
            ),
            NavigationDestination(
              icon: Icon(Icons.cake_outlined),
              selectedIcon: Icon(Icons.cake),
              label: '誕生日',
            ),
          ],
        ),
      ),
    );
  }
}
