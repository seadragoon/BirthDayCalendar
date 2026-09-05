# BirthDayCalendar 実装進捗

> このファイルはプロジェクトの実装進捗を管理するものです。
> セッションを跨いでも現在の状態を把握できるようにしています。
> 最終更新: 2026-09-06

- **2026-09-06**: ホーム画面「予定ウィジェット（Schedule Widget）」を新規追加。今日〜直近の予定を最大4件（時間・タイトル・カラーバー・スタンプ対応、誕生日連動）で一覧表示する 4×2 カード型ウィジェット（ScheduleWidgetProvider, widget_schedule.xml, WidgetScheduleItem）を構築。予定の作成/編集/削除/インポート/復元時および誕生日表示設定変更時の自動データ同期を完備。
- **2026-09-06**: ホーム画面ウィジェット機能（Android AppWidget / home_widget）を実装。スマートフォンのホーム画面で「もうすぐ誕生日（あと○日、年齢、月日）」をトップにハイライトし、直近2〜3人をすっきり一覧表示するカードデザインを構築。アプリ起動時・誕生日登録/更新/削除時・バックアップ復元・連絡先インポート時の自動データ同期、および基本設定画面での手動同期・設定案内を完備。
- **2026-09-06**: 他カレンダー（Googleカレンダー/iCloudカレンダー等）および.icsファイルからの予定インポート機能（DeviceCalendarService, DeviceCalendarImportModal）を実装。端末内カレンダーアカウントの自動検出、期間指定（前後/標準/広範囲/カスタム）、既存登録との重複自動判定（登録済みバッジ）、取り込み時の帯カラー選択、一括取り込み、ドロワーへの導線配置を完了。
- **2026-09-06**: UI表示およびコード内の表記ゆれ（「スタンプ・アイコン」「アイコン」等）をすべて「スタンプ」へ統一（StampPickerSheetのヘッダータイトルを「スタンプを選択」へ変更、EventModalのツールチップを「スタンプを解除」へ統一）。
- **2026-09-06**: 設定メニュー（ドロワー）がスクロール可能であることが一目で分かるようにアフォーダンスを大幅強化（Scrollbarの常時表示 `thumbVisibility: true`、DrawerHeaderのスリム化による下部項目の見切れ・チラ見せ効果、下にコンテンツが残っている際の下端グラデーションフェード＆下矢印インジケーター動的表示）。
- **2026-09-06**: ドロワー（サイドメニュー）の構成をユーザーのメンタルモデルに合わせて5大カテゴリ（アプリ設定、カレンダー、誕生日、データ連携・バックアップ、その他）に整理。「基本設定（通知）」と「カレンダー設定（週の開始日：CalendarSettingsModal新設）」を論理的に分離し、サブタイトル付きで直感的なメニュー構成に刷新。
- **2026-09-06**: 他カレンダー（Googleカレンダー/Yahoo!カレンダー/iPhone等）向けのエクスポートとして、世界標準規格「iCalendar（.ics）形式」での書き出しオプションを実装。予定・誕生日（毎年繰り返し終日イベント）を自動変換し、共有シート経由で他社カレンダーへ一括取り込み可能に。
- **2026-09-06**: データ保護（バックアップ・復元）機能の実装。SQLiteの全データ（予定・誕生日・タグ）をJSONファイル形式で書き出し、OS共有シート経由でGoogle Driveやメール等に安全に保存・転送可能に。ファイルピッカーからの復元機能（上書き復元・追加復元の選択対応、通知一括再スケジュール）を実装。
- **2026-09-06**: 端末連絡先（Contacts）からの誕生日一括取り込み機能を実装。連絡帳に生年月日が設定されている連絡先を自動検出し、既存登録との重複判定、一括タグ付け、一括インポートに対応。誕生日リスト0件時のオンボーディングボタンおよびドロワー導線を配置。
- **2026-09-06**: カレンダー日付マス右上（CustomMonthView）のスタンプバッジ表示をオミット。日付と誕生日マークのみのシンプルで洗練されたデザインに整理し、予定バー内のスタンプ表示へ一本化。
- **2026-09-06**: カレンダー上のヘッダー日付タップ時に、下から月選択UI（MonthPickerSheet）がアニメーション表示される機能を実装（上部中央に現在の年、左右に「＜前年」「翌年＞」の移動ボタン、1月〜12月のグリッド配置、現在選択中の年月のハイライト表示、月タップによるカレンダーの即時移動と日付整合クランプ処理。不要な装飾・文字被りドットの除去）。
- **2026-09-06**: 月間カレンダー（CustomMonthView）の日付セルを長押しした際、触覚フィードバック（振動）と共にその日付を初期値とした予定作成モーダル（EventModal）を直接起動するショートカット機能を実装。
- **2026-09-05**: 予定リスト（EventListView）の各項目の縦幅・上下パディング・カラーバー高さを少し広げて緩和。縮めすぎによる窮屈感を解消し、自然な余白と見切れ表示のバランスを最適化。
- **2026-09-05**: カレンダー下部の予定リスト表示（EventListView）の各項目（ListTile）の上下余白・カラーバー高さを微調整してスリム化。予定が5件ある際に5件目が下部に見切れて表示されるようにし、スクロール可能であることが一目でわかるアフォーダンスを向上。
- **2026-09-05**: スタンプ追加後の確認モーダルに「キャンセル」アクションを追加。誤ってスタンプをタップしてしまった場合でも、ワンタップで予定追加を取り消し、履歴からも削除できるように改善。
- **2026-09-05**: スタンプ選択UIの操作感向上（タップ・長押し時に「ギュッ」と沈み込むスケール縮小アニメーション、触覚フィードバック（HapticFeedback）、波紋リプル効果、立体感のあるハイライトを実装し、「押している手応え」を大幅に強化）。
- **2026-09-05**: スタンプ選択モーダルの「よく使う（履歴）」タブにて、不要なスタンプを長押しして個別に履歴から削除できる機能（確認ダイアログ付き）を実装。
- **2026-09-05**: 通知設定UXの改善（アプリ起動時の強制権限リクエスト・設定画面遷移を廃止。初回起動時のみ「通知を有効にしますか？」確認ダイアログを表示し、以降は非表示化。基本設定で通知をONにした際に端末側で未許可の場合は案内ダイアログを表示して設定画面へ誘導する仕様を実装）。
- **2026-09-05**: スタンプ追加後の確認モーダルに対象日付バッジ（年月日・曜日・祝日名）を表示し、どの日付に追加されたかを一目で確認できるように改善。
- **2026-09-05**: カレンダー上部（TodayBar）からのスタンプクイック追加時に、予定詳細の編集確認ダイアログを表示し、ワンタップで時間・メモ・通知などの編集画面（EventModal）へ遷移できる機能を追加。
- **2026-09-05**: スタンプ選択モーダルの「よく使う（時計マーク）」タブの幅・余白を調整し、窮屈感を解消して押しやすいゆったりとした幅に改善。
- **2026-09-05**: スタンプの「よく使う（履歴）」への追加タイミングをスタンプ選択時ではなく、予定の「保存」時（予定作成・編集モーダル保存時、およびTodayBarクイック追加保存時）に変更。
- **2026-09-05**: スタンプ選択モーダルの「よく使う」タブデザイン改善（文字を廃止して時計アイコンのみの省スペース化、右側に縦のグレーボーダー仕切り線を追加）。
- **2026-09-05**: スタンプ選択の「よく使う」タブの動作改善（初期状態は空、履歴が0件のときは1つ右の「シフト・仕事」がデフォルトで開き、1つでもスタンプを使用すると自動的に「よく使う」がデフォルトで開く仕様へ変更）。
- **2026-09-05**: 予定スタンプカタログの拡充（各カテゴリ16種類、合計80種類の絵文字スタンプ）および「重要・その他」へのドクロマーク（💀）追加。
- **2026-09-05**: 予定アイコン・スタンプのカレンダー表示機能（DB v7 マイグレーション、EventStampカタログ、StampPickerSheet、CustomMonthViewでのバー内＆日付横スタンプバッジ描画、TodayBarからのクイックスタンプ追加）を実装。
- **2026-08-29**: AGENTS.md および PROGRESS.md の全ファイル構成・機能同期更新。
- **2026-05-11**: ダークモード対応。端末設定・ライト・ダークの3モード切替と、きせかえ適用時のダークデザイン追加。
- **2026-05-11**: 誕生日詳細画面のケーキアイコンと当日のハイライト色を「誕生日の表示カラー」に連動。
- **2026-04-18**: 複数日にわたる予定の表示安定化（週単位のレーン固定ロジック）を実装。
- **2026-04-17**: 誕生日保存・表示時のエラー（Unexpected null value / box.dart）を修正。データマッピングの安全性向上。
- **2026-04-16**: 「今日」ボタン押下時にカレンダーが現在の月までスクロールしない不具合を修正。
- **2026-04-16**: Web版でのレイアウト崩れ（1/4縮小・左上寄り）の修正。MaterialApp.builder による安定化。
- **2026-04-15**: 通知設定ダイアログ内での排他制御ロジック（「なし」選択時の他項目解除など）を実装。

