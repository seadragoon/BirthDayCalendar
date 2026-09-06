import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:birthday_calendar/shared/constants/app_constants.dart';

/// サポート問い合わせ・メーラー連携サービス
class ContactService {
  const ContactService._();

  /// メール本文の初期雛形テキストを生成
  static String generateEmailBodyTemplate() {
    final osName = Platform.operatingSystem;
    final osVersion = Platform.operatingSystemVersion;

    return '''
--------------------------------------------------
【お問い合わせ・ご意見内容】
※ 下記にご要望や不具合の詳細をご記入ください。



--------------------------------------------------
【ご利用環境（自動入力）】
アプリ名: ${AppConstants.appName}
バージョン: ${AppConstants.appVersion}
OS: $osName ($osVersion)
--------------------------------------------------
''';
  }

  /// メールアプリを起動して問い合わせメールを作成
  static Future<bool> launchEmail() async {
    final body = generateEmailBodyTemplate();
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': AppConstants.supportEmailSubject,
        'body': body,
      },
    );

    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return success;
    } catch (_) {
      return false;
    }
  }

  /// サポートメールアドレスをクリップボードにコピー
  static Future<void> copySupportEmail() async {
    await Clipboard.setData(const ClipboardData(text: AppConstants.supportEmail));
  }
}
