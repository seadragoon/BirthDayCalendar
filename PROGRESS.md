# 実装進捗記録 (PROGRESS.md)

> 最終更新: 2026-09-06

---

## 📊 全体進捗概要

- **基本・コア機能実装:** 100% 完了
- **主要拡張機能（フェーズ 10〜21）:** 100% 完了
- **ストア公開要件（法務・サポート・メーラー導線）:** 100% 完了
- **静的解析 (`flutter analyze`):** エラー・警告 0 件
- **単体・Widgetテスト (`flutter test`):** 全 44 件通過

---

## 🚀 フェーズ別実装履歴

| Phase | 内容 | 実装ファイル・主な対応 | 状態 |
|:---:|:---|:---|:---:|
| **1** | 環境構築 & パッケージ設定 | `pubspec.yaml`, `AndroidManifest.xml` (minSdk 21) | ✅ 完了 |
| **2** | データモデル & Repository | `EventModel`, `BirthdayModel`, `sqflite` CRUD基盤 | ✅ 完了 |
| **3** | 状態管理（Riverpod） | `event_providers.dart`, `birthday_providers.dart`, DI設計 | ✅ 完了 |
| **4** | UI基盤レイアウト | `AppShell`, `CustomHeader`, `CustomFooter`, `CustomFAB` | ✅ 完了 |
| **5** | Schedule View | `CustomMonthView`, `TodayBar`, `EventListView` | ✅ 完了 |
| **6** | Birthday View | `BirthdayView`, `TagFilterBar`, `BirthdayListView` | ✅ 完了 |
| **7** | Full Screen Modal | `BaseModal`, `EventModal`, `BirthdayModal` | ✅ 完了 |
| **8** | きせかえ機能 | `ThemeNotifier`, `ThemeSelectionModal`, 桜・夜空テーマ | ✅ 完了 |
| **9** | 仕上げ & 検索機能 | `CustomSearchDelegate` (リアルタイム横断検索) | ✅ 完了 |
| **10** | 高度な繰り返し機能 | `CustomRecurrenceModal`, 範囲選択編集/削除, 祝日考慮 | ✅ 完了 |
| **11** | ダークモード対応 | `ThemeModeDialog`, `AppSettings` 連携, テーマ色調整 | ✅ 完了 |
| **12** | タグ管理 & 通知スケジュール | `TagManagementView`, `NotificationService`, 予定連動 | ✅ 完了 |
| **13** | アイコン・スタンプ機能 | `EventStamp`, `StampPickerSheet`, カレンダー上アイコン描画 | ✅ 完了 |
| **14** | データ保護 & 連絡先インポート | `BackupService` (JSON), `ContactImportService` | ✅ 完了 |
| **15** | 外部カレンダー連携 | `DeviceCalendarService`, Google/iCloud/.ics インポート | ✅ 完了 |
| **16** | ホーム画面ウィジェット | `home_widget`, 4×2, 2×2, 2×3 (全6種マルチサイズウィジェット) | ✅ 完了 |
| **17** | ストア公開・法務要件 | プライバシーポリシー, 利用規約, お問い合わせ窓口 (mailto:) | ✅ 完了 |
| **18** | セキュリティ・生体認証 | 4桁PIN, SHA-256暗号化, 指紋/顔認証, 目隠しシールド | ✅ 完了 |
| **19** | 日本の六曜・旧暦表示 | `qreki_dart`, `RokuyoUtil`, カレンダーセル＆選択日バー表示 | ✅ 完了 |
| **20** | プレゼント・お祝い履歴メモ | DB v8, `GiftModel`, `GiftEditModal`, ギフト記録＆バックアップ | ✅ 完了 |
| **21** | 操作性向上・複製・設定 | 予定の複製作成, `MonthPickerSheet` (年月移動), 予定初期値設定 | ✅ 完了 |

---

## 🎯 アイデア出し・今後の拡張候補の進捗状況

> 詳細は [FEATURE_IDEAS.md](file:///d:/FlutterProject/BirthDayCalendar/FEATURE_IDEAS.md) を参照。

### ✅ 実装済みの重要機能
1. **データバックアップ＆復元（JSON / .ics）**
2. **端末連絡先からの誕生日一括取り込み**
3. **パスコードロック＆生体認証（指紋・顔認証）**
4. **ホーム画面ウィジェット（6種類マルチサイズ）**
5. **外部カレンダー（Google/iCloud/.ics）取り込み**
6. **六曜（大安・友引・仏滅等）表示**
7. **プレゼント・お祝い履歴メモ（あげた/もらった/候補）**
8. **既存予定の複製（コピーして作成）機能**
9. **カレンダー年月ジャンプ（月選択シート）**
10. **カレンダー新規登録時の初期値設定（終日/カラー/通知）**

---

## 💎 プレミアム・マネタイズ機能（フェーズ 22 実装予定）

全部入りの「プレミアムプラン（Pro）」によるハイブリッド型（月額 / 年額 / 買い切りLifetime）マネタイズのロードマップ：

| ステップ | 内容 | 状態 |
|:---:|:---|:---:|
| **ステップ 1** | **キラー機能の実装**<br>・自分の写真でカレンダー背景きせかえ（`image_picker`）<br>・写真付きカウントダウン・透過など拡張ウィジェット<br>・プレミアム限定テーマパック | 📋 計画中 |
| **ステップ 2** | **プレミアム状態管理基盤**<br>・`isPremiumProvider`（Riverpod）の作成<br>・デバッグ用「無料 ⇄ プレミアム」即時切り替えスイッチの用意 | 📋 計画中 |
| **ステップ 3** | **Paywall / 料金案内モーダル**<br>・王冠アイコン 👑 / Proアップグレード案内UI<br>・プラン選択カード（月額 / 年額 / 買い切りLifetime）<br>・購入・復元（Restore）導線モック | 📋 計画中 |
| **ステップ 4** | **課金パッケージ連携 & 広告枠**<br>・`purchases_flutter` (RevenueCat) によるストア決済接続<br>・`google_mobile_ads` 導入（無料時のみ表示・プレミアム時完全非表示） | 📋 計画中 |

---

### 💡 その他の機能候補（未実装）
1. **記念日（結婚記念日・命日・ペットなど）への拡張**:
   - 誕生日以外の定期イベントや記念日の汎用カウントダウン管理
2. **予定の定型テンプレート / 履歴入力**:
   - シフト（早番・遅番・夜勤）や通院など、定型予定のワンタップ入力
3. **お祝い連絡ショートカット**:
   - 誕生日詳細画面からのLINE・電話・SMS直接起動導線
4. **干支・星座・長寿祝い・厄年自動表示**:
   - 生年月日から干支や還暦等の長寿祝い・厄年を自動算出
5. **クラウド自動バックアップ**:
   - Google Drive / iCloud との自動同期