## 全体の進捗: ██████████ 100%

---

## Phase 1: 環境構築 ✅ 完了
- [x] Flutterプロジェクト初期化
- [x] pubspec.yaml に依存パッケージ追加（calendar_view, flutter_riverpod, intl, sqflite, path, holiday_jp, shared_preferences, flutter_local_notifications, timezone）
- [x] Android minSdkVersion 設定（21以上）
- [x] アセットディレクトリ作成（assets/images/themes/）
- [x] Feature-based ディレクトリ構成の作成

## Phase 2: データモデル & Repository ✅ 完了
- [x] 共通Enum定義
  - [x] `EventColor`（12色） — `lib/shared/constants/event_color.dart`
  - [x] `RecurrenceType`（繰り返し: なし/毎日/毎週/毎月/毎年/平日/カスタム） — `lib/shared/constants/recurrence_type.dart`
  - [x] `NotificationType`（通知） — `lib/shared/constants/notification_type.dart`
- [x] データモデル
  - [x] `EventModel`（toMap / fromMap / copyWith / icon） — `lib/features/calendar/models/event_model.dart`
  - [x] `EventStamp`（スタンプカタログ・プリセット定義） — `lib/features/calendar/models/event_stamp.dart`
  - [x] `CustomRecurrence` — `lib/features/calendar/models/custom_recurrence.dart`
  - [x] `EditScope` — `lib/features/calendar/models/edit_scope.dart`
  - [x] `BirthdayModel`（toMap / fromMap / copyWith / age） — `lib/features/birthday/models/birthday_model.dart`
  - [x] `TagModel` — `lib/features/birthday/models/tag_model.dart`
  - [x] `AppSettings` / `BirthdayDisplaySettings` — `lib/features/settings/models/`
