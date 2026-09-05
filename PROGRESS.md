# BirthDayCalendar 実装進捗

> このファイルはプロジェクトの実装進捗を管理するものです。
> セッションを跨いでも現在の状態を把握できるようにしています。
> 最終更新: 2026-09-05

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
- [x] TodayBarからのワンタップクイックスタンプ追加
- [x] 一覧・詳細・検索画面へのアイコン表示連携

---

## ディレクトリ構成（現在の状態）
```
lib/
├── main.dart                                    # アプリエントリポイント
├── features/
│   ├── calendar/
│   │   ├── models/ (event_model.dart, event_stamp.dart, custom_recurrence.dart, edit_scope.dart)
│   │   ├── repositories/ (event_repository.dart, sqflite_event_repository.dart)
│   │   ├── providers/ (event_providers.dart)
│   │   ├── views/ (schedule_view.dart)
│   │   └── widgets/ (custom_month_view.dart, custom_recurrence_modal.dart, event_detail_modal.dart, event_list_view.dart, event_modal.dart, stamp_picker_sheet.dart, today_bar.dart)
│   ├── birthday/
│   │   ├── models/ (birthday_model.dart, tag_model.dart)
│   │   ├── repositories/ (birthday_repository.dart, sqflite_birthday_repository.dart, tag_repository.dart, sqflite_tag_repository.dart)
│   │   ├── providers/ (birthday_providers.dart)
│   │   ├── views/ (birthday_view.dart, tag_management_view.dart)
│   │   └── widgets/ (birthday_detail_modal.dart, birthday_list_view.dart, birthday_modal.dart, tag_filter_bar.dart)
│   └── settings/
│       ├── models/ (app_settings.dart, birthday_display_settings.dart)
│       ├── providers/ (settings_providers.dart)
│       └── widgets/ (basic_settings_modal.dart, birthday_display_settings_modal.dart, theme_mode_dialog.dart)
└── shared/
    ├── constants/ (event_color.dart, japanese_holiday.dart, notification_type.dart, recurrence_type.dart, view_type.dart)
    ├── db/ (database_helper.dart)
    ├── providers/ (app_state_providers.dart, repository_providers.dart, theme_provider.dart)
    ├── services/ (notification_service.dart)
    ├── theme/ (app_theme.dart)
    └── widgets/ (app_shell.dart, base_modal.dart, custom_drawer.dart, custom_fab.dart, custom_footer.dart, custom_header.dart, custom_search_delegate.dart, multi_select_dialog.dart, theme_selection_modal.dart)
```

