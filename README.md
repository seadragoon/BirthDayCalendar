# BirthDay Calendar

**大切な人の誕生日と日々のスケジュールをひとつで管理できる、Flutter製のカレンダー＆誕生日管理アプリです。**

日本のカレンダーアプリらしい視認性と操作性を重視し、予定管理・誕生日カウントダウン・プレゼント履歴メモ・きせかえ・ホーム画面ウィジェット・セキュリティロック・バックアップまでを**完全ローカル完結**で設計・実装しています。

> **開発ステータス**: 主要機能およびマネタイズ基盤の実装は完了しており、現在はストア公開（Android / iOS）に向けた最終調整・実機検証を進めています。  
> **開発ツール**: 本アプリは **Google Antigravity** を活用して設計・実装・テストを行っています。  

---

## 主な機能

### カレンダー・スケジュール管理
- **カスタム月間カレンダー**: 横スワイプでの月切替、複数日跨ぎイベントバー、スタンプ・アイコン表示、日付長押しでの予定作成、ヘッダータップからの年月ジャンプシートに対応
- **日本の祝日・六曜表示**: 振替休日・国民の休日を含む祝日判定、および旧暦計算による六曜（大安・友引・仏滅など）の表示切替
- **高度な繰り返し予定**: 毎日 / 毎週 / 毎月 / 毎年 / 平日 / カスタム繰り返し（間隔・曜日・祝日除外平日・終了条件）と、繰り返し予定の編集・削除範囲選択（この予定のみ / 以降すべて / すべて）
- **入力効率化**: 既存予定の複製（コピーして作成）、予定登録時のデフォルト設定（終日・カラー・通知）、予定・誕生日のリアルタイム横断検索

### 誕生日・お祝い管理
- **誕生日一覧＆カウントダウン**: 満年齢・今年の到達年齢・「あと○日」カウントダウンを自動計算。生まれ年不明の登録や、タグによるグルーピング・絞り込みに対応
- **スケジュール連動**: カレンダー上に誕生日を自動表示（ON/OFF・除外タグ・表示カラー設定が可能）
- **プレゼント・お祝い履歴メモ**: 誕生日ごとに年度別・種別（あげた / もらった / 候補）・金額・メモを記録
- **ローカル通知**: 予定・誕生日ごとに複数タイミング（当日 / 1〜3日前 / 1週間前）でリマインダー通知

### カスタマイズ・ホーム画面ウィジェット
- **きせかえ＆ダークモード**: 標準（12色カスタム）・桜・夜空の標準テーマに加え、プレミアム限定テーマ5種（ミント・モカ・夕暮れ・ローズ・海）とシステム連動ダークモードに対応
- **写真きせかえ（オリジナル背景）**: 端末フォトライブラリから好きな写真を選択し、文字の視認性を保つ透過度スライダー付きでカレンダー背景に設定
- **Android ホーム画面ウィジェット（全8種）**:
  - 誕生日カウントダウン / 直近予定一覧（4×2, 2×2, 2×3 の計6種）
  - 推し・家族・ペットの写真（円形クロップ対応）を表示できる写真付きカウントダウンウィジェット（2×2, 4×2 の計2種）

### データ保護・外部連携・セキュリティ
- **バックアップ＆復元**: 全データ（予定・誕生日・タグ・プレゼント履歴）の JSON エクスポート / インポート（上書き・追加対応）および `.ics`（iCalendar）書き出し
- **外部データ取り込み**: 端末の連絡先からの誕生日一括スキャン＆重複照合インポート、端末 / Google / iCloud カレンダーおよび `.ics` ファイルからの予定一括取り込み
- **パスコード＆生体認証ロック**: 4桁PIN（SHA-256ソルト付きハッシュ化）、指紋・顔認証（`local_auth`）、バックグラウンド遷移時のタスクスイッチャー目隠しシールド、自動再ロック時間設定