- [x] DatabaseHelper — `lib/shared/db/database_helper.dart`
  - [x] シングルトンパターン（DBバージョン 7）
  - [x] events / birthdays / tags テーブル作成 & マイグレーション（v7: icon カラム追加）
  - [x] インデックス作成（日付カラム）
- [x] Repository インターフェース & sqflite実装
  - [x] `EventRepository` & `SqfliteEventRepository`
  - [x] `BirthdayRepository` & `SqfliteBirthdayRepository`
  - [x] `TagRepository` & `SqfliteTagRepository`
- [x] `flutter analyze` — エラーなし確認済み

## Phase 3: 状態管理（Riverpod Provider / Notifier） ✅ 完了
- [x] `ViewType` enum — `lib/shared/constants/view_type.dart`
- [x] Repository Provider — `lib/shared/providers/repository_providers.dart`
- [x] App State Provider（選択日付 / 表示月 / 表示モード） — `lib/shared/providers/app_state_providers.dart`
- [x] EventsByDateNotifier / EventsByMonthNotifier — `lib/features/calendar/providers/event_providers.dart`
- [x] BirthdayListNotifier + TagListNotifier + フィルタリング派生 — `lib/features/birthday/providers/birthday_providers.dart`
- [x] Settings Providers — `lib/features/settings/providers/settings_providers.dart`
- [x] 検索Provider（eventSearch / birthdaySearch）
- [x] main.dart を ProviderScope で wrap

