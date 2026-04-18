# AGENTS.md — AI向けプロジェクトリファレンス

> **このファイルはAIアシスタントがセッション開始時に最初に読むべきドキュメントです。**
> 最終更新: 2026-04-18

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

---

## 1. プロジェクト概要

| 項目 | 内容 |
|------|------|
| **アプリ名** | BirthDay Calendar |
| **目的** | Yahoo!カレンダー（Y!カレンダー）のUI/UXをベースとした、シンプルかつ拡張性の高いカレンダーアプリ |
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
| カレンダーUI | `calendar_view` | ^1.2.0 | MonthView、日付跨ぎバー表示 |
| 日付処理 | `intl` | ^0.19.0 | 日本語(ja_JP)フォーマット |
| ローカルDB | `sqflite` | ^2.4.1 | CRUD操作 |
| DB (デスクトップ) | `sqflite_common_ffi` | ^2.4.0+2 | Windows/Linux対応 |
| DB (Web) | `sqflite_common_ffi_web` | ^1.1.1 | Web対応 |
| パス操作 | `path` | ^1.9.1 | DBファイルパス構築 |
| 祝日判定 | `holiday_jp` | ^0.0.8 | 日本の祝日データと判定論理 |

---

## 3. アーキテクチャ

### 3.1 設計方針
- **Feature-based ディレクトリ構成**: 機能ごとにディレクトリを分離
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
lib/
├── main.dart                                    # アプリエントリポイント（ProviderScope + MaterialApp）
│
├── features/
│   ├── calendar/                                # ── スケジュール機能 ──
│   │   ├── models/
│   │   │   └── event_model.dart                 # EventModel（toMap/fromMap/copyWith）
│   │   ├── repositories/
│   │   │   ├── event_repository.dart            # EventRepository 抽象クラス
│   │   │   └── sqflite_event_repository.dart    # sqflite実装
│   │   ├── providers/
│   │   │   └── event_providers.dart             # EventsByDate/Month Notifier, 検索Provider
│   │   ├── views/
│   │   │   └── schedule_view.dart               # Schedule画面（MonthView + EventList統合）
│   │   └── widgets/
│   │       ├── custom_month_view.dart           # 横スワイプ可能・可変高さのカスタムカレンダー
│   │       ├── event_list_view.dart             # 選択日付のイベントリスト
│   │       ├── event_modal.dart                 # イベント追加/編集/表示モーダル
│   │       └── today_bar.dart                   # 選択日付表示バー
│   │
│   ├── birthday/                                # ── 誕生日機能 ──
│   │   ├── models/
│   │   │   └── birthday_model.dart              # BirthdayModel（age計算, daysUntil）
│   │   ├── repositories/
│   │   │   ├── birthday_repository.dart         # BirthdayRepository 抽象クラス
│   │   │   └── sqflite_birthday_repository.dart # sqflite実装
│   │   ├── providers/
│   │   │   └── birthday_providers.dart          # BirthdayList Notifier, タグフィルタ, 検索
│   │   ├── views/
│   │   │   └── birthday_view.dart               # Birthday画面（タグフィルタ + リスト統合）
│   │   └── widgets/
│   │       ├── birthday_list_view.dart          # 誕生日リスト表示
│   │       ├── birthday_modal.dart              # 誕生日追加/編集モーダル
│   │       └── tag_filter_bar.dart              # タグフィルターバー
│   │
│   └── settings/                                # ── 設定機能 ──（現在空）
│
└── shared/                                      # ── 共通部品 ──
    ├── constants/
    │   ├── event_color.dart                     # EventColor enum（12色）
    │   ├── japanese_holiday.dart                # 日本の祝日判定ユーティリティ
    │   ├── recurrence_type.dart                 # RecurrenceType enum（none/daily/weekly/monthly/yearly/weekday）
    │   ├── notification_type.dart               # NotificationType enum（none〜1週間前）
    │   └── view_type.dart                       # ViewType enum（schedule/birthday）
    ├── db/
    │   └── database_helper.dart                 # DatabaseHelper シングルトン（テーブル定義）
    ├── providers/
    │   ├── repository_providers.dart            # EventRepository / BirthdayRepository Provider
    │   ├── app_state_providers.dart             # selectedDate / currentMonth / viewType
    │   └── theme_provider.dart                  # ThemeNotifier（きせかえ状態管理）
    ├── theme/
    │   └── app_theme.dart                       # AppThemeData / AppThemeType enum（standard/sakura/night）
    └── widgets/
        ├── app_shell.dart                       # Scaffold統合（Header + Main + Footer + FAB）
        ├── base_modal.dart                      # 共通Full Screen Modalヘッダー
        ├── custom_header.dart                   # ヘッダー（タイトル/メニュー/検索/今日ボタン）
        ├── custom_footer.dart                   # フッター（スケジュール/誕生日 切り替え）
        ├── custom_fab.dart                      # FAB（ViewType連動、モーダル起動）
        ├── custom_drawer.dart                   # ドロワー（テーマ切り替え/About）
        ├── custom_search_delegate.dart          # 検索モーダル（リアルタイム検索）
        └── multi_select_dialog.dart             # 汎用複数選択ダイアログ
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
| colorIndex | `EventColor` | peacock | color_index | 12色enum |
| recurrence | `RecurrenceType` | none | recurrence | 繰り返し（なし/毎日/毎週/毎月/毎年/平日） |
| notifications | `List<NotificationType>` | [none] | notification | 通知設定（JSON形式） |
| comment | `String` | '' | comment | コメント |
| isBirthday | `bool` | false | is_birthday | 誕生日紐づきフラグ |
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
| createdAt | `DateTime` | date | created_at | 作成日時 |
| updatedAt | `DateTime` | date | updated_at | 更新日時 |

