# AGENTS.md — AI向けプロジェクトリファレンス

> **このファイルはAIアシスタントがセッション開始時に最初に読むべきドキュメントです。**
> 最終更新: 2026-09-06

---

## 🔄 AIへの運用指示（必須）

### 参照ルール
- **毎回のセッション開始時に、このファイルを最初に読み込むこと。**
- コード変更前にこのファイルの内容を把握し、既存のアーキテクチャ・規約に沿った実装を行うこと。

### 自動更新ルール
- **ソースコードに変更を加えた場合、このファイル（AGENTS.md）も同時に更新すること。**
- 以下のいずれかに該当する変更があった場合は、対応するセクションを必ず更新する：

| 変更内容 | 更新すべきセクション |
|---------|-------------------|
| ファイルの追加・削除・リネーム | §4 ディレクトリ構成 |
| データモデルのフィールド変更 | §5 データモデル詳細 |
| Provider / Notifier の追加・変更 | §6 Provider / 状態管理マップ |
| DBテーブル・カラムの変更 | §7 DBスキーマ |
| テーマの追加・変更 | §8 きせかえテーマ |
| 画面構成やモーダルの追加・変更 | §9 画面構成 |
| 実装フェーズの進捗変化 | §10 実装状況 |
| 既知の制限の解消・新規発見 | §11 既知の制限 |
| コーディング規約の追加・変更 | §12 コーディング規約 |
| パッケージの追加・更新・削除 | §2 技術スタック |

- 更新時は `最終更新` の日付も当日の日付に変更すること。
- `PROGRESS.md` にも同様の変更がある場合はそちらも合わせて更新すること。

### 品質管理ルール（厳守）
- **ソースコードに変更を加えた後は、必ず `flutter analyze` を実行してエラーや警告がないか確認すること。**
- インポートの欠落や型エラーなど、AIの不注意によるコンパイルエラーを未然に防ぎ、常に動作可能な状態を維持すること。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| **アプリ名** | BirthDay Calendar |
| **目的** | Yahoo!カレンダー（Y!カレンダー）のUI/UXをベースとした、シンプルかつ拡張性の高いカレンダー＆誕生日管理アプリ |
| **プラットフォーム** | Android / iOS / Windows / Web（主にAndroid向け） |
| **画面方向** | 縦向き固定 |
| **言語** | Dart (Null Safety) |
| **フレームワーク** | Flutter |
| **最低Android SDK** | 21 |

---

## 2. 技術スタック

| カテゴリ | パッケージ | バージョン | 用途 |
|----------|-----------|-----------|------|
| 状態管理 | `flutter_riverpod` | ^2.6.1 | Provider / Notifier による状態管理 |
| カレンダーUI | `calendar_view` | ^1.2.0 | MonthView、日付跨ぎバー表示（一部カスタム実装） |
| 日付処理 | `intl` | ^0.20.2 | 日本語(ja_JP)フォーマット |
| ローカルDB | `sqflite` | ^2.4.1 | CRUD操作 |
| DB (デスクトップ) | `sqflite_common_ffi` | ^2.4.0+2 | Windows/Linux対応 |
| DB (Web) | `sqflite_common_ffi_web` | ^1.1.1 | Web対応 |
| パス操作 | `path` | ^1.9.1 | DBファイルパス構築 |
| 祝日判定 | `holiday_jp` | ^0.0.8 | 日本の祝日データと判定論理 |
| 旧暦・六曜 | `qreki_dart` | ^1.1.2 | 旧暦（天保暦）および六曜（大安・仏滅等）の算出 |
| ローカル永続化 | `shared_preferences` | ^2.5.5 | アプリ設定・誕生日表示設定・テーマ永続化 |
| ローカル通知 | `flutter_local_notifications` | ^18.0.1 | 予定・誕生日のローカル通知スケジュール |
| タイムゾーン | `timezone` | ^0.9.4 | 日時のタイムゾーン制御 |
| ファイル一時保存 | `path_provider` | ^2.1.5 | バックアップ一時ファイル生成 |
| 共有・外部保存 | `share_plus` | ^10.1.4 | バックアップJSONのOS共有・ファイル保存 |
| ファイル選択 | `file_picker` | ^8.1.7 | 復元用バックアップJSONファイル選択 |
| 連絡先連携 | `flutter_contacts` | ^1.1.9 | 端末連絡先からの誕生日スキャン・一括取り込み |
| 外部カレンダー連携 | `device_calendar` | ^4.3.3 | 端末/Google/iCloudカレンダーの予定取得・一括取り込み |
| ホーム画面ウィジェット | `home_widget` | ^0.7.0 | Android/iOSホーム画面ウィジェット連携・データ同期 |
| 外部リンク・メーラー | `url_launcher` | ^6.3.1 | お問い合わせメーラー起動（mailto:）およびURLオープン |
| 生体認証 | `local_auth` | ^2.3.0 | 指紋認証 / 顔認証 (Face ID / BiometricPrompt) |
| 暗号化・ハッシュ | `crypto` | ^3.0.6 | パスコードのSHA-256ソルト付きハッシュ化 |

