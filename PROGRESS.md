# BirthDayCalendar 実装進捗

> このファイルはプロジェクトの実装進捗を管理するものです。
> セッションを跨いでも現在の状態を把握できるようにしています。
> 最終更新: 2026-04-18

- **2026-04-18**: 複数日にわたる予定の表示安定化（週単位のレーン固定ロジック）を実装。
- **2026-04-17**: 誕生日保存・表示時のエラー（Unexpected null value / box.dart）を修正。データマッピングの安全性向上。
- **2026-04-16**: 「今日」ボタン押下時にカレンダーが現在の月までスクロールしない不具合を修正。
- **2026-04-16**: Web版でのレイアウト崩れ（1/4縮小・左上寄り）の修正。MaterialApp.builder による安定化。
- **2026-04-15**: 通知設定ダイアログ内での排他制御ロジック（「なし」選択時の他項目解除など）を実装。

## 全体の進捗: ██████████ 100%

---

## Phase 1: 環境構築 ✅ 完了
- [x] Flutterプロジェクト初期化
- [x] pubspec.yaml に依存パッケージ追加（calendar_view, flutter_riverpod, intl, sqflite, path, holiday_jp）
- [x] Android minSdkVersion 設定（21以上）
- [x] アセットディレクトリ作成（assets/images/themes/）
- [x] Feature-based ディレクトリ構成の作成

## Phase 2: データモデル & Repository ✅ 完了
- [x] 共通Enum定義
  - [x] `EventColor`（12色） — `lib/shared/constants/event_color.dart`
  - [x] `RecurrenceType`（繰り返し: なし/毎日/毎週/毎月/毎年/平日） — `lib/shared/constants/recurrence_type.dart`
  - [x] `NotificationType`（通知） — `lib/shared/constants/notification_type.dart`
- [x] データモデル
  - [x] `EventModel`（toMap / fromMap / copyWith） — `lib/features/calendar/models/event_model.dart`
  - [x] `BirthdayModel`（toMap / fromMap / copyWith / age） — `lib/features/birthday/models/birthday_model.dart`
- [x] DatabaseHelper — `lib/shared/db/database_helper.dart`
  - [x] シングルトンパターン
  - [x] events テーブル作成
  - [x] birthdays テーブル作成
  - [x] インデックス作成（日付カラム）
- [x] Repository インターフェース & sqflite実装
  - [x] `EventRepository`（抽象クラス） — `lib/features/calendar/repositories/event_repository.dart`
  - [x] `SqfliteEventRepository` — `lib/features/calendar/repositories/sqflite_event_repository.dart`
  - [x] `BirthdayRepository`（抽象クラス） — `lib/features/birthday/repositories/birthday_repository.dart`
  - [x] `SqfliteBirthdayRepository` — `lib/features/birthday/repositories/sqflite_birthday_repository.dart`
- [x] `flutter analyze` — エラーなし確認済み

## Phase 3: 状態管理（Riverpod Provider / Notifier） ✅ 完了
- [x] `ViewType` enum — `lib/shared/constants/view_type.dart`
- [x] Repository Provider — `lib/shared/providers/repository_providers.dart`
- [x] App State Provider（選択日付 / 表示月 / 表示モード） — `lib/shared/providers/app_state_providers.dart`
- [x] EventsByDateNotifier / EventsByMonthNotifier — `lib/features/calendar/providers/event_providers.dart`
- [x] BirthdayListNotifier + フィルタリング派生 — `lib/features/birthday/providers/birthday_providers.dart`
- [x] 検索Provider（eventSearch / birthdaySearch）
- [x] main.dart を ProviderScope で wrap
- [x] `flutter analyze` — エラーなし確認済み

## Phase 4: UI - 基盤レイアウト ✅ 完了
- [x] main.dart をRiverpod・intl対応に書き換え — `lib/main.dart`
- [x] AppShell（ヘッダー + メインビュー + フッター + FAB） — `lib/shared/widgets/app_shell.dart`
- [x] Header View（メニュー、タイトル、検索、今日ボタン） — `lib/shared/widgets/custom_header.dart`
- [x] Footer View（スケジュール / 誕生日 切り替え） — `lib/shared/widgets/custom_footer.dart`
- [x] FAB（表示モードに応じたアラート表示） — `lib/shared/widgets/custom_fab.dart`
- [x] Drawer（設定メニューのプレースホルダ） — `lib/shared/widgets/custom_drawer.dart`
- [x] ScheduleView / BirthdayView のプレースホルダ作成

## Phase 5: UI - Schedule View ✅ 完了
- [x] MonthView（自作 CustomMonthView に置き換え済） — `lib/features/calendar/views/schedule_view.dart`
- [x] 5週/6週可変高さ、横方向スワイプ対応
- [x] 土日・祝日の色分け対応（holiday_jp 使用）
- [x] 複数日イベントバーの連結表示
- [x] Today Bar（選択日付表示） — `lib/features/calendar/widgets/today_bar.dart`
- [x] Event List（選択日付のイベント表示） — `lib/features/calendar/widgets/event_list_view.dart`

