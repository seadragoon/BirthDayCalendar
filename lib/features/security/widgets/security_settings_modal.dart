import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:birthday_calendar/features/security/models/security_settings.dart';
import 'package:birthday_calendar/features/security/providers/security_providers.dart';
import 'package:birthday_calendar/features/security/services/security_service.dart';
import 'package:birthday_calendar/features/security/widgets/passcode_screen.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// セキュリティ設定（パスコードロック・生体認証）画面。
class SecuritySettingsModal extends ConsumerStatefulWidget {
  const SecuritySettingsModal({super.key});

  @override
  ConsumerState<SecuritySettingsModal> createState() =>
      _SecuritySettingsModalState();
}

class _SecuritySettingsModalState extends ConsumerState<SecuritySettingsModal> {
  bool _isBiometricsSupported = false;
  bool _isLoadingBiometricsCheck = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricsSupport();
  }

  Future<void> _checkBiometricsSupport() async {
    final supported = await SecurityService.instance.isBiometricSupported();
    if (mounted) {
      setState(() {
        _isBiometricsSupported = supported;
        _isLoadingBiometricsCheck = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(securitySettingsProvider);

    return BaseModal(
      title: 'セキュリティ設定',
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('設定の読み込みに失敗しました: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SecuritySettings settings) {
    final isPasscodeEnabled = settings.hasValidPasscode;

    String getAutoLockText(int seconds) {
      switch (seconds) {
        case 0:
          return '即時';
        case 60:
          return '1分後';
        case 300:
          return '5分後';
        default:
          return '$seconds秒後';
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'パスコード保護',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),

        // パスコードロックのON/OFF
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('パスコードロック'),
          subtitle: Text(
            isPasscodeEnabled ? 'アプリ起動・復帰時にロックされます' : '未設定（無効）',
          ),
          value: isPasscodeEnabled,
          onChanged: (value) => _togglePasscode(settings, value),
        ),

        if (isPasscodeEnabled) ...[
          // パスコードの変更
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('パスコードを変更'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePasscode,
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '生体認証 & 自動ロック',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // 生体認証スイッチ
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('生体認証（指紋・顔認証）'),
            subtitle: Text(
              _isLoadingBiometricsCheck
                  ? '対応状況を確認中...'
                  : (_isBiometricsSupported
                      ? '生体認証で素早くロックを解除できます'
                      : 'お使いの端末は生体認証に対応していません'),
            ),
            value: settings.isBiometricEnabled && _isBiometricsSupported,
            onChanged: _isBiometricsSupported ? _toggleBiometrics : null,
          ),

          // 自動再ロックの時間
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('自動ロックの時間'),
            subtitle: Text(
              'バックグラウンド移行後: ${getAutoLockText(settings.autoLockIntervalSeconds)}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAutoLockDialog(settings.autoLockIntervalSeconds),
          ),
        ],

        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '※ パスコードをお忘れになるとアプリ内のデータを復元できなくなる場合があります。バックアップ機能を活用し、定期的にデータを保存しておくことをおすすめします。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePasscode(
    SecuritySettings settings,
    bool enable,
  ) async {
    if (enable) {
      // パスコード設定ウィザードを開く
      final newPin = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const PasscodeScreen(mode: PasscodeMode.setup),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) return;
      if (newPin != null) {
        await ref.read(securitySettingsProvider.notifier).setPasscode(newPin);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスコードを設定しました'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // パスコード解除の本人確認
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const PasscodeScreen(
            mode: PasscodeMode.verify,
            customTitle: 'パスコードの解除',
          ),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) return;
      if (verified == true) {
        await ref.read(securitySettingsProvider.notifier).disablePasscode();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスコードロックを解除しました'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _changePasscode() async {
    // 1. 現在のパスコードを入力
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PasscodeScreen(
          mode: PasscodeMode.verify,
          customTitle: '現在のパスコードを入力',
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || verified != true) return;

    // 2. 新しいパスコードを設定
    final newPin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const PasscodeScreen(
          mode: PasscodeMode.setup,
          customTitle: '新しいパスコードを設定',
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;
    if (newPin != null) {
      await ref.read(securitySettingsProvider.notifier).setPasscode(newPin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスコードを変更しました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    if (enable) {
      // 一度生体認証をテスト
      final authenticated = await SecurityService.instance
          .authenticateWithBiometrics(localizedReason: '生体認証を有効にするための確認');
      if (!mounted) return;
      if (authenticated) {
        await ref
            .read(securitySettingsProvider.notifier)
            .setBiometricEnabled(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('生体認証を有効にしました'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await ref
          .read(securitySettingsProvider.notifier)
          .setBiometricEnabled(false);
    }
  }

  Future<void> _showAutoLockDialog(int currentValue) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('自動ロックの時間', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('即時'),
                subtitle: const Text('アプリを離れるとすぐにロック'),
                trailing:
                    currentValue == 0 ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(securitySettingsProvider.notifier).setAutoLockInterval(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('1分後'),
                trailing:
                    currentValue == 60 ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(securitySettingsProvider.notifier).setAutoLockInterval(60);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('5分後'),
                trailing:
                    currentValue == 300 ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  ref.read(securitySettingsProvider.notifier).setAutoLockInterval(300);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }
}
