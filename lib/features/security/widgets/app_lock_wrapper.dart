import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/features/security/providers/security_providers.dart';
import 'package:birthday_calendar/features/security/widgets/passcode_screen.dart';

/// アプリ全体を覆い、ライフサイクル連動ロックおよびバックグラウンド時の
/// プライバシー保護シールドを提供するラッパーWidget。
class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // バックグラウンドまたは非アクティブ（タスクスイッチャー表示中など）
      ref.read(appLockStateProvider.notifier).onAppPaused();
      if (!_isBackground) {
        setState(() {
          _isBackground = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // アプリに復帰
      ref.read(appLockStateProvider.notifier).onAppResumed();
      if (_isBackground) {
        setState(() {
          _isBackground = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockStateProvider);
    final settingsAsync = ref.watch(securitySettingsProvider);
    final hasPasscode =
        settingsAsync.valueOrNull?.hasValidPasscode ?? false;

    // パスコードが有効な場合のみロックまたはシールドを適用
    if (!hasPasscode) {
      return widget.child;
    }

    return Stack(
      children: [
        // メインコンテンツ
        widget.child,

        // バックグラウンド時のタスクスイッチャー目隠しシールド
        if (_isBackground)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'BirthDay Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ロック中のパスコード入力画面
        if (isLocked)
          const Positioned.fill(
            child: PasscodeScreen(mode: PasscodeMode.unlock),
          ),
      ],
    );
  }
}