## Phase 6: UI - Birthday View ✅ 完了
- [x] タグフィルター（すべて / カスタム / 未設定） — `lib/features/birthday/widgets/tag_filter_bar.dart`
- [x] 誕生日リスト（名前 / 日付 / 満年齢 / ソート対応） — `lib/features/birthday/widgets/birthday_list_view.dart`
- [x] Birthday View統合 — `lib/features/birthday/views/birthday_view.dart`

## Phase 7: UI - Full Screen Modal ✅ 完了
- [x] 共通BaseModal（ヘッダー: 閉じる / 決定 / 削除 / 編集）
- [x] イベント追加/編集モーダル
  - [x] バリデーション / 12色選択 / 通知設定
  - [x] **UI/UX 改善（タップ領域拡大、背景色付与、メモ欄の強調表示、半角括弧統一）**
  - [x] **日本語化対応（日付/時刻ピッカー、セレクトボックスの表示ラベル）**
  - [x] **通知の複数選択対応**
- [x] 誕生日追加/編集モーダル（生まれ年不明 / タグ選択）
- [x] FABおよび各リストからモーダルへのルーティング
- [x] 検索モーダル（リアルタイム検索） -> Phase 9へ整理
- [x] 設定モーダル -> Phase 9へ整理

## Phase 8: きせかえ機能 ✅ 完了
- [x] テーマデータ定義 — `lib/shared/theme/app_theme.dart`
- [x] テーマの状態管理 — `lib/shared/providers/theme_provider.dart`
- [x] Header/Footer への画像適用 — `lib/shared/widgets/custom_header.dart`, `custom_footer.dart`
- [x] Main View 背景透過・適用 — `lib/shared/widgets/app_shell.dart`
- [x] 3種類のテーマ画像準備とテーマ切り替えUI（Drawer） — `lib/shared/widgets/custom_drawer.dart`

## Phase 9: 仕上げ ✅ 完了
- [x] 画面方向の縦固定 — `lib/main.dart`
- [x] 検索モーダル（リアルタイム検索） — `lib/shared/widgets/custom_search_delegate.dart`
- [x] アプリについて（About）ダイアログ — `lib/shared/widgets/custom_drawer.dart`
- [x] パフォーマンス、エラーハンドリング、静的解析の最終確認（エラー・警告ゼロ）

---

## ディレクトリ構成（現在の状態）
```
lib/
├── main.dart                          ✅ ProviderScope + MaterialApp
├── features/
│   ├── calendar/
│   │   ├── models/
│   │   │   └── event_model.dart       ✅
│   │   ├── repositories/
│   │   │   ├── event_repository.dart   ✅
│   │   │   └── sqflite_event_repository.dart ✅
│   │   ├── providers/
│   │   │   └── event_providers.dart    ✅
│   │   ├── views/
│   │   │   └── schedule_view.dart      ✅
│   │   ├── widgets/
│   │   │   ├── custom_month_view.dart  ✅
│   │   │   ├── event_list_view.dart    ✅
│   │   │   ├── event_modal.dart        ✅
│   │   │   └── today_bar.dart          ✅
│   ├── birthday/
│   │   ├── models/
│   │   │   └── birthday_model.dart    ✅
│   │   ├── repositories/
│   │   │   ├── birthday_repository.dart ✅
│   │   │   └── sqflite_birthday_repository.dart ✅
│   │   ├── providers/
│   │   │   └── birthday_providers.dart ✅
│   │   ├── views/
│   │   │   └── birthday_view.dart      ✅
│   │   └── widgets/
│   │       ├── birthday_list_view.dart ✅
│   │       ├── birthday_modal.dart     ✅
│   │       └── tag_filter_bar.dart     ✅
│   └── settings/                      （空）
└── shared/
    ├── constants/
    │   ├── event_color.dart           ✅
    │   ├── japanese_holiday.dart      ✅
    │   ├── recurrence_type.dart       ✅
    │   ├── notification_type.dart     ✅
    │   └── view_type.dart             ✅
    ├── providers/
    │   ├── repository_providers.dart   ✅
    │   └── app_state_providers.dart    ✅
    ├── db/
    │   └── database_helper.dart       ✅
    ├── theme/
    │   └── app_theme.dart             ✅
    └── widgets/
        ├── app_shell.dart             ✅
        ├── base_modal.dart            ✅
        ├── custom_header.dart         ✅
        ├── custom_footer.dart         ✅
        ├── custom_fab.dart            ✅
        └── custom_drawer.dart         ✅
```
