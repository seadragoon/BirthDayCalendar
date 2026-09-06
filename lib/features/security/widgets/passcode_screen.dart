import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/features/security/models/security_settings.dart';
import 'package:birthday_calendar/features/security/providers/security_providers.dart';
import 'package:birthday_calendar/features/security/services/security_service.dart';

/// パスコード画面の動作モード
enum PasscodeMode {
  /// アプリ起動時のロック解除（生体認証自動トリガー対応）
  unlock,

  /// パスコード新規設定（入力 ➔ 確認再入力）
  setup,

  /// 設定変更・解除前の本人確認
  verify,
}

/// 4桁のPINテンキー入力画面。
class PasscodeScreen extends ConsumerStatefulWidget {
  final PasscodeMode mode;
  final String? customTitle;
  final VoidCallback? onUnlocked;

  const PasscodeScreen({
    super.key,
    required this.mode,
    this.customTitle,
    this.onUnlocked,
  });

  @override
  ConsumerState<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends ConsumerState<PasscodeScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _firstPin; // setupモードでの1回目の入力PIN
  String? _errorMessage;
  bool _isError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    // unlockモードの場合、生体認証が有効なら自動で呼び出す
    if (widget.mode == PasscodeMode.unlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryBiometricAuth();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    final settings = ref.read(securitySettingsProvider).valueOrNull;
    if (settings == null || !settings.isBiometricEnabled) return;

    final authenticated =
        await SecurityService.instance.authenticateWithBiometrics();
    if (authenticated && mounted) {
      HapticFeedback.mediumImpact();
      _handleUnlockSuccess();
    }
  }

  void _handleUnlockSuccess() {
    ref.read(appLockStateProvider.notifier).unlock();
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    }
    if (widget.mode != PasscodeMode.unlock && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _onKeyPressed(String value) {
    if (_enteredPin.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      _isError = false;
      _enteredPin += value;
    });

    if (_enteredPin.length == 4) {
      _handlePinComplete(_enteredPin);
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _triggerError(String message) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isError = true;
      _errorMessage = message;
    });
    await _shakeController.forward(from: 0.0);
    if (mounted) {
      setState(() {
        _enteredPin = '';
      });
    }
  }

  void _handlePinComplete(String pin) async {
    final settings = ref.read(securitySettingsProvider).valueOrNull ??
        const SecuritySettings();

    switch (widget.mode) {
      case PasscodeMode.unlock:
        final isValid = SecurityService.instance.verifyPasscode(pin, settings);
        if (isValid) {
          HapticFeedback.mediumImpact();
          _handleUnlockSuccess();
        } else {
          _triggerError('パスコードが正しくありません');
        }
        break;

      case PasscodeMode.setup:
        if (_firstPin == null) {
          // 1回目の入力完了 ➔ 2回目の確認入力へ
          HapticFeedback.mediumImpact();
          setState(() {
            _firstPin = pin;
            _enteredPin = '';
            _errorMessage = null;
          });
        } else {
          // 2回目の確認入力完了
          if (_firstPin == pin) {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(pin);
          } else {
            // 一致しない場合は最初からやり直し
            await _triggerError('パスコードが一致しませんでした。もう一度最初から入力してください');
            if (mounted) {
              setState(() {
                _firstPin = null;
              });
            }
          }
        }
        break;

      case PasscodeMode.verify:
        final isValid = SecurityService.instance.verifyPasscode(pin, settings);
        if (isValid) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true);
        } else {
          _triggerError('パスコードが正しくありません');
        }
        break;
    }
  }

  String _getTitleText() {
    if (widget.customTitle != null) return widget.customTitle!;

    switch (widget.mode) {
      case PasscodeMode.unlock:
        return 'パスコードを入力';
      case PasscodeMode.setup:
        return _firstPin == null ? '新しいパスコードを設定' : 'もう一度入力してください';
      case PasscodeMode.verify:
        return '現在のパスコードを入力';
    }
  }

  String _getSubtitleText() {
    switch (widget.mode) {
      case PasscodeMode.unlock:
        return '4桁の数字を入力してください';
      case PasscodeMode.setup:
        return _firstPin == null
            ? 'アプリを保護するための4桁の数字を入力してください'
            : '確認のため同じパスコードを入力してください';
      case PasscodeMode.verify:
        return '本人確認のため、設定されているパスコードを入力してください';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(securitySettingsProvider).valueOrNull ??
        const SecuritySettings();

    final showBiometricButton = widget.mode == PasscodeMode.unlock &&
        settings.isBiometricEnabled;

    final canCancel = widget.mode != PasscodeMode.unlock;

    return PopScope(
      canPop: canCancel,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: canCancel
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              // アイコン
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.mode == PasscodeMode.setup
                      ? Icons.lock_reset_rounded
                      : Icons.lock_outline_rounded,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // タイトル
              Text(
                _getTitleText(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // サブタイトル
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? _getSubtitleText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _errorMessage != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: _errorMessage != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4つのPINインジケーター（シェイクアニメーション付き）
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isError
                            ? theme.colorScheme.error
                            : (isFilled
                                ? theme.colorScheme.primary
                                : Colors.transparent),
                        border: Border.all(
                          color: _isError
                              ? theme.colorScheme.error
                              : (isFilled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(flex: 3),

              // テンキーグリッド
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  children: [
                    _buildKeyRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildKeyRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildKeyRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 左下: 生体認証ボタン（利用可能な場合）
                        showBiometricButton
                            ? _buildIconButton(
                                icon: Icons.fingerprint,
                                onTap: _tryBiometricAuth,
                                tooltip: '生体認証',
                              )
                            : const SizedBox(width: 72, height: 72),
                        // 中央: 0
                        _buildKeyButton('0'),
                        // 右下: 削除ボタン
                        _buildIconButton(
                          icon: Icons.backspace_outlined,
                          onTap: _onDeletePressed,
                          tooltip: '1文字削除',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeyButton(key)).toList(),
    );
  }

  Widget _buildKeyButton(String label) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPressed(label),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 72,
      child: IconButton(
        icon: Icon(icon, size: 28),
        color: theme.colorScheme.onSurface,
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}