### プレミアム・マネタイズ基盤
- **Paywall UI & 状態管理**: 月額 / 年額（7日間無料トライアル） / 買い切り（Lifetime）のハイブリッドプラン設計、選択プランに応じたCTA動的切替、購入復元（Restore）導線
- **RevenueCat 課金連携 & Google AdMob**: `purchases_flutter` によるストア決済・Offering動的価格取得・リアルタイム権限同期、`google_mobile_ads` によるバナー広告（無料ユーザー時のみ表示・Pro会員時は完全非表示）

---

## 工夫した点（技術・設計のポイント）

### 1. Feature-based アーキテクチャと疎結合なDI設計
- 機能単位（`calendar`, `birthday`, `backup`, `widget`, `security`, `premium`, `ads`, `settings`, `legal`）でディレクトリを分離し、**UI → Riverpod Notifier → 抽象 Repository / Service → sqflite / 外部SDK** の一方向データフローを徹底しています。
- Repository や `PurchaseService` / `AdService` を抽象クラスで切り出し Riverpod の Provider 経由でDIしているため、課金・広告などの外部SDK依存処理もモック差し替えによる単体・ウィジェットテストが可能です。

### 2. カレンダー描画と複雑な繰り返しロジックの自前制御
- 既製カレンダーパッケージの制約にとらわれないよう、月間カレンダー（`CustomMonthView`）をカスタム実装し、複数日跨ぎバーの段組み配置・可変高さ・スタンプ描画・六曜キャッシュ（`RokuyoUtil`）を組み込んでいます。
- 繰り返し予定は単一レコードに対して表示期間内のみ動的展開し、`exception_dates`（除外日）と `EditScope`（単発・以降・全体）を組み合わせることで、データ肥大化を防ぎつつ柔軟な編集・削除を実現しています。

### 3. ネイティブ連携（Android AppWidgetProvider）とリアルタイム同期
- `home_widget` と Android ネイティブ側（Kotlin の `AppWidgetProvider` 全8種）を組み合わせ、アプリ内のデータ変更や写真設定を即座にホーム画面ウィジェットへ反映する同期基盤（`WidgetSyncService`）を構築しています。

### 4. セキュリティとプライバシーへの配慮
- 個人情報（誕生日や予定）を外部サーバーに送信しない**完全ローカル設計**を採用し、アプリ内から利用規約・プライバシーポリシーを閲覧できる構成としています。
- パスコードは平文保存せずランダムソルト付き SHA-256 でハッシュ化し、マルチタスク画面での覗き見を防ぐ目隠しシールド（`AppLockWrapper`）をライフサイクル連動で実装しています。

### 5. リリース安全性を考慮した課金・広告設計
- APIキーや本番広告ユニットIDはコードに直書きせず、`--dart-define` によるビルド時注入を採用しています。
- 開発用プレミアム切替スイッチは `kDebugMode` ガードによりリリースビルド時に Tree Shaking で完全除外され、AdMob もデバッグビルド時は常に Google 公式テストIDへ自動切替することでポリシー違反を防止しています。

### 6. 静的解析・自動テスト・AI協働開発の品質維持
- **Google Antigravity** との協働開発にあたり、設計方針・ディレクトリ構成・コーディング規約・変更時の品質チェックルールをプロジェクト内ドキュメント（`AGENTS.md`）として明文化し、一貫したアーキテクチャを保っています。
- `flutter analyze` のエラー・警告ゼロを継続的に維持しています。
- データモデル・繰り返し・六曜・プレゼント履歴・セキュリティ・ウィジェット・プレミアムガード・Paywall・課金サービス・広告表示制御など、計 **93件の Unit / Widget テスト** を整備しています。

---

## 技術スタック

