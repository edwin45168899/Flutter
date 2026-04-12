# Supabase 整合說明

## 📋 完成項目

✅ 已將 Todo List 從本地 Hive 儲存遷移至 Supabase 雲端資料庫
✅ 建立設定對話框，可於 App 內輸入 Supabase URL 和 Anon Key
✅ 使用 SharedPreferences 儲存設定，重開 App 不需重新輸入
✅ 完整 CRUD 功能（新增/讀取/更新/刪除）
✅ 支援搜尋、篩選、排序
✅ 重新整理按鈕，手動同步雲端資料
✅ **多使用者隔離**：使用 `user_id` 欄位區分不同使用者的資料
✅ **RLS 政策保護**：資料庫層級確保使用者只能存取自己的待辦事項

---

## 🚀 快速開始

### 1. 首次執行 App

```bash
cd todo_list
flutter run
```

首次啟動會自動跳出設定對話框，要求輸入：
- **Supabase URL**：`https://your-project-id.supabase.co`
- **Supabase Anon Key**：從 Dashboard → Settings → API 取得
- **User ID**：自動生成 UUID（可在設定中查看/修改）

### 2. 修改設定

在 App 主畫面右上角點擊 **⚙️ 設定按鈕** 即可修改 Supabase 連線資訊與 User ID。

---

## 👥 多使用者架構

### 設計理念

本專案採用 **本地 User ID + 資料庫 RLS** 的雙層隔離機制：

1. **本地端**：每個裝置/使用者擁有獨立的 `user_id`（UUID）
2. **資料庫端**：Row Level Security (RLS) 政策確保查詢/寫入時自動過濾

### User ID 管理

| 項目 | 說明 |
|------|------|
| **生成方式** | 使用 `flutter_udid` 取得裝置唯一識別碼 |
| **重裝 App** | ✅ **ID 保持不變**（基於硬體/系統識別碼） |
| **儲存位置** | `SharedPreferences`（本地快取） |
| **查看路徑** | 設定對話框 → 點擊「User ID」展開 |
| **跨平台** | Android / iOS / Web（Web 使用 fallback） |

### 🔑 技術實作

```dart
// 使用 flutter_udid 取得裝置唯一 ID
import 'package:flutter_udid/flutter_udid.dart';

static Future<String> getDeviceUdid() async {
  try {
    final udid = await FlutterUdid.udid;
    return udid; // Android: Android ID, iOS: IDFV
  } catch (e) {
    return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

### ⚠️ 注意事項

- 目前採用 **本地 User ID**（非 Supabase Auth），適合測試/小型專案
- 若需正式多使用者登入，建議改用 **Supabase Auth**（Email/Google/GitHub）
- 更換 Anon Key 不會影響 User ID，但若清除設定會重新生成

---

## 🗄️ 資料庫結構

### 資料表名稱：`todos`

| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵（自動生成） |
| **user_id** | **UUID** | **使用者識別碼（多使用者隔離）** |
| title | TEXT | 事項標題（必填） |
| description | TEXT | 詳細描述 |
| is_completed | BOOLEAN | 是否已完成 |
| priority | INTEGER | 優先級（0:低, 1:中, 2:高） |
| due_date | TIMESTAMPTZ | 截止日期 |
| category | TEXT | 分類標籤 |
| created_at | TIMESTAMPTZ | 建立時間 |
| completed_at | TIMESTAMPTZ | 完成時間 |

### 📝 資料庫設定腳本說明

專案內的 `supabase_setup.sql` 檔案為 **Supabase 資料庫初始化腳本**，用於在 Supabase 雲端平台建立完整的資料庫結構。

#### 腳本功能清單：

1. **建立資料表** (`CREATE TABLE`)
   - 建立 `todos` 資料表，包含所有必要欄位
   - 使用 `gen_random_uuid()` 自動生成 UUID 主鍵
   - **新增 `user_id` 欄位**，預設使用 `auth.uid()` 取得當前使用者
   - 設定各欄位的預設值與約束條件

2. **建立索引** (`CREATE INDEX`)
   - `idx_todos_created_at`：加速依建立時間排序查詢
   - `idx_todos_is_completed`：加速依完成狀態篩選
   - `idx_todos_due_date`：加速依截止日期查詢
   - **`idx_todos_user_id`**：加速查詢特定使用者的待辦
   - **`idx_todos_user_created`**：複合索引（使用者 + 時間排序）
   - **`idx_todos_user_status`**：複合索引（使用者 + 完成狀態篩選）

3. **啟用安全性** (`ENABLE ROW LEVEL SECURITY`)
   - 啟用 Row Level Security (RLS) 保護資料存取
   - 防止未授權的資料讀取與修改

4. **建立存取政策** (`CREATE POLICY`)
   - 正式政策：`Users can only access their own todos`
   - 使用 `auth.uid() = user_id` 嚴格隔離
   - 提供測試用備案（已註解，需時手動啟用）

5. **欄位註解** (`COMMENT`)
   - 為資料表與每個欄位加入中文註解
   - 方便團隊成員理解資料結構用途

#### 🚀 使用方式：

1. 登入 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇你的專案
3. 點擊左側選單 **SQL Editor**
4. 點擊 **New Query**
5. 複製 `supabase_setup.sql` 的完整內容並貼上
6. 點擊 **Run** 執行腳本
7. 確認訊息顯示 `Success. No rows returned` 即完成建立

> ✅ 執行完成後，可在 **Table Editor** 中查看 `todos` 資料表是否建立成功

---

## 📁 專案結構

```
todo_list/lib/
├── main.dart                        # 應用程式入口（含 Supabase 初始化）
├── config/
│   └── supabase_config.dart         # 設定管理器（SharedPreferences）
├── services/
│   └── supabase_todo_service.dart   # Supabase CRUD 服務
├── providers/
│   └── todo_provider.dart           # Provider 狀態管理
├── models/
│   └── todo.dart                    # Todo 資料模型
├── pages/
│   └── todo_list_page.dart          # 主頁面（含設定按鈕）
└── widgets/
    ├── settings_dialog.dart         # Supabase 設定對話框
    ├── todo_tile.dart               # 列表項目元件
    ├── todo_form_dialog.dart        # 新增/編輯對話框
    └── empty_state.dart             # 空狀態元件
```

---

## 🔧 技術棧

| 類別 | 套件 | 版本 |
|------|------|------|
| 狀態管理 | provider | ^6.1.2 |
| 雲端資料庫 | supabase_flutter | ^2.12.2 |
| 設定儲存 | shared_preferences | ^2.5.5 |
| UUID 生成 | uuid | ^4.5.1 |

---

## ⚠️ 注意事項

1. **網路連線**：需要網路連線才能操作資料庫
2. **RLS 政策**：目前設定為允許所有操作（測試用），正式環境應加入認證機制
3. **錯誤處理**：所有 CRUD 操作均包含 try-catch 與日誌記錄

---

## 🐛 常見問題

### Q: 出現連線錯誤？
A: 檢查 Supabase URL 是否正確，確認專案存在且運作中

### Q: 資料無法寫入？
A: 確認 SQL 腳本已執行，`todos` 資料表已建立

### Q: 如何清除設定？
A: 在設定對話框中點擊「清除設定」按鈕

---

## 📝 更新日誌

### 2026-04-12
- ✅ 移除 Hive 本地儲存
- ✅ 整合 Supabase 雲端資料庫
- ✅ 新增設定對話框
- ✅ 完整 CRUD 功能
