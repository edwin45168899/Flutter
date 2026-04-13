# 更新日誌

所有本專案的重要變更均記錄在此檔案中。

此專案遵循 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.0.0/) 規範。

## [未發佈]

## [1.1.5] - 2026-04-14

### 修復
- **Supabase**: 強化 `user_id` UUID 生成的容錯與驗證機制
  - 新增 `normalizeUserId()` 的 try-catch 與降級機制（UUID v5 生成失敗時改用 v4）
  - 新增 `getUserId()` 的最終驗證保障，確保無論任何情況都回傳合法 UUID
  - 解決 Android 設備上 `flutter_udid` 回傳非法 UUID 格式導致資料庫操作失敗的問題

### 新增
- 新增 UUID 與連線診斷相關文件
- 實現 Supabase 初始化、連線狀態診斷及設定管理
- 實現 Supabase 健康檢查及錯誤處理機制

---

## 版本發佈歷史

### [1.1.5]
- 發佈日期: 2026-04-14
- UUID 容錯機制完善版本

### [1.1.4] 及以前
- 初始版本與開發階段