## Phase 4: UI - 基盤レイアウト ✅ 完了
- [x] main.dart をRiverpod・intl対応に書き換え — `lib/main.dart`
- [x] AppShell（ヘッダー + メインビュー + フッター + FAB） — `lib/shared/widgets/app_shell.dart`
- [x] Header View（メニュー、タイトル、検索、今日ボタン） — `lib/shared/widgets/custom_header.dart`
- [x] Footer View（スケジュール / 誕生日 切り替え） — `lib/shared/widgets/custom_footer.dart`
- [x] FAB（表示モードに応じた追加モーダル起動） — `lib/shared/widgets/custom_fab.dart`
- [x] Drawer（設定メニュー・きせかえ・タグ管理・About） — `lib/shared/widgets/custom_drawer.dart`

## Phase 5: UI - Schedule View ✅ 完了
- [x] MonthView（自作 CustomMonthView に置き換え済） — `lib/features/calendar/views/schedule_view.dart`
- [x] 5週/6週可変高さ、横方向スワイプ対応
- [x] 土日・祝日の色分け対応（holiday_jp 使用）
- [x] 複数日イベントバーの連結表示・週跨ぎレーン固定
- [x] 誕生日予定のスケジュール連動表示
- [x] Today Bar（選択日付表示） — `lib/features/calendar/widgets/today_bar.dart`
- [x] Event List（選択日付のイベント表示） — `lib/features/calendar/widgets/event_list_view.dart`

## Phase 6: UI - Birthday View ✅ 完了
- [x] タグフィルター（すべて / カスタムタグ / 未設定） — `lib/features/birthday/widgets/tag_filter_bar.dart`
- [x] 誕生日リスト（名前 / 日付 / 満年齢 / ソート対応） — `lib/features/birthday/widgets/birthday_list_view.dart`
- [x] Birthday View統合 — `lib/features/birthday/views/birthday_view.dart`

## Phase 7: UI - Full Screen Modal ✅ 完了
- [x] 共通BaseModal（ヘッダー: 閉じる / 決定 / 削除 / 編集）
- [x] イベント追加/編集モーダル
  - [x] バリデーション / 12色選択 / 通知設定（複数選択） / コメント
- [x] 誕生日追加/編集モーダル（生まれ年不明 / タグ複数選択 / メモ）
- [x] FABおよび各リストからモーダルへのルーティング

## Phase 8: きせかえ機能 & ダークモード ✅ 完了
- [x] テーマデータ定義 — `lib/shared/theme/app_theme.dart`
- [x] テーマの状態管理 & SharedPreferences 永続化 — `lib/shared/providers/theme_provider.dart`
- [x] Header/Footer への画像適用 — `lib/shared/widgets/custom_header.dart`, `custom_footer.dart`
- [x] Main View 背景透過・適用 — `lib/shared/widgets/app_shell.dart`
- [x] テーマ選択モーダル（標準12色・桜・夜空） — `lib/shared/widgets/theme_selection_modal.dart`
- [x] ダークモード切り替えダイアログ — `lib/features/settings/widgets/theme_mode_dialog.dart`

## Phase 9: 仕上げ & 追加機能 ✅ 完了
- [x] 画面方向の縦固定 — `lib/main.dart`
- [x] 検索モーダル（リアルタイム横断検索） — `lib/shared/widgets/custom_search_delegate.dart`
- [x] アプリについて（About）ダイアログ — `lib/shared/widgets/custom_drawer.dart`
- [x] タグ管理画面（追加・削除・一覧） — `lib/features/birthday/views/tag_management_view.dart`
- [x] カスタム繰り返し設定モーダル — `lib/features/calendar/widgets/custom_recurrence_modal.dart`
- [x] 基本設定モーダル — `lib/features/settings/widgets/basic_settings_modal.dart`
- [x] 誕生日カレンダー表示設定モーダル — `lib/features/settings/widgets/birthday_display_settings_modal.dart`
- [x] ローカル通知スケジュール（NotificationService） — `lib/shared/services/notification_service.dart`

