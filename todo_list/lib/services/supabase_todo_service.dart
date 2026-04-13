import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo.dart';
import '../config/supabase_config.dart';

/// Supabase 待辦事項服務
/// 負責與 Supabase PostgreSQL 資料庫進行 CRUD 操作
/// 支援多使用者隔離（使用 user_id 過濾）
class SupabaseTodoService {
  /// 目前使用者的 ID（從本地設定取得）
  String? _currentUserId;

  /// 公開取得當前使用者 ID
  String? get currentUserId => _currentUserId;

  /// 初始化並取得當前使用者 ID
  Future<void> initializeCurrentUser() async {
    _currentUserId = await SupabaseConfig.getUserId();
    debugPrint('👤 當前使用者 ID: $_currentUserId');
  }

  /// 確保 Supabase 已初始化
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// 取得 SupabaseClient（延遲存取）
  SupabaseClient get _supabase => Supabase.instance.client;

  /// 取得當前使用者 ID（若未初始化則自動初始化）
  Future<String> _ensureUserId() async {
    if (_currentUserId == null) {
      await initializeCurrentUser();
    }
    final userId = _currentUserId!;
    if (!SupabaseConfig.isValidUuid(userId)) {
      throw Exception('user_id 非法，必須為 UUID：$userId');
    }
    return userId;
  }

  /// 獲取所有待辦事項（僅限當前使用者）
  Future<List<Todo>> getAllTodos() async {
    try {
      final userId = await _ensureUserId();
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Todo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ 獲取待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 獲取未完成的待辦事項
  Future<List<Todo>> getActiveTodos() async {
    try {
      final userId = await _ensureUserId();
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', userId)
          .eq('is_completed', false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Todo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ 獲取未完成待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 獲取已完成的待辦事項
  Future<List<Todo>> getCompletedTodos() async {
    try {
      final userId = await _ensureUserId();
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => Todo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ 獲取已完成待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 根據 ID 獲取待辦事項（需驗證擁有者）
  Future<Todo?> getTodoById(String id) async {
    try {
      final userId = await _ensureUserId();
      final response = await _supabase
          .from('todos')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .single();

      return Todo.fromJson(response);
    } catch (e) {
      debugPrint('❌ 獲取待辦事項 ($id) 失敗：$e');
      return null;
    }
  }

  /// 新增待辦事項（自動帶入 user_id）
  Future<Todo> addTodo({
    required String title,
    String? description,
    int priority = 1,
    DateTime? dueDate,
    String? category,
  }) async {
    try {
      final userId = await _ensureUserId();
      final response = await _supabase
          .from('todos')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'priority': priority,
            'due_date': dueDate?.toIso8601String(),
            'category': category,
            'is_completed': false,
          })
          .select()
          .single();

      return Todo.fromJson(response);
    } catch (e) {
      debugPrint('❌ 新增待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 更新待辦事項
  Future<void> updateTodo(Todo todo) async {
    try {
      final userId = await _ensureUserId();
      await _supabase
          .from('todos')
          .update(todo.toJson())
          .eq('id', todo.id)
          .eq('user_id', userId); // 確保只能更新自己的資料
    } catch (e) {
      debugPrint('❌ 更新待辦事項 (${todo.id}) 失敗：$e');
      rethrow;
    }
  }

  /// 切換完成狀態
  Future<void> toggleTodo(String id) async {
    try {
      final todo = await getTodoById(id);
      if (todo == null) return;

      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: !todo.isCompleted ? DateTime.now() : null,
      );

      await updateTodo(updatedTodo);
    } catch (e) {
      debugPrint('❌ 切換完成狀態失敗：$e');
      rethrow;
    }
  }

  /// 刪除待辦事項
  Future<void> deleteTodo(String id) async {
    try {
      final userId = await _ensureUserId();
      await _supabase
          .from('todos')
          .delete()
          .eq('id', id)
          .eq('user_id', userId); // 確保只能刪除自己的資料
    } catch (e) {
      debugPrint('❌ 刪除待辦事項 ($id) 失敗：$e');
      rethrow;
    }
  }

  /// 批量刪除
  Future<void> deleteTodos(List<String> ids) async {
    try {
      final userId = await _ensureUserId();
      await _supabase
          .from('todos')
          .delete()
          .inFilter('id', ids)
          .eq('user_id', userId); // 確保只能刪除自己的資料
    } catch (e) {
      debugPrint('❌ 批量刪除待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 清除已完成的待辦事項
  Future<void> clearCompleted() async {
    try {
      final userId = await _ensureUserId();
      await _supabase
          .from('todos')
          .delete()
          .eq('is_completed', true)
          .eq('user_id', userId); // 確保只能清除自己的資料
    } catch (e) {
      debugPrint('❌ 清除已完成待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 搜尋待辦事項
  Future<List<Todo>> searchTodos(String query) async {
    try {
      final userId = await _ensureUserId();
      
      if (query.trim().isEmpty) {
        return getAllTodos();
      }

      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Todo.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ 搜尋待辦事項失敗：$e');
      rethrow;
    }
  }

  /// 獲取統計資訊
  Future<Map<String, int>> getStats() async {
    try {
      final all = await getAllTodos();
      final completed = getCompletedTodos();
      final active = getActiveTodos();
      final overdue = (await active).where((todo) => todo.isOverdue).length;

      return {
        'total': all.length,
        'completed': (await completed).length,
        'active': (await active).length,
        'overdue': overdue,
      };
    } catch (e) {
      debugPrint('❌ 獲取統計資訊失敗：$e');
      return {
        'total': 0,
        'completed': 0,
        'active': 0,
        'overdue': 0,
      };
    }
  }
}
