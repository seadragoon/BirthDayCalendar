import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリ共通のドロワーメニュー。
///
/// 今後、設定モーダルや各種トグル（例えば「誕生日表示のON/OFF」など）を追加する。
class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('ユーザー'),
            accountEmail: Text(''),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('表示設定'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('表示設定は今後のPhaseで実装予定です')),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () {
              // TODO(Phase 7): 設定モーダルを開く
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定機能は Phase 7 で実装予定です')),
              );
            },
          ),
        ],
      ),
    );
  }
}