---

## 3. アーキテクチャ

### 3.1 設計方針
- **Feature-based ディレクトリ構成**: 機能ごとにディレクトリを分離 (`calendar`, `birthday`, `settings`, `legal`, `shared`)
- **疎結合**: UI → Provider → Repository → DB の一方向依存
- **ロジック分離**: Widget内にビジネスロジックを書かず、Notifierに集約

### 3.2 データフロー
```
UI (ConsumerWidget)
  ↕ ref.watch / ref.read
Provider (Notifier / AsyncNotifier)
  ↕
Repository (抽象クラス)
  ↕
SqfliteRepository (具象クラス)
  ↕
DatabaseHelper (シングルトン)
  ↕
sqflite DB
```

---

## 4. ディレクトリ構成と全ファイル一覧

```
docs/                                            # ── ストア公開用法務ドキュメント ──
├── PRIVACY_POLICY.md                            # プライバシーポリシー全文（外部公開用Markdown）
└── TERMS_OF_SERVICE.md                          # 利用規約全文（外部公開用Markdown）

lib/
├── main.dart                                    # アプリエントリポイント（ProviderScope + MaterialApp）
│
├── features/
│   ├── calendar/                                # ── スケジュール機能 ──
│   │   ├── models/
│   │   │   ├── custom_recurrence.dart           # CustomRecurrence（高度な繰り返しルールモデル）
│   │   │   ├── device_calendar_entry.dart       # DeviceCalendarEntry（端末/Googleカレンダー予定モデル）
│   │   │   ├── edit_scope.dart                  # EditScope enum（all/thisEvent/followingEvents）
│   │   │   ├── event_model.dart                 # EventModel（toMap/fromMap/copyWith）
│   │   │   └── event_stamp.dart                 # EventStamp（スタンプモデル・プリセットカタログ）
│   │   ├── repositories/
│   │   │   ├── event_repository.dart            # EventRepository 抽象クラス
│   │   │   └── sqflite_event_repository.dart    # sqflite実装
│   │   ├── providers/
│   │   │   └── event_providers.dart             # EventsByDate/Month Notifier, 繰り返し展開, 検索Provider
│   │   ├── services/
│   │   │   └── device_calendar_service.dart     # 端末カレンダー（Google/iCloud）スキャン・予定一括取り込み
│   │   ├── views/
│   │   │   └── schedule_view.dart               # Schedule画面（MonthView + EventList統合）
│   │   └── widgets/
│   │       ├── custom_month_view.dart           # 横スワイプ可能・可変高さ・複数日バーのカスタムカレンダー（アイコン・スタンプ描画・日付長押し予定作成対応）
│   │       ├── custom_recurrence_modal.dart     # カスタム繰り返し設定モーダル
│   │       ├── device_calendar_import_modal.dart# 端末/Googleカレンダー・.ics予定インポートモーダル
│   │       ├── event_detail_modal.dart          # イベント詳細表示モーダル（読み取り専用・範囲選択編集/削除・コピー作成対応）
│   │       ├── event_list_view.dart             # 選択日付のイベントリスト（アイコン表示）
│   │       ├── event_modal.dart                 # イベント追加/編集/複製モーダル（スタンプ・アイコン選択・コピー作成対応）
│   │       ├── month_picker_sheet.dart          # 月選択ボトムシート（ヘッダータップからの年月ジャンプUI）
│   │       ├── stamp_picker_sheet.dart          # スタンプ選択モーダルシート（カテゴリ別タブ・グリッド）
│   │       └── today_bar.dart                   # 選択日付表示バー（スタンプクイック追加対応）
│   │
│   ├── birthday/                                # ── 誕生日機能 ──
│   │   ├── models/
│   │   │   ├── birthday_model.dart              # BirthdayModel（age計算, daysUntilNextBirthday）
│   │   │   └── tag_model.dart                   # TagModel（タグ管理用データモデル）
│   │   ├── repositories/
│   │   │   ├── birthday_repository.dart         # BirthdayRepository 抽象クラス
│   │   │   ├── sqflite_birthday_repository.dart # sqflite実装
│   │   │   ├── tag_repository.dart              # TagRepository 抽象クラス
│   │   │   └── sqflite_tag_repository.dart      # sqfliteタグ管理実装
│   │   ├── providers/
│   │   │   └── birthday_providers.dart          # BirthdayList Notifier, TagList, タグフィルタ, 検索
│   │   ├── views/
│   │   │   ├── birthday_view.dart               # Birthday画面（タグフィルタ + リスト統合）
│   │   │   └── tag_management_view.dart         # タグ管理画面（追加・削除・一覧）
│   │   └── widgets/
│   │       ├── birthday_detail_modal.dart       # 誕生日詳細表示モーダル（読み取り専用・編集/削除）
│   │       ├── birthday_list_view.dart          # 誕生日リスト表示（ソート・カウント・0件時インポート導線対応）
│   │       ├── birthday_modal.dart              # 誕生日追加/編集モーダル
│   │       ├── contact_import_modal.dart        # 連絡先誕生日インポートモーダル
│   │       └── tag_filter_bar.dart              # タグフィルターバー
│   │   └── services/
│   │       └── contact_import_service.dart      # 端末連絡先アクセス・誕生日抽出・重複照合
│   │
│   ├── backup/                                  # ── データ保護・バックアップ機能 ──
│   │   ├── models/
│   │   │   └── backup_data.dart                 # BackupData（JSONシリアライズ・スキーマ定義）
│   │   ├── services/
│   │   │   ├── backup_service.dart              # バックアップ生成・共有・復元・整合性検証
│   │   │   └── icalendar_service.dart           # 他カレンダー連携用（.ics形式エクスポート生成）
│   │   └── views/
│   │       └── backup_restore_modal.dart        # バックアップ＆復元UI画面（JSON/ICS出力、上書き/追加復元対応）
│   │
│   ├── widget/                                  # ── ホーム画面ウィジェット機能 ──
│   │   ├── models/
│   │   │   ├── widget_birthday_item.dart        # WidgetBirthdayItem（誕生日ウィジェット用モデル）
│   │   │   └── widget_schedule_item.dart        # WidgetScheduleItem（予定ウィジェット用モデル）
│   │   └── services/
│   │       └── widget_sync_service.dart         # ホーム画面ウィジェット連携・データ更新サービス（誕生日・予定同期）
│   │
│   ├── legal/                                   # ── 法務・ストア公開・お問い合わせ ──
│   │   ├── models/
│   │   │   └── legal_texts.dart                 # 利用規約・プライバシーポリシー全文＆セクションモデル
│   │   ├── services/
│   │   │   └── contact_service.dart             # お問い合わせメーラー起動（mailto:）・端末情報雛形生成
│   │   ├── views/
│   │   │   └── legal_document_modal.dart        # 規約・ポリシー閲覧モーダル（全文コピー対応）
│   │   └── widgets/
│   │       └── contact_dialog.dart              # お問い合わせ・ご意見ダイアログ（メーラー起動/メアドコピー）
│   │
│   ├── security/                                # ── セキュリティ・パスコード・生体認証機能 ──
│   │   ├── models/
│   │   │   └── security_settings.dart           # SecuritySettings（パスコードハッシュ/ソルト/生体認証有効フラグ）
│   │   ├── services/
│   │   │   └── security_service.dart            # 暗号ソルト/SHA-256ハッシュ化/生体認証制御
│   │   ├── providers/
│   │   │   └── security_providers.dart          # SecuritySettingsNotifier, AppLockNotifier
│   │   └── widgets/
│   │       ├── app_lock_wrapper.dart            # アプリライフサイクル連動ロック＆タスクスイッチャー目隠しシールド
│   │       ├── passcode_screen.dart             # 4桁PINテンキー入力・シェイクアニメーション・生体認証UI
│   │       └── security_settings_modal.dart     # セキュリティ設定画面（ON/OFF、変更、生体認証、自動ロック時間）
│   │
│   └── settings/                                # ── 設定機能 ──
│       ├── models/
│       │   ├── app_settings.dart                # AppSettings（通知有効/週の開始日/themeMode 等）
│       │   └── birthday_display_settings.dart   # BirthdayDisplaySettings（スケジュール連動・タグ除外・カラー）
│       ├── providers/
│       │   └── settings_providers.dart          # AppSettingsNotifier, BirthdayDisplaySettingsNotifier
│       └── widgets/
│           ├── basic_settings_modal.dart        # 基本設定モーダル（通知・セキュリティ・データ連携/バックアップ・ウィジェット）
│           ├── calendar_settings_modal.dart     # カレンダー設定モーダル（週の開始日等）
│           ├── birthday_display_settings_modal.dart # 誕生日カレンダー表示設定モーダル
│           └── theme_mode_dialog.dart           # ダークモード切り替えダイアログ（システム/ライト/ダーク）
│
└── shared/                                      # ── 共通部品 ──
    ├── constants/
    │   ├── app_constants.dart                   # アプリ定数（アプリ名、バージョン、サポートメール）
    │   ├── event_color.dart                     # EventColor enum（12色）
    │   ├── japanese_holiday.dart                # 日本の祝日判定ユーティリティ（振替休日/国民の休日対応）
    │   ├── notification_type.dart               # NotificationType enum（なし/当日/1日前/2日前/3日前/1週間前）
    │   ├── recurrence_type.dart                 # RecurrenceType enum（none/daily/weekly/monthly/yearly/weekday/custom）
    │   ├── rokuyo_util.dart                     # RokuyoUtil（旧暦・六曜計算・キャッシュユーティリティ）
    │   └── view_type.dart                       # ViewType enum（schedule/birthday）
    ├── services/
    │   └── notification_service.dart            # 通知の初期化・スケジュール制御・権限判定/リクエスト（ローカル通知）
    ├── db/
    │   └── database_helper.dart                 # DatabaseHelper シングルトン（v6 スキーマ・マイグレーション）
    ├── providers/
    │   ├── app_state_providers.dart             # selectedDate / currentMonth / viewType
    │   ├── repository_providers.dart            # EventRepository / BirthdayRepository / TagRepository Provider
    │   └── theme_provider.dart                  # ThemeNotifier（きせかえテーマ＆カラー永続化管理）
    ├── theme/
    │   └── app_theme.dart                       # AppThemeData / AppThemeType enum（standard/sakura/night）
    └── widgets/
        ├── app_shell.dart                       # Scaffold統合（Header + Main + Footer + FAB）
        ├── base_modal.dart                      # 共通Full Screen Modalヘッダー
        ├── custom_drawer.dart                   # ドロワー（きせかえ/設定/タグ管理/About）
        ├── custom_fab.dart                      # FAB（ViewType連動、モーダル起動）
        ├── custom_footer.dart                   # フッター（スケジュール/誕生日 切り替え）
        ├── custom_header.dart                   # ヘッダー（タイトル/メニュー/検索/今日ボタン）
        ├── custom_search_delegate.dart          # 検索モーダル（予定・誕生日 リアルタイム横断検索）
        ├── multi_select_dialog.dart             # 汎用複数選択ダイアログ
        └── theme_selection_modal.dart           # きせかえテーマ選択モーダル
```