## Phase 13: 予定アイコン・スタンプ機能 ✅ 完了
- [x] DBスキーマ v7（`events.icon` カラム追加とマイグレーション）
- [x] スタンプカタログ & プリセット定義（`EventStamp`）
- [x] スタンプ選択モーダルシート（`StampPickerSheet`）
- [x] 予定作成・編集モーダルでのアイコン選択 ＆ タイトル自動補完
- [x] カレンダー（CustomMonthView）でのイベントバー内アイコン表示 ＆ 日付横スタンプバッジ表示
## Phase 14: データ保護（バックアップ・復元）＆ 連絡先誕生日インポート ✅ 完了
- [x] 依存パッケージ追加（path_provider, share_plus, file_picker, flutter_contacts）
- [x] AndroidManifest.xml（READ_CONTACTS）＆ Info.plist（NSContactsUsageDescription）権限追加
- [x] バックアップデータモデル（BackupData）＆ JSONシリアライズ/デシリアライズ
- [x] バックアップサービス（BackupService）
  - [x] DB全データ（events, birthdays, tags）のJSONエクスポート ＆ OS共有シート連携
  - [x] ファイルピッカーからのJSON読み込み・形式検証
  - [x] 上書き復元 / 追加復元（重複防止）のトランザクション処理
  - [x] 復元後の通知一括再スケジュール（NotificationService.rescheduleAll）
- [x] バックアップ＆復元UI画面（BackupRestoreModal）
- [x] 連絡先インポートサービス（ContactImportService）
  - [x] 端末連絡先の誕生日スキャン（EventLabel.birthday）
  - [x] 既存データとの重複判定（登録済みバッジ）
  - [x] 一括タグ付与 ＆ 一括インポート処理
- [x] 連絡先誕生日インポートUI画面（ContactImportModal）
  - [x] 検索バー、全選択/全解除、選択カウンター、付与タグ選択チップ
- [x] 導線統合（CustomDrawerへのメニュー追加、BirthdayListViewの0件時インポートボタン）

## Phase 15: 他カレンダーからの予定インポート ✅ 完了
- [x] パッケージ導入（device_calendar: ^4.3.3）
  - [x] AndroidManifest.xml に READ_CALENDAR / WRITE_CALENDAR パーミッション追加
  - [x] Info.plist に NSCalendarsUsageDescription / NSCalendarsFullAccessUsageDescription 追加
- [x] カレンダーインポートサービス（DeviceCalendarService）
  - [x] 端末内のカレンダー一覧（Googleアカウント/iCloud等）の取得
  - [x] 期間指定・カレンダー指定での予定取得（RetrieveEventsParams）
  - [x] 既存予定（eventsテーブル）との重複判定キー照合（タイトル・開始・終了）
  - [x] 選択予定の一括インポート処理（トランザクション）
- [x] iCalendarパース機能（ICalendarService.parseIcsToEntries）
  - [x] .ics形式ファイルのテキスト解析・重複判定・エントリ変換
- [x] カレンダーインポートUI画面（DeviceCalendarImportModal）
  - [x] カレンダー選択ドロップダウン（端末カレンダー + .icsファイル読み込み）
  - [x] 取得期間指定（前後/標準/広範囲/日付範囲カスタム指定）
  - [x] 検索バー、全選択/全解除、重複バッジ表示
  - [x] 取り込み予定の帯カラー選択（12色パレット）
  - [x] 一括取り込み実行 ＆ カレンダーProvider自動再読込
- [x] ドロワー導線統合（CustomDrawerの「データ連携・バックアップ」に追加）

