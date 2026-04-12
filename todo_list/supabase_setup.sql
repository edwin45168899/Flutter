-- Supabase 資料庫設定腳本
-- 在 Supabase Dashboard → SQL Editor 中執行此腳本
-- ⚠️ 若資料表已存在，請先刪除舊資料表或執行 ALTER TABLE 新增欄位

-- 1. 建立 todos 資料表（多使用者版本）
CREATE TABLE IF NOT EXISTS todos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid(), -- 🔑 使用者識別碼（關聯 Supabase Auth）
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT false,
  priority INTEGER DEFAULT 1,
  due_date TIMESTAMPTZ,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- 2. 建立索引（提升查詢效能）
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_todos_is_completed ON todos(is_completed);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);

-- 🔑 多使用者索引
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_user_created ON todos(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_todos_user_status ON todos(user_id, is_completed);

-- 3. 啟用 Row Level Security (RLS)
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- 4. 建立政策（測試模式：允許所有操作）
-- ⚠️ 正式環境應改為需要使用者認證
CREATE POLICY "Allow all operations for testing"
  ON todos
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 📌 正式環境政策（若需啟用 Auth，請取消註解下方政策）
-- DROP POLICY IF EXISTS "Allow all operations for testing" ON todos;
-- CREATE POLICY "Users can only access their own todos"
--   ON todos
--   FOR ALL
--   USING (auth.uid() = user_id)
--   WITH CHECK (auth.uid() = user_id);

-- 5. 註解（方便理解欄位用途）
COMMENT ON TABLE todos IS '待辦事項資料表（支援多使用者）';
COMMENT ON COLUMN todos.id IS '唯一識別碼 (UUID)';
COMMENT ON COLUMN todos.user_id IS '使用者識別碼 (關聯 Supabase Auth)';
COMMENT ON COLUMN todos.title IS '事項標題';
COMMENT ON COLUMN todos.description IS '詳細描述';
COMMENT ON COLUMN todos.is_completed IS '是否已完成';
COMMENT ON COLUMN todos.priority IS '優先級 (0: 低, 1: 中, 2: 高)';
COMMENT ON COLUMN todos.due_date IS '截止日期';
COMMENT ON COLUMN todos.category IS '分類標籤';
COMMENT ON COLUMN todos.created_at IS '建立時間';
COMMENT ON COLUMN todos.completed_at IS '完成時間';