---

## 5. データモデル詳細

### 5.1 EventModel (`features/calendar/models/event_model.dart`)

| フィールド | 型 | デフォルト | DB列名 | 説明 |
|-----------|-----|---------|--------|------|
| id | `int?` | null (AUTOINCREMENT) | id | 主キー |
| title | `String` | (必須) | title | イベント名 |
| startDate | `DateTime` | (必須) | start_date | 開始日時（ミリ秒） |
| endDate | `DateTime` | (必須) | end_date | 終了日時（ミリ秒） |
| isAllDay | `bool` | false | is_all_day | 終日フラグ |
| colorIndex | `EventColor` | lavender | color_index | 12色enum |
| recurrence | `RecurrenceType` | none | recurrence | 繰り返し（なし/毎日/毎週/毎月/毎年/平日/カスタム） |
| customRecurrence | `CustomRecurrence?` | null | custom_recurrence | カスタム繰り返し詳細（JSON） |
| exceptionDates | `List<DateTime>` | [] | exception_dates | 繰り返し除外日リスト（JSON） |
| notifications | `List<NotificationType>` | [none] | notification | 通知設定（JSON形式） |
| comment | `String` | '' | comment | コメント / メモ |
| icon | `String?` | null | icon | スタンプ・アイコン（絵文字等） |
| isBirthday | `bool` | false | is_birthday | 誕生日紐づきフラグ（カレンダー展開用仮想フラグ） |
| createdAt | `DateTime` | startDate | created_at | 作成日時 |
| updatedAt | `DateTime` | startDate | updated_at | 更新日時 |