| カテゴリ | 採用技術・パッケージ | 用途 |
|---|---|---|
| **フレームワーク / 言語** | Flutter / Dart (SDK `^3.11.3`, Null Safety), Kotlin | クロスプラットフォームUI、Androidネイティブウィジェット |
| **状態管理 / DI** | `flutter_riverpod` (`^2.6.1`) | Notifier / AsyncNotifier によるリアクティブ状態管理・DI |
| **ローカルDB / 永続化** | `sqflite` (`^2.4.1`), `sqflite_common_ffi`, `shared_preferences` (`^2.5.5`) | SQLite CRUD、設定・テーマ永続化 |
| **日付・日本暦** | `intl` (`^0.20.2`), `holiday_jp` (`^0.0.8`), `qreki_dart` (`^1.1.2`), `timezone` (`^0.9.4`) | 日本語フォーマット、祝日判定、旧暦・六曜計算 |
| **通知・ウィジェット** | `flutter_local_notifications` (`^18.0.1`), `home_widget` (`^0.7.0`) | ローカル通知スケジュール、ホーム画面ウィジェット連携 |
| **外部連携・ファイル** | `flutter_contacts` (`^1.1.9`), `device_calendar` (`^4.3.3`), `share_plus` (`^10.1.4`), `file_picker` (`^8.1.7`), `image_picker` (`^1.1.2`), `url_launcher` (`^6.3.1`) | 連絡先/外部カレンダー取込、JSON/ICS共有、写真選択 |
| **セキュリティ** | `local_auth` (`^2.3.0`), `crypto` (`^3.0.6`) | 指紋/顔認証、SHA-256ソルト付きハッシュ化 |
| **課金・広告** | `purchases_flutter` (`^11.0.4`), `google_mobile_ads` (`^9.2.0`) | RevenueCat アプリ内課金・レシート検証、AdMob バナー広告 |
| **開発環境** | Google Antigravity | AIエージェントを活用した設計・実装・テスト・リファクタリング |

---

## セットアップ

### 前提環境
- Flutter SDK（Dart SDK `^3.11.3` 対応バージョン）
- Android Studio / Android SDK（Android 実機・エミュレータ実行時）
- Xcode / CocoaPods（iOS 実行時・macOS 環境のみ）

### 1. リポジトリ取得と依存パッケージ導入
```bash
git clone <repository-url>
cd BirthDayCalendar
flutter pub get
```

### 2. アプリの起動（開発モード）
APIキー未設定のまま通常のデバッグ実行が可能です（課金は開発用モック動作、広告は Google 公式テストIDが自動適用されます）。
```bash
flutter run
```

### 3. 課金・広告キーを注入してビルドする場合
RevenueCat の公開APIキーや AdMob の本番バナーIDは `--dart-define` で渡します。
```bash
flutter build appbundle --release \
  --dart-define=REVENUECAT_ANDROID_API_KEY=<your_revenuecat_android_key> \
  --dart-define=ADMOB_ANDROID_BANNER_ID=<your_admob_android_banner_id>
```

### 4. 静的解析・テスト実行
```bash
flutter analyze
flutter test
```

### 5. 別プロジェクトとしてコピー・流用する場合の差し替え箇所
- **アプリID / Bundle ID**: `android/app/build.gradle.kts`（`namespace` / `applicationId`）、`android/app/src/main/kotlin/...` のパッケージ名、`ios/Runner.xcodeproj/project.pbxproj`
- **AdMob App ID**: `android/app/src/main/AndroidManifest.xml`（`com.google.android.gms.ads.APPLICATION_ID`）および `ios/Runner/Info.plist`（`GADApplicationIdentifier`）
- **サポート連絡先・法務ドキュメント**: `lib/shared/constants/app_constants.dart`、`docs/PRIVACY_POLICY.md`、`docs/TERMS_OF_SERVICE.md`

---

## 関連ドキュメント

- [プライバシーポリシー](docs/PRIVACY_POLICY.md)
- [利用規約](docs/TERMS_OF_SERVICE.md)

---

## 権利表記

Copyright © 2026 seadragoon. All Rights Reserved.

本リポジトリのソースコードおよびアセットは個人開発プロジェクトとして公開しています。無断での商用利用・再配布・ストアへのそのままの再公開はご遠慮ください。
