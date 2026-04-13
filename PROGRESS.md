# BirthDayCalendar 実装進捗

> このファイルはプロジェクトの実装進捗を管理するものです。
> セッションを跨いでも現在の状態を把握できるようにしています。
> 最終更新: 2026-04-13

## 全体の進捗: ███░░░░░░░ 25%

---

## Phase 1: 環境構築 ✅ 完了
- [x] Flutterプロジェクト初期化
- [x] pubspec.yaml に依存パッケージ追加（calendar_view, flutter_riverpod, intl, sqflite, path）
- [x] Android minSdkVersion 設定（21以上）
- [x] アセットディレクトリ作成（assets/images/themes/）
- [x] Feature-based ディレクトリ構成の作成

## Phase 2: データモデル & Repository ✅ 完了
- [x] 共通Enum定義
  - [x] `EventColor`（12色） — `lib/shared/constants/event_color.dart`
  - [x] `RecurrenceType`（繰り返し） — `lib/shared/constants/recurrence_type.dart`
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

## Phase 4: UI - 基盤レイアウト 🔲 未着手
- [ ] main.dart をRiverpod/calendar_view対応に書き換え
- [ ] AppShell（ヘッダー + メインビュー + フッター + FAB）
- [ ] Header View（メニュー、タイトル、検索、今日ボタン）
- [ ] Footer View（スケジュール / 誕生日 切り替え）
- [ ] FAB（表示モードに応じたモーダル表示）

## Phase 5: UI - Schedule View 🔲 未着手
- [ ] MonthView（calendar_view 使用）
- [ ] 日本語対応（locale: ja_JP）
- [ ] 5週/6週 高さ調整
- [ ] イベントバー表示（日付跨ぎ対応）
- [ ] Today Bar（選択日付表示）
- [ ] Event List（選択日付のイベントリスト）

## Phase 6: UI - Birthday View 🔲 未着手
- [ ] タグフィルター（すべて / 家族 / 友達 / カスタム / 未設定）
- [ ] 誕生日リスト（名前 / 日付 / 満年齢）

## Phase 7: UI - Full Screen Modal 🔲 未着手
- [ ] 共通BaseModal（ヘッダー: 閉じる / 決定 / 削除 / 編集）
- [ ] 検索モーダル（リアルタイム検索）
- [ ] イベント表示モーダル
- [ ] イベント追加/編集モーダル（バリデーション / 12色選択 / 通知設定）
- [ ] 誕生日追加/編集モーダル（生まれ年不明 / タグ選択）
- [ ] 設定モーダル

## Phase 8: きせかえ機能 🔲 未着手
- [ ] テーマデータ定義
- [ ] Header/Footer への画像適用
- [ ] Main View 背景ホワイトアウト
- [ ] 3種類のテーマ画像準備

## Phase 9: 仕上げ 🔲 未着手
- [ ] 画面方向の縦固定
- [ ] エラーハンドリング
- [ ] パフォーマンス最適化
- [ ] 最終テスト

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
│   │   └── views/                     （空）
│   ├── birthday/
│   │   ├── models/
│   │   │   └── birthday_model.dart    ✅
│   │   ├── repositories/
│   │   │   ├── birthday_repository.dart ✅
│   │   │   └── sqflite_birthday_repository.dart ✅
│   │   ├── providers/
│   │   │   └── birthday_providers.dart ✅
│   │   └── views/                     （空）
│   └── settings/                      （空）
└── shared/
    ├── constants/
    │   ├── event_color.dart           ✅
    │   ├── recurrence_type.dart       ✅
    │   ├── notification_type.dart     ✅
    │   └── view_type.dart             ✅
    ├── providers/
    │   ├── repository_providers.dart   ✅
    │   └── app_state_providers.dart    ✅
    ├── db/
    │   └── database_helper.dart       ✅
    ├── theme/                         （空）
    └── widgets/                       （空）
```