### 5.2 BirthdayModel (`features/birthday/models/birthday_model.dart`)

| フィールド | 型 | デフォルト | DB列名 | 説明 |
|-----------|-----|---------|--------|------|
| id | `int?` | null (AUTOINCREMENT) | id | 主キー |
| name | `String` | (必須) | name | 名前 |
| date | `DateTime` | (必須) | date | 誕生日（ミリ秒） |
| isYearUnknown | `bool` | false | is_year_unknown | 生まれ年不明フラグ |
| tags | `List<String>` | [] | tags | タグ（JSON文字列保存） |
| notifications | `List<NotificationType>` | [none] | notification | 通知設定（JSON形式） |
| comment | `String` | '' | comment | コメント / メモ |
| createdAt | `DateTime` | date | created_at | 作成日時 |
| updatedAt | `DateTime` | date | updated_at | 更新日時 |

**計算プロパティ:**
- `int? age` — 満年齢（isYearUnknown時はnull）
- `int? ageThisYear` — 今年の誕生日に迎える（または迎えた）年齢（isYearUnknown時はnull）
- `int daysUntilNextBirthday` — 次の誕生日までの日数

### 5.3 TagModel (`features/birthday/models/tag_model.dart`)

| フィールド | 型 | デフォルト | DB列名 | 説明 |
|-----------|-----|---------|--------|------|
| id | `int?` | null (AUTOINCREMENT) | id | 主キー |
| name | `String` | (必須) | name | タグ名（UNIQUE） |
| createdAt | `DateTime` | (必須) | created_at | 作成日時（ミリ秒） |

