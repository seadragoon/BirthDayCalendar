import 'package:birthday_calendar/shared/constants/app_constants.dart';

/// 法務ドキュメント種別
enum LegalDocumentType {
  /// 利用規約
  termsOfService,

  /// プライバシーポリシー
  privacyPolicy,
}

/// 法務ドキュメントの各セクション
class LegalSection {
  final String title;
  final String body;

  const LegalSection({
    required this.title,
    required this.body,
  });
}

/// アプリ内および外部公開用の法務テキスト管理クラス
class LegalTexts {
  const LegalTexts._();

  /// 利用規約のセクション一覧を取得
  static List<LegalSection> getTermsOfService() {
    return const [
      LegalSection(
        title: '第1条（目的および適用）',
        body: '本利用規約（以下「本規約」）は、${AppConstants.appName}（以下「本アプリ」）の利用条件を定めるものです。ユーザーは、本アプリをインストールまたは利用することにより、本規約のすべての内容に同意したものとみなされます。',
      ),
      LegalSection(
        title: '第2条（利用条件および自己責任の原則）',
        body: 'ユーザーは、自己の責任において本アプリを利用するものとします。本アプリを利用して登録・管理するスケジュールや誕生日等の情報、および端末の管理は、ユーザー自身の責任において行うものとします。',
      ),
      LegalSection(
        title: '第3条（データの管理とバックアップの推奨）',
        body: '本アプリは端末内ローカルストレージ（SQLite）にデータを保存する仕様となっております。そのため、端末の故障、紛失、機種変更、OSアップデート、誤ったアンインストール等によってデータが消失した場合、開発者がデータを復元することはできません。ユーザーは、本アプリ内のバックアップ機能（ファイル出力）を活用し、定期的に自己の責任でデータのバックアップを行うものとします。',
      ),
      LegalSection(
        title: '第4条（禁止事項）',
        body: 'ユーザーは、本アプリの利用にあたり、以下の行為を行ってはならないものとします。\n・本アプリのリバースエンジニアリング、逆コンパイル、逆アセンブル等の解析行為。\n・本アプリの不具合や脆弱性を不正な目的で利用する行為。\n・法令、公序良俗に反する行為、または開発者もしくは第三者の権利を侵害する行為。',
      ),
      LegalSection(
        title: '第5条（免責事項）',
        body: '1. 開発者は、本アプリに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます）がないことを明示的にも黙示的にも保証しておりません。\n2. 開発者は、本アプリの利用に起因してユーザーに生じたあらゆる損害（データの消失、逸失利益、端末の故障などを含むがこれらに限定されません）について、故意または重過失がある場合を除き、一切の責任を負いません。',
      ),
      LegalSection(
        title: '第6条（本規約の変更）',
        body: '開発者は、必要と判断した場合には、ユーザーに個別の事前通知を行うことなく、本規約を変更することができるものとします。変更後の本規約は、本アプリ内または指定のWebサイト上に掲示された時点で効力を生じるものとし、ユーザーが本規約の変更後も本アプリを継続して利用した場合、変更後の本規約に同意したものとみなされます。',
      ),
      LegalSection(
        title: '第7条（準拠法および管轄裁判所）',
        body: '本規約の解釈および適用にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、開発者の所在地を管轄する裁判所を第一審の専属的合意管轄裁判所とします。',
      ),
    ];
  }

  /// プライバシーポリシーのセクション一覧を取得
  static List<LegalSection> getPrivacyPolicy() {
    return const [
      LegalSection(
        title: '1. はじめに（基本方針）',
        body: '${AppConstants.appName}（以下「本アプリ」）は、ユーザーの皆様の大切な個人情報およびプライバシーを極めて重要視しています。本アプリは、端末内ローカルデータベース（SQLite）で完結する設計を採用しており、ユーザーが入力または取り込んだスケジュールや誕生日データが、開発者を含む第三者の外部サーバーへ無断で送信・収集されることは一切ありません。',
      ),
      LegalSection(
        title: '2. 端末アクセス権限の利用目的',
        body: '本アプリは、利便性向上のために以下の端末権限を必要としますが、これらはすべて端末内での処理のみに使用されます。\n\n・連絡先アクセス権限（READ_CONTACTS）：端末の連絡帳に登録されている誕生日情報を本アプリに一括インポートするためにのみ使用します。連絡先データが外部に送信されることはありません。\n・カレンダーアクセス権限（READ_CALENDAR / WRITE_CALENDAR）：端末内のGoogleカレンダーやOS標準カレンダーから予定を取り込むためにのみ使用します。許可なく予定を外部へ送信することはありません。\n・通知権限（POST_NOTIFICATIONS / アラーム設定）：大切な予定や誕生日の事前通知を、端末ローカルで指定日時に発火するためにのみ使用します。',
      ),
      LegalSection(
        title: '3. データの保存場所とバックアップ',
        body: '本アプリで管理されるすべての予定、誕生日、タグ、設定データは、ユーザーの端末内ローカルストレージにのみ保存されます。ユーザーが「バックアップ」機能を利用して生成したファイル（JSON形式や.ics形式）は、ユーザー自身が指定した保存先（クラウドストレージ、メール送信等）でのみ管理されます。',
      ),
      LegalSection(
        title: '4. 個人情報の第三者提供',
        body: '本アプリは、法令に基づく正当な開示請求がある場合を除き、取得・保持する情報を第三者に提供・販売することはありません。',
      ),
      LegalSection(
        title: '5. プライバシーポリシーの改定',
        body: '開発者は、法令の変更やアプリの機能拡張に伴い、本プライバシーポリシーを改定することがあります。改定後のポリシーは本アプリ内にて掲載した時点より効力を生じるものとします。',
      ),
      LegalSection(
        title: '6. お問い合わせ窓口',
        body: '本プライバシーポリシーおよび個人情報の取り扱いに関するご質問・ご要望は、本アプリ内の「お問い合わせ・ご意見」または以下のサポートメールアドレスまでお気軽にご連絡ください。\n\nサポート窓口：${AppConstants.supportEmail}',
      ),
    ];
  }

  /// 全文プレーンテキスト生成（コピー用・外部出力用）
  static String getFullPlainText(LegalDocumentType type) {
    final isTerms = type == LegalDocumentType.termsOfService;
    final title = isTerms ? '利用規約' : 'プライバシーポリシー';
    final date = isTerms ? AppConstants.termsOfServiceLastUpdated : AppConstants.privacyPolicyLastUpdated;
    final sections = isTerms ? getTermsOfService() : getPrivacyPolicy();

    final buffer = StringBuffer();
    buffer.writeln('【$title】');
    buffer.writeln('アプリ名: ${AppConstants.appName}');
    buffer.writeln('最終改定日: $date\n');

    for (final section in sections) {
      buffer.writeln('■ ${section.title}');
      buffer.writeln('${section.body}\n');
    }

    buffer.writeln(AppConstants.copyright);
    return buffer.toString();
  }
}
