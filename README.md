# Flutter
Flutter 學習筆記

![TODO](./images/TODO.png)

## 安裝 Flutter (Windows)

### 使用 Scoop 安裝（推薦）

```bash
# 1. 安裝 Scoop
irm get.scoop.sh | iex

# 2. 安裝 Flutter
scoop install flutter

# 3. 驗證安裝
flutter doctor
```

### 其他方式

| 方式 | 命令 |
|------|------|
| **winget** | `winget install Google.Flutter` |
| **Chocolatey** | `choco install flutter -y` |
| **Git** | `git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter` |
| **手動** | [下載 ZIP](https://docs.flutter.dev/get-started/install/windows) |

---

## 安裝 Flutter (macOS)

### 使用 Homebrew 安裝（推薦）

```bash
# 1. 安裝 Homebrew（如果還沒有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 安裝 Flutter
brew install flutter

# 3. 驗證安裝
flutter doctor
```

### 設定 Android SDK（編譯 APK 需要）

```bash
# 1. 安裝 Android Studio
brew install --cask android-studio

# 2. 開啟 Android Studio 並完成首次設定
open -a "Android Studio"

# 3. 在 Android Studio 中安裝 Android SDK Command-line Tools
#    SDK Manager → SDK Tools → 勾選 "Android SDK Command-line Tools (latest)"

# 4. 設定 SDK 路徑並接受授權
flutter config --android-sdk ~/Library/Android/sdk
flutter doctor --android-licenses

# 5. 再次驗證
flutter doctor
```

### 其他方式

| 方式 | 命令 |
|------|------|
| **Git** | `git clone https://github.com/flutter/flutter.git -b stable ~/flutter` |
| **手動** | [下載 ZIP](https://docs.flutter.dev/get-started/install/macos) |

---

## 專案列表

### 📝 To Do List

一個功能完整的待辦事項管理應用程式。

**位置：** [`todo_list/`](todo_list/)

**功能特色：**

基本功能：
- ✅ 新增/編輯/刪除待辦事項
- ✅ 標記完成/未完成
- ✅ 滑動刪除（含確認對話框）
- ✅ 一鍵清除已完成
- ✅ 統計顯示（總數/進行中/已完成/已過期）

進階功能：
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

**技術棧：**
- **狀態管理：** Provider
- **資料持久化：** Hive（支援 Web/Android/iOS）
- **UI 框架：** Material Design 3
- **國際化：** 繁體中文/英文

**專案結構：**
```
todo_list/lib/
├── main.dart                  # 應用程式入口
├── i18n.dart                  # 國際化設定
├── models/
│   ├── todo.dart              # Todo 資料模型
│   └── todo.g.dart            # Hive Adapter（自動生成）
├── services/
│   └── todo_service.dart      # 資料持久化服務層
├── providers/
│   └── todo_provider.dart     # Provider 狀態管理
├── pages/
│   └── todo_list_page.dart    # 主頁面 UI
└── widgets/
    ├── todo_tile.dart         # 列表項目元件
    ├── todo_form_dialog.dart  # 新增/編輯對話框
    └── empty_state.dart       # 空狀態元件
```

**快速開始：**
```bash
cd todo_list
flutter pub get
flutter run
```

**執行測試：**
```bash
cd todo_list
flutter test
```

**編譯 APK：**
```bash
cd todo_list
flutter build apk --release
```

**APK 輸出位置：**
```
todo_list/build/app/outputs/flutter-apk/
├── todo_list-debug.apk      (開發測試用)
└── todo_list-release.apk    (發布用)
```

[詳細說明](todo_list/README.md)

---

## 開發環境

- **Flutter:** 3.41.5 (stable)
- **Dart:** 3.11.3
- **支援平台：** Android, iOS, Web, Windows, macOS, Linux

# 常用命令

```bash
# 檢查環境
flutter doctor

# 執行應用
flutter run

# 編譯 APK
flutter build apk

# 編譯 Web
flutter build web

# 執行測試
flutter test

# 執行特定測試檔案
flutter test test/widget_test.dart
```

---

## 疑難排解 (Troubleshooting)

### Windows: `flutter` 找不到指令
如果您透過 Scoop 安裝了 Flutter 但終端機顯示 `flutter: The term 'flutter' is not recognized`：

1. **重新建立路徑連結 (推薦)**
   ```powershell
   scoop reset flutter
   ```
2. **手動加入環境變數**
   確保 `C:\Users\<您的用戶名>\scoop\apps\flutter\current\bin` 已加入系統或使用者 `PATH`。
3. **重新啟動終端機**
   更新環境變數後，必須重啟 PowerShell 視窗才會生效。