### 5.4 CustomRecurrence (`features/calendar/models/custom_recurrence.dart`)

| フィールド | 型 | デフォルト | 説明 |
|-----------|-----|---------|------|
| interval | `int` | 1 | 繰り返す間隔（例: 2週間ごと） |
| unit | `CustomRecurrenceUnit` | days | 単位 (days, weeks, months, years) |
| daysOfWeek | `List<int>?` | null | 曜日指定 (1=月 〜 7=日) |
| monthType | `CustomMonthType?` | null | 月指定種別 (dayOfMonth: 日付指定, nthWeekday: 第N曜日) |
| isWeekday | `bool` | false | 平日のみ（日本の祝日を除く）フラグ |
| endType | `CustomEndType` | none | 終了条件 (none: 期限なし, date: 日付指定, count: 回数指定) |
| endDate | `DateTime?` | null | 終了日 |
| count | `int?` | null | 終了回数 |

### 5.5 AppSettings (`features/settings/models/app_settings.dart`)
- `isNotificationsEnabled`: 全体通知の有効/無効
- `firstDayOfWeek`: 週の開始日（0: 日曜日, 1: 月曜日）
- `themeMode`: テーマモード（0: システム設定, 1: ライト, 2: ダーク）
- `showRokuyo`: 六曜（大安・友引など）表示フラグ（デフォルト: false）

### 5.6 BirthdayDisplaySettings (`features/settings/models/birthday_display_settings.dart`)
- `isShowOnSchedule`: スケジュール画面に誕生日を表示するか
- `excludedTags`: 表示から除外するタグのリスト（空文字 '' は「未設定」）
- `colorIndex`: スケジュール表示時の帯カラー（EventColor）

### 5.7 SecuritySettings (`features/security/models/security_settings.dart`)
- `isPasscodeEnabled`: パスコードロック有効フラグ
- `passcodeHash`: SHA-256でハッシュ化されたPIN
- `passcodeSalt`: 暗号ソルト
- `isBiometricEnabled`: 生体認証（指紋・顔認証）有効フラグ
- `autoLockIntervalSeconds`: 自動再ロック間隔（0: 即時, 60: 1分, 300: 5分）

---

## 6. Provider / 状態管理マップ

### 6.1 グローバル状態 (`shared/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `selectedDateProvider` | `StateProvider<DateTime>` | カレンダーで選択中の日付 |
| `currentMonthProvider` | `StateProvider<DateTime>` | 表示中の月 |
| `viewTypeProvider` | `StateProvider<ViewType>` | 表示モード（schedule/birthday） |
| `eventRepositoryProvider` | `Provider<EventRepository>` | EventRepository インスタンス |
| `birthdayRepositoryProvider` | `Provider<BirthdayRepository>` | BirthdayRepository インスタンス |
| `tagRepositoryProvider` | `Provider<TagRepository>` | TagRepository インスタンス |
| `themeProvider` | `AsyncNotifierProvider<ThemeNotifier, AppThemeData>` | きせかえテーマ＆カラー永続化管理 |

