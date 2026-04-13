# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2026-04-13

### Added
- **todo_list**: 在設定對話框中加入 Anon Key 的顯示/隱藏切換功能（使用 * 遮罩）。
- 初始化專案結構。
- 新增 `README.md` 包含安裝指南與專案說明。
- 建立 `todo_list` 範例專案。
- 在 `README.md` 新增「疑難排解」章節。
- **todo_list**: 新增 i18n 國際化支援（繁體中文、英文）。
- **todo_list**: 新增 `i18n.dart` 翻譯類別，提供多語言文字轉換。

### Changed
- **todo_list**: 將 `main.dart` 中的硬編碼文字改為使用 i18n 翻譯。
- **todo_list**: 移除 `SettingsDialog` 中多餘的 API 金鑰取得說明文字。

### Fixed
- 修復 Supabase URL 可能包含空白導致連線失敗的問題（SocketFailed host lookup）。
- 修復 Flutter SDK 路徑問題 (scoop shims)。
