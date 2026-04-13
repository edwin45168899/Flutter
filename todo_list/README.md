# To Do List - Flutter 應用

一個功能完整的待辦事項管理應用程式，使用 Flutter 開發。

## ✨ 功能特色

### 基本功能
- ✅ 新增/編輯/刪除待辦事項
- ✅ 標記完成/未完成
- ✅ 滑動刪除（含確認對話框）
- ✅ 一鍵清除已完成
- ✅ 統計顯示（總數/進行中/已完成/已過期）

### 進階功能
- 🔔 **優先級設定** - 高/中/低優先級，顏色標示
- 📅 **截止日期** - 設定到期日，自動標示已過期/即將到期
- 🏷️ **分類標籤** - 為事項分類管理
- 📝 **詳細描述** - 為事項添加說明
- 🔍 **搜尋功能** - 快速找到待辦事項
- 🎯 **篩選功能** - 全部/進行中/已完成/已過期
- 🔄 **排序功能** - 依時間/優先級/標題排序
- ↩️ **撤銷刪除** - 刪除後可立即復原
- 🌙 **深色模式** - 跟隨系統主題自動切換
- 💾 **資料持久化** - 使用 Hive 本機儲存，關閉 App 不遺失

## 📁 專案結構

```
todo_list/
├── lib/
│   ├── main.dart                  # 應用程式入口
│   ├── i18n.dart                  # 國際化設定
│   ├── models/
│   │   └── todo.dart              # Todo 資料模型（含 Hive 註解）
│   ├── services/
│   │   └── todo_service.dart      # 資料持久化服務層
│   ├── providers/
│   │   └── todo_provider.dart     # Provider 狀態管理
│   ├── pages/
│   │   └── todo_list_page.dart    # 主頁面 UI
│   └── widgets/
│       ├── todo_tile.dart         # 列表項目元件
│       ├── todo_form_dialog.dart  # 新增/編輯對話框
│       └── empty_state.dart       # 空狀態元件
├── test/
│   ├── models/
│   │   └── todo_test.dart         # 模型單元測試
│   └── widgets/
│       └── empty_state_test.dart  # 元件測試
├── pubspec.yaml                   # 專案設定
└── ...
```

## 🚀 快速開始

### 安裝依賴
```bash
cd todo_list
flutter pub get

# 生成 Hive adapter（如需修改模型）
dart run build_runner build --delete-conflicting-outputs
```

### 執行應用
```bash
flutter run
```

### 編譯 APK
```bash
flutter build apk
```

### APK 檔案位置
```
build/app/outputs/flutter-apk/
├── app-debug.apk          # 開發測試用 (約 145 MB)
└── app-release.apk        # 發布用 (約 47 MB)
```

**完整路徑：**
```
D:\github\chiisen\Flutter\todo_list\build\app\outputs\flutter-apk\
```

### 安裝 APK
```bash
# 透過 ADB 安裝
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 📦 使用的套件

| 套件 | 用途 |
|------|------|
| `provider` | 狀態管理 |
| `hive` / `hive_flutter` | 本機資料持久化 |
| `path_provider` | 取得儲存路徑 |
| `uuid` | 生成唯一 ID |
| `intl` | 日期格式化 |
| `flutter_localizations` | 國際化支援 |

### 開發依賴
| 套件 | 用途 |
|------|------|
| `hive_generator` | 生成 Hive adapter |
| `build_runner` | 程式碼生成工具 |
| `flutter_launcher_icons` | 產生 App Icon |
| `flutter_test` | 單元測試框架 |

## 🧪 執行測試

```bash
# 執行所有測試
flutter test

# 執行特定測試檔案
flutter test test/models/todo_test.dart
flutter test test/widgets/empty_state_test.dart
```

## 🎨 開發環境

- **Flutter:** 3.41.5 (stable)
- **Dart:** 3.11.3
- **支援平台：** Android, iOS, Web, Windows, macOS, Linux

## 📝 開發筆記

### 修改 Todo 模型後
如果修改了 `lib/models/todo.dart` 中的模型結構，需要重新生成 Hive adapter：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 資料模型欄位
- `id` - 唯一識別碼（UUID）
- `title` - 事項標題（必填）
- `description` - 詳細描述（選填）
- `isCompleted` - 是否已完成
- `priority` - 優先級（0: 低，1: 中，2: 高）
- `dueDate` - 截止日期（選填）
- `category` - 分類（選填）
- `createdAt` - 建立時間（自動）
- `completedAt` - 完成時間（自動）

## 📚 學習資源

- [Flutter 官方文件](https://docs.flutter.dev/)
- [Provider 套件文件](https://pub.dev/packages/provider)
- [Hive 資料庫文件](https://docs.hivedb.dev/)
- [Material Design 3](https://m3.material.io/)

## 📄 License

MIT License

## Supabase 與 Android USB 實機除錯紀錄（2026-04）

### 本次問題根因總結

1. **`user_id` 型別不符**
- 錯誤訊息：`invalid input syntax for type uuid`（`22P02`）
- 原因：Supabase `todos.user_id` 欄位是 `UUID`，但 App 一開始送出的是裝置字串（例如：`e856b2e85ccb97ee`）
- 修正：在程式內將裝置 ID 正規化為合法 UUID（非 UUID 轉為穩定 UUID v5），並自動遷移舊快取值

2. **錯誤解讀誤會（`host` 不含 `https://`）**
- 看到 `Failed host lookup: omareqsfkeqslywwvkyg.supabase.co` 屬正常格式
- `host` 本來就只顯示網域，不會帶 `https://`
- 是否有 `https://` 應看完整 `URL` 欄位與 `scheme` 欄位