### 6.2 イベント関連 (`features/calendar/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `eventsByDateProvider` | `AsyncNotifierProvider<..., List<EventModel>>` | 選択日付のイベント一覧（誕生日連携含む） |
| `eventsByMonthProvider` | `AsyncNotifierProvider<..., List<EventModel>>` | 表示月のイベント一覧（カレンダーバー表示用、展開済み） |
| `eventSearchProvider` | `FutureProvider.family<..., String>` | イベント検索結果 |

### 6.3 誕生日関連 (`features/birthday/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `birthdayListProvider` | `AsyncNotifierProvider<..., List<BirthdayModel>>` | 全誕生日リスト |
| `tagListProvider` | `AsyncNotifierProvider<..., List<TagModel>>` | 管理タグリスト |
| `selectedTagProvider` | `StateProvider<String?>` | 選択中のタグフィルタ（null=すべて, ''=未設定） |
| `filteredBirthdaysProvider` | `Provider<AsyncValue<List<BirthdayModel>>>` | フィルタ済み誕生日リスト |
| `allTagsProvider` | `Provider<AsyncValue<List<String>>>` | 登録済みユニークタグ一覧 |
| `birthdaySearchProvider` | `FutureProvider.family<..., String>` | 誕生日検索結果 |

### 6.4 設定関連 (`features/settings/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `appSettingsProvider` | `AsyncNotifierProvider<..., AppSettings>` | アプリ全体設定（通知・週開始日・ダークモード） |
| `birthdayDisplaySettingsProvider` | `AsyncNotifierProvider<..., BirthdayDisplaySettings>` | 誕生日カレンダー表示設定 |

### 6.5 セキュリティ関連 (`features/security/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `securitySettingsProvider` | `AsyncNotifierProvider<..., SecuritySettings>` | セキュリティ設定永続化管理 |
| `appLockStateProvider` | `StateNotifierProvider<AppLockNotifier, bool>` | 現在のアプリロック状態・ライフサイクル連動再ロック |

---

## 7. DBスキーマ

### 7.1 events テーブル
```sql
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  start_date INTEGER NOT NULL,      -- ミリ秒エポック
  end_date INTEGER NOT NULL,        -- ミリ秒エポック
  is_all_day INTEGER NOT NULL DEFAULT 0,
  color_index INTEGER NOT NULL DEFAULT 8,  -- EventColor.lavender
  recurrence INTEGER NOT NULL DEFAULT 0,
  custom_recurrence TEXT,           -- カスタム繰り返し条件（JSON形式）
  exception_dates TEXT,             -- 繰り返し例外日（JSON配列）
  notification TEXT NOT NULL DEFAULT '[0]', -- 通知タイミング（JSON配列）
  comment TEXT DEFAULT '',
  icon TEXT,                        -- スタンプ・アイコン（絵文字等）
  is_birthday INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
-- INDEX: idx_events_start_date, idx_events_end_date
```

### 7.2 birthdays テーブル
```sql
CREATE TABLE birthdays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  date INTEGER NOT NULL,            -- ミリ秒エポック
  is_year_unknown INTEGER NOT NULL DEFAULT 0,
  tags TEXT DEFAULT '[]',           -- JSON文字列
  notification TEXT NOT NULL DEFAULT '[0]', -- 通知タイミング（JSON配列）
  comment TEXT DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
-- INDEX: idx_birthdays_date
```

### 7.3 tags テーブル (Version 3 追加)
```sql
CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);
```

- **DBバージョン:** 7
- **DBファイル名:** `birthday_calendar.db`
- **マイグレーション履歴:** 
  - v2: notification の JSON化
  - v3: tags テーブル追加 + デフォルトデータ投入
  - v4: 初期タグの投入補正
  - v5: birthdays に comment カラム追加
  - v6: events に custom_recurrence と exception_dates カラム追加
  - v7: events に icon カラム追加

---

## 8. きせかえテーマ & ダークモード

| テーマ名 | `AppThemeType` | primaryColor | 背景画像 |
|---------|---------------|-------------|---------|
| 標準（シンプルホワイト） | `standard` | Lavender (`#7986CB`) または 12色カスタム | なし |
| 桜（サクラ） | `sakura` | Pink 400 (`#EC407A`) | `assets/images/themes/sakura.png` |
| 夜空（ナイト） | `night` | Indigo 600 (`#3949AB`) | `assets/images/themes/night.png` |

- **永続化:** `SharedPreferences` で選択テーマおよび標準テーマのカスタムカラーを保存。
- **ダークモード:** `AppSettings` の `themeMode` (0: システム連動, 1: ライト, 2: ダーク) に連動。きせかえ画像適用時もダークモード用の透過背景色に調整。

---

## 9. 画面構成