## Phase 16: ホーム画面ウィジェット ✅ 完了
- [x] パッケージ導入（home_widget: ^0.7.0）
- [x] AndroidネイティブAppWidget基盤構築
  - [x] birthday_widget_info.xml（初期サイズ4x2、更新間隔30分、home_screen設定）
  - [x] widget_background.xml, widget_chip_primary.xml, widget_chip_secondary.xml
  - [x] widget_birthday.xml（ヘッダー、1人目ハイライト、2〜3人目リスト、空状態表示）
  - [x] BirthdayWidgetProvider.kt（RemoteViews生成、タップ起動PendingIntent、JSONパース・バインド）
  - [x] AndroidManifest.xml にレシーバー登録
- [x] Flutter側データモデル＆同期サービス
  - [x] WidgetBirthdayItem（直近日数判定、名前・年齢・日付ラベル、JSONシリアライズ）
  - [x] WidgetSyncService（DBから直近誕生日抽出、ソート、home_widget共有領域への保存、再描画トリガー）
- [x] アプリ内ライフサイクル・更新トリガー連動
  - [x] アプリ起動時の初期同期（main.dart）
  - [x] 誕生日の追加・更新・削除時の自動同期（BirthdayListNotifier）
  - [x] バックアップ復元完了時の自動同期（BackupService）
  - [x] 連絡先インポート完了時の自動同期（ContactImportService）
- [x] 設定メニュー導線
  - [x] 基本設定画面（BasicSettingsModal）に「手動更新ボタン」およびホーム画面配置手順の案内カードを追加

---

## ディレクトリ構成（現在の状態）
```
lib/
├── main.dart                                    # アプリエントリポイント
├── features/
│   ├── calendar/
│   │   ├── models/ (event_model.dart, event_stamp.dart, custom_recurrence.dart, edit_scope.dart, device_calendar_entry.dart)
│   │   ├── repositories/ (event_repository.dart, sqflite_event_repository.dart)
│   │   ├── providers/ (event_providers.dart)
│   │   ├── services/ (device_calendar_service.dart)
│   │   ├── views/ (schedule_view.dart)
│   │   └── widgets/ (custom_month_view.dart, custom_recurrence_modal.dart, device_calendar_import_modal.dart, event_detail_modal.dart, event_list_view.dart, event_modal.dart, month_picker_sheet.dart, stamp_picker_sheet.dart, today_bar.dart)
│   ├── birthday/
│   │   ├── models/ (birthday_model.dart, tag_model.dart, contact_birthday_entry.dart)
│   │   ├── repositories/ (birthday_repository.dart, sqflite_birthday_repository.dart, tag_repository.dart, sqflite_tag_repository.dart)
│   │   ├── providers/ (birthday_providers.dart)
│   │   ├── services/ (contact_import_service.dart)
│   │   ├── views/ (birthday_view.dart, tag_management_view.dart)
│   │   └── widgets/ (birthday_detail_modal.dart, birthday_list_view.dart, birthday_modal.dart, contact_import_modal.dart, tag_filter_bar.dart)
│   ├── widget/
│   │   ├── models/ (widget_birthday_item.dart)
│   │   └── services/ (widget_sync_service.dart)
│   ├── backup/
│   │   ├── models/ (backup_data.dart)
│   │   ├── services/ (backup_service.dart, icalendar_service.dart)
│   │   └── views/ (backup_restore_modal.dart)
│   └── settings/
│       ├── models/ (app_settings.dart, birthday_display_settings.dart)
│       ├── providers/ (settings_providers.dart)
│       └── widgets/ (basic_settings_modal.dart, calendar_settings_modal.dart, birthday_display_settings_modal.dart, theme_mode_dialog.dart)
└── shared/
    ├── constants/ (event_color.dart, japanese_holiday.dart, notification_type.dart, recurrence_type.dart, view_type.dart)
    ├── db/ (database_helper.dart)
    ├── providers/ (app_state_providers.dart, repository_providers.dart, theme_provider.dart)
    ├── services/ (notification_service.dart)
    ├── theme/ (app_theme.dart)
    └── widgets/ (app_shell.dart, base_modal.dart, custom_drawer.dart, custom_fab.dart, custom_footer.dart, custom_header.dart, custom_search_delegate.dart, multi_select_dialog.dart, theme_selection_modal.dart)
```