3. **Android 編譯端 Kotlin Daemon 快取鎖定**
- 典型現象：`Daemon compilation failed` / `Could not close incremental caches`
- 原因：Windows 下增量快取檔案被鎖住
- 修正：清理 `build/.dart_tool/android/.gradle`、停用 Kotlin daemon/incremental 後重建

---

### 手機如何開啟 USB 偵錯模式（Android）

1. 開啟「開發者選項」
- 設定 → 關於手機 → 連點「版本號碼（Build number）」7 次
- 看到「你現在是開發人員」即成功

2. 開啟「USB 偵錯」
- 設定 → 系統（或其他設定）→ 開發者選項 → 打開 `USB 偵錯`

3. 連接 USB 後允許授權
- 手機跳出「允許 USB 偵錯？」時按「允許」
- 建議勾選「一律允許這台電腦」

4. USB 連線模式切換為 `檔案傳輸 (MTP)`
- 不要使用「僅充電」

---

### 常用指令（Windows / PowerShell）

```powershell
# 進入專案
cd D:\github\chiisen\Flutter\todo_list

# 檢查 Flutter 與 Android 依賴
flutter doctor -v

# 啟動 adb 並檢查裝置
adb kill-server
adb start-server
adb devices

# 查看 Flutter 可見裝置
flutter devices

# 以指定裝置執行（<deviceId> 由 flutter devices 取得）
flutter run -d <deviceId>
```

---

### 怎麼找裝置 ID（`deviceId`）

1. 執行：

```powershell
flutter devices
```

2. 範例輸出：

```text
SM S918N (mobile) • R3CW123456A • android-arm64
```

3. 中間欄位就是裝置 ID，例如：
- `R3CW123456A`

4. 執行指定裝置：

```powershell
flutter run -d R3CW123456A
```

---

### 常見錯誤對照表

1. `Failed host lookup` / `SocketException`
- 類型：DNS/網路層
- 先檢查：手機網路、VPN、防火牆、公司網路限制
- 快速測試：手機瀏覽器開 `https://omareqsfkeqslywwvkyg.supabase.co/rest/v1/`

2. `401` / `403` / `Invalid API key` / `JWT`
- 類型：授權
- 先檢查：Supabase Anon Key 是否正確、是否過期或貼錯專案

3. `22P02 invalid input syntax for type uuid`
- 類型：資料格式
- 先檢查：`user_id` 是否為合法 UUID
- 若是舊版快取，清除 App 設定或重裝 App

4. `Daemon compilation failed` / `Could not close incremental caches`
- 類型：Android/Kotlin 建置快取鎖定
- 修復：完整清理快取再重建（見下節）

---

### Android 建置快取鎖定修復步驟

```powershell
cd D:\github\chiisen\Flutter\todo_list

# 關閉可能佔用檔案的程序（先關 Android Studio）
taskkill /F /IM java.exe
taskkill /F /IM adb.exe

# 清理快取
Remove-Item -Recurse -Force .\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\.dart_tool -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\android\.gradle -ErrorAction SilentlyContinue

# 重新抓依賴並執行
flutter clean
flutter pub get
flutter run
```

---

### 本專案 Supabase 固定設定

- Supabase URL 固定為：
  - `https://omareqsfkeqslywwvkyg.supabase.co`
- 設定畫面中的 URL 為唯讀，避免誤改
- 只需輸入正確的 `Anon Key`

### 為什麼要用這三步測試（`flutter clean` / `flutter pub get` / `flutter run`）

當你在排查「修過但還是報錯」時，這三步是最小且有效的驗證流程：

1. `flutter clean`
- 目的：清掉舊的編譯產物與快取
- 原因：避免誤跑到舊版程式（本次曾遇到 Kotlin/Gradle cache 鎖定）

2. `flutter pub get`
- 目的：重新同步依賴
- 原因：確保目前程式實際使用到的套件版本與 `pubspec.yaml` 一致

3. `flutter run`
- 目的：以「全新編譯」直接在裝置驗證
- 原因：可確認最新修正是否真的生效，而不是 hot reload 的殘留狀態

建議指令：

```powershell
cd D:\github\chiisen\Flutter\todo_list
flutter clean
flutter pub get
flutter run
```

補充：
- 若只做 hot reload/hot restart，初始化流程與快取有機會未完全重建，測試結果可能失真。