```
┌──────────────────────────────────┐
│ CustomHeader                     │  ← メニュー / タイトル / 今日ボタン / 検索
├──────────────────────────────────┤
│                                  │
│  [Schedule View]                 │  ← MonthView + TodayBar + EventList
│       or                         │
│  [Birthday View]                 │  ← TagFilterBar + BirthdayList
│                                  │
├──────────────────────────────────┤
│ CustomFooter                     │  ← スケジュール / 誕生日 切り替えタブ
└──────────────────────────────────┘
                            [FAB]  ← 右下、ViewType連動でモーダル起動
```

### 画面・モーダル一覧
| 画面 / モーダル | ファイル | 操作・用途 |
|---------|--------|------|
| スケジュール画面 | `schedule_view.dart` | 月間カレンダー + 選択日イベント一覧 |
| イベント詳細表示 | `event_detail_modal.dart` | 予定の閲覧 / 繰り返し予定の編集・削除範囲選択 |
| イベント追加/編集 | `event_modal.dart` | CRUD + 12色選択 + バリデーション + 複数通知 + アイコン選択 |
| スタンプ選択 | `stamp_picker_sheet.dart` | カテゴリ別スタンプ・アイコン選択モーダル |
| 月選択 | `month_picker_sheet.dart` | カレンダーヘッダータップからの年月ジャンプUI（前年/翌年/1〜12月選択） |
| カスタム繰り返し設定 | `custom_recurrence_modal.dart` | 間隔・曜日・祝日除外平日・月日/週指定・終了条件 |
| 誕生日一覧画面 | `birthday_view.dart` | タグフィルター + 年齢/日数別リスト |
| 誕生日詳細表示 | `birthday_detail_modal.dart`| 誕生日の閲覧 / 編集モーダルへ遷移 / 削除 |
| 誕生日追加/編集 | `birthday_modal.dart` | CRUD + タグ複数選択 + 生まれ年不明 + メモ |
| タグ管理 | `tag_management_view.dart` | タグの一覧表示・追加・削除（フルスクリーン） |
| 基本設定 | `basic_settings_modal.dart` | 通知一括ON/OFF |
| カレンダー設定 | `calendar_settings_modal.dart` | 週の開始日切り替え（日曜/月曜） |
| 誕生日表示設定 | `birthday_display_settings_modal.dart` | スケジュール連携ON/OFF、除外タグ、表示カラー |
| ダークモード切り替え | `theme_mode_dialog.dart` | システム連動 / ライト / ダーク の切替 |
| きせかえテーマ選択 | `theme_selection_modal.dart` | 標準（カラーパレット12色）・桜・夜空テーマ選択 |
| バックアップと復元 | `backup_restore_modal.dart` | データ出力（共有/保存）・復元（上書き/追加）・.ics書き出し |
| 誕生日を取り込み | `contact_import_modal.dart` | 連絡先スキャン・誕生日一括インポート・タグ付与 |
| 外部カレンダーから取り込み | `device_calendar_import_modal.dart` | 端末/Google/iCloudカレンダー・.icsファイルの予定スキャン・重複検知・一括インポート |
| 利用規約 | `legal_document_modal.dart` | 利用規約の全文閲覧・全文コピー機能 |
| プライバシーポリシー | `legal_document_modal.dart` | 完全ローカル動作・権限利用目的・免責事項の全文閲覧・コピー機能 |
| お問い合わせ・ご意見 | `contact_dialog.dart` | サポート窓口メール案内（mailto:連携・OS/アプリ環境雛形自動挿入・メアドコピー） |
| 検索 | `custom_search_delegate.dart` | 予定・誕生日のリアルタイム横断検索 |
| 共通ヘッダー | `base_modal.dart` | ×ボタン / 決定 / 削除 / 編集 |

---

## 10. 実装状況

