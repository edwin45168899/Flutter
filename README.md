# Flutter
Flutter 學習筆記

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

一個簡單的待辦事項管理應用程式。

**位置：** [`todo_list/`](todo_list/)

**功能特色：**
- ✅ 新增待辦事項
- ✅ 標記完成/未完成
- ✅ 滑動刪除
- ✅ 一鍵清除已完成
- ✅ 統計顯示

**快速開始：**
```bash
cd todo_list
flutter run
```

**APK 下載：**
```
todo_list/build/app/outputs/flutter-apk/
├── app-debug.apk    (開發測試用)
└── app-release.apk  (發布用)
```

[詳細說明](todo_list/README.md)

---

## 開發環境

- **Flutter:** 3.41.5 (stable)
- **Dart:** 3.11.3
- **支援平台：** Android, iOS, Web, Windows, macOS, Linux

## 常用命令

```bash
# 檢查環境
flutter doctor

# 執行應用
flutter run

# 編譯 APK
flutter build apk

# 編譯 Web
flutter build web
```