**計算プロパティ:**
- `int? age` — 満年齢（isYearUnknown時はnull）
- `int daysUntilNextBirthday` — 次の誕生日までの日数

---

## 6. Provider / 状態管理マップ

### 6.1 グローバル状態 (`shared/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `selectedDateProvider` | `StateProvider<DateTime>` | カレンダーで選択中の日付 |
| `currentMonthProvider` | `StateProvider<DateTime>` | 表示中の月 |
| `viewTypeProvider` | `StateProvider<ViewType>` | 表示モード（schedule/birthday） |
| `eventRepositoryProvider` | `Provider<EventRepository>` | EventRepositoryインスタンス |
| `birthdayRepositoryProvider` | `Provider<BirthdayRepository>` | BirthdayRepositoryインスタンス |
| `themeProvider` | `NotifierProvider<ThemeNotifier, AppThemeData>` | きせかえテーマ |

### 6.2 イベント関連 (`features/calendar/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `eventsByDateProvider` | `AsyncNotifierProvider<..., List<EventModel>>` | 選択日付のイベント一覧 |
| `eventsByMonthProvider` | `AsyncNotifierProvider<..., List<EventModel>>` | 表示月のイベント一覧（カレンダーバー表示用） |
| `eventSearchProvider` | `FutureProvider.family<..., String>` | イベント検索結果 |

### 6.3 誕生日関連 (`features/birthday/providers/`)

| Provider名 | 型 | 役割 |
|------------|-----|------|
| `birthdayListProvider` | `AsyncNotifierProvider<..., List<BirthdayModel>>` | 全誕生日リスト |
| `selectedTagProvider` | `StateProvider<String?>` | 選択中のタグフィルタ（null=すべて, ''=未設定） |
| `filteredBirthdaysProvider` | `Provider<AsyncValue<List<BirthdayModel>>>` | フィルタ済み誕生日リスト |
| `allTagsProvider` | `Provider<AsyncValue<List<String>>>` | 登録済みユニークタグ一覧 |
| `birthdaySearchProvider` | `FutureProvider.family<..., String>` | 誕生日検索結果 |

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
  color_index INTEGER NOT NULL DEFAULT 6,  -- EventColor.peacock
  recurrence INTEGER NOT NULL DEFAULT 0,
  notification TEXT NOT NULL DEFAULT '[0]', -- 通知タイミング（JSON配列）
  comment TEXT DEFAULT '',
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

- **DBバージョン:** 3
- **DBファイル名:** `birthday_calendar.db`
- **マイグレーション:** notification の JSON化 (v2) および tags テーブル追加 + デフォルトデータ投入 (v3)

---

## 8. きせかえテーマ

| テーマ名 | `AppThemeType` | primaryColor | 背景画像 |
|---------|---------------|-------------|---------|
| 標準（シンプルホワイト） | `standard` | Blue 400 (`#42A5F5`) | なし |
| 桜（サクラ） | `sakura` | Pink 400 (`#EC407A`) | `assets/images/themes/sakura.png` |
| 夜空（ナイト） | `night` | Indigo 600 (`#3949AB`) | `assets/images/themes/night.png` |

- テーマ状態はオンメモリ管理（SharedPreferencesでの永続化は未実装）
- Header/Footerに背景画像を適用、Main Viewは`surfaceColor`による透過

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

### Full Screen Modal 一覧
| モーダル | ファイル | 操作 |
|---------|--------|------|
| イベント追加/編集/表示 | `event_modal.dart` | CRUD + 12色選択 + バリデーション |
| 誕生日追加/編集 | `birthday_modal.dart` | CRUD + タグ選択グリッド + 生まれ年不明 |
| タグ管理 | `tag_management_view.dart` | タグの一覧表示・追加・削除（フルスクリーン） |
| 検索 | `custom_search_delegate.dart` | リアルタイム横断検索 |
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
| 9 | 仕上げ（検索/About/静的解析） | ✅ 完了 |

**全体進捗: 100%** — 全フェーズ実装完了済み

---

## 11. 既知の制限・今後の拡張候補

| 項目 | 現状 | 改善候補 |
|------|------|---------|
| テーマ永続化 | オンメモリのみ | SharedPreferencesで永続化 |
| 通知機能 | UI設定のみ（実際の通知は未実装） | `flutter_local_notifications` 統合 |
| settings機能 | `features/settings/` ディレクトリは空 | 設定画面の実装 |
| テスト | `test/` ディレクトリは空 | Unit/Widget テスト追加 |
| プッシュ通知 | 未実装 | Firebase Cloud Messaging |
| データバックアップ | 未実装 | Google Drive / iCloud 連携 |
| 繰り返しイベント | DB保存のみ（実際の繰り返し展開は未実装） | 繰り返しイベント（平日を含む）の日付展開ロジック |

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
| `PLANNING.md` | 機能要件・UI仕様の詳細定義 |
| `PROGRESS.md` | 実装進捗の記録 |
| `pubspec.yaml` | 依存パッケージ管理 |
| `analysis_options.yaml` | 静的解析ルール |
| `sample-ui/yahoo.png` | デザイン参考画像 |