| Phase | 内容 | 状態 |
|-------|------|------|
| 1 | 環境構築 | ✅ 完了 |
| 2 | データモデル & Repository | ✅ 完了 |
| 3 | 状態管理（Riverpod） | ✅ 完了 |
| 4 | UI基盤レイアウト | ✅ 完了 |
| 5 | Schedule View | ✅ 完了 |
| 6 | Birthday View | ✅ 完了 |
| 7 | Full Screen Modal | ✅ 完了 |
| 8 | きせかえ機能 | ✅ 完了 |
| 9 | 仕上げ（検索/設定/静的解析） | ✅ 完了 |
| 10 | 繰り返し予定の大幅拡張（カスタム繰り返し・編集削除範囲・祝日考慮） | ✅ 完了 |
| 11 | ダークモード対応 | ✅ 完了 |
| 12 | タグ管理機能・誕生日カレンダー連動設定・通知スケジュール | ✅ 完了 |
| 13 | 予定アイコン・スタンプ機能（カレンダー表示・クイック追加） | ✅ 完了 |
| 14 | データ保護（バックアップ・復元）＆ 連絡先誕生日インポート | ✅ 完了 |
| 15 | 他カレンダー（Google/iCloud/.ics）からの予定インポート | ✅ 完了 |
| 16 | ホーム画面ウィジェット（直近誕生日カウントダウン＆直近予定一覧：4×2, 2×2, 2×3 全6種） | ✅ 完了 |
| 17 | ストア公開要件（プライバシーポリシー・利用規約・お問い合わせ窓口・メーラー連携） | ✅ 完了 |

**全体進捗: 100%** — 主要機能、全拡張機能、ホーム画面ウィジェット、およびストア公開要件（法務・問い合わせ導線）の実装・実機動作検証完了済み

---

## 11. 既知の制限・今後の拡張候補

> 詳細な機能アイデア集・ロードマップは [FEATURE_IDEAS.md](file:///d:/FlutterProject/BirthDayCalendar/FEATURE_IDEAS.md) を参照。

| 項目 | 現状 | 改善候補 |
|------|------|---------|
| テーマ永続化 | ✅ 実装済み | SharedPreferences でテーマ・カスタム色を永続化 |
| 通知機能 | ✅ 実装済み | flutter_local_notificationsによるローカル通知スケジュール |
| 設定機能 | ✅ 実装済み | 基本設定・誕生日表示設定・ダークモード設定 |
| タグ管理 | ✅ 実装済み | タグ一覧・追加・削除・誕生日紐付け |
| スタンプ・アイコン | ✅ 実装済み | 予定アイコン・スタンプのカレンダー表示・クイック追加 |
| データバックアップ | ✅ 実装済み | JSONエクスポート・共有・上書き/追加復元機能 |
| 連絡先インポート | ✅ 実装済み | 端末連絡先からの誕生日スキャン・一括取り込み |
| 外部カレンダー連携 | ✅ 実装済み | 端末/Google/iCloudカレンダー・.icsインポート |
| ホーム画面ウィジェット | ✅ 実装済み | 誕生日＆予定ウィジェット（4×2, 2×2, 2×3 全6種対応） |
| ストア公開要件 | ✅ 実装済み | プライバシーポリシー・利用規約・お問い合わせ（メール連携）導線整備 |
| プレゼント履歴メモ | 未実装 (候補) | 誕生日ごとのプレゼント・お祝い履歴の記録 |
| 六曜・旧暦表示 | 未実装 (候補) | 大安・友引などのカレンダー表示 |
| テスト | 基本テスト実装済 | Unit/Widget テスト追加（15件通過） |

---

## 12. コーディング規約

### 全般
- **言語:** すべてのコメント、docstring、UIラベルは**日本語**
- **Null Safety:** 有効（Dart 3.11.3+）
- **静的解析:** `flutter analyze` でエラー・警告ゼロを維持
- **import:** パッケージimportは `package:birthday_calendar/` を使用

### Riverpod
- CRUD操作後は `state = await AsyncValue.guard(() async { ... })` で再取得
- `ref.watch` はリアクティブ監視、`ref.read` は一回限りの読み取りに使い分け
- Notifierの `build()` 内で `ref.watch` してリアクティブ依存を確立

### Repository パターン
- 抽象クラス（インターフェース）と具象クラス（sqflite実装）を分離
- Provider経由でDI（データソース切り替え時はProviderのみ変更）

### Enum の DB保存
- `index` (整数値) としてsqfliteに保存
- `fromIndex()` ファクトリメソッドで復元（不正値はデフォルトにフォールバック）

### モデル
- `toMap()` / `fromMap()` でDB↔モデル変換
- `copyWith()` でイミュータブル更新
- `id` が null の場合は `toMap()` でMapから除外（AUTOINCREMENTに委任）

---

## 13. 関連ファイル

| ファイル | 説明 |
|---------|------|
| `FEATURE_IDEAS.md` | 機能拡張・追加アイデア集 & ロードマップ |
| `PLANNING.md` | 機能要件・UI仕様の詳細定義 |
| `PROGRESS.md` | 実装進捗の記録 |
| `pubspec.yaml` | 依存パッケージ管理 |
| `analysis_options.yaml` | 静的解析ルール |
| `sample-ui/yahoo.png` | デザイン参考画像 |

