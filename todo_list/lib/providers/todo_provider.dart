import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/supabase_todo_service.dart';

/// 待辦事項提供者
/// 使用 Provider 模式進行狀態管理（Supabase 雲端版本）
class TodoProvider extends ChangeNotifier {
  final SupabaseTodoService _todoService = SupabaseTodoService();

  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.createdAt;
  bool _ascending = false;
  FilterOption _filterOption = FilterOption.all;
  String? _error; // 錯誤訊息

  // 最後刪除的項目（用於撤銷）
  List<Todo> _lastDeletedTodos = [];

  /// 當前使用者 ID
  String? get currentUserId => _todoService.currentUserId;

  /// 錯誤訊息
  String? get error => _error;

  /// 獲取所有待辦事項
  List<Todo> get todos => _filteredTodos;
  
  /// 獲取原始所有待辦事項
  List<Todo> get allTodos => _todos;

  /// 是否正在載入
  bool get isLoading => _isLoading;

  /// 搜尋關鍵字
  String get searchQuery => _searchQuery;

  /// 當前排序選項
  SortOption get sortOption => _sortOption;

  /// 是否遞增排序
  bool get ascending => _ascending;

  /// 當前篩選選項
  FilterOption get filterOption => _filterOption;

  /// 最後刪除的項目
  List<Todo> get lastDeletedTodos => _lastDeletedTodos;

  /// 統計資訊（同步，使用記憶體資料）
  Map<String, int> get stats {
    final completed = _todos.where((t) => t.isCompleted).length;
    final active = _todos.where((t) => !t.isCompleted).length;
    final overdue = _todos.where((t) => t.isOverdue).length;

    return {
      'total': _todos.length,
      'completed': completed,
      'active': active,
      'overdue': overdue,
    };
  }

  /// 初始化
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 確保使用者 ID 已初始化
      await _todoService.initializeCurrentUser();
      _todos = await _todoService.getAllTodos();
      _applyFiltersAndSort();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint('初始化失敗：$_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重新載入（從雲端同步）
  Future<void> reload() async {
    await init();
  }

  /// 新增待辦事項
  Future<Todo> addTodo({
    required String title,
    String? description,
    int priority = 1,
    DateTime? dueDate,
    String? category,
  }) async {
    final todo = await _todoService.addTodo(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      category: category,
    );
    _todos.add(todo);
    _applyFiltersAndSort();
    notifyListeners();
    return todo;
  }

  /// 更新待辦事項
  Future<void> updateTodo(Todo todo) async {
    await _todoService.updateTodo(todo);
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      _applyFiltersAndSort();
      notifyListeners();
    }
  }

  /// 切換完成狀態
  Future<void> toggleTodo(String id) async {
    await _todoService.toggleTodo(id);
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final todo = _todos[index];
      _todos[index] = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: !todo.isCompleted ? DateTime.now() : null,
      );
      _applyFiltersAndSort();
      notifyListeners();
    }
  }

  /// 刪除待辦事項（支援撤銷）
  Future<void> deleteTodo(String id, {bool enableUndo = true}) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    _todos.removeWhere((t) => t.id == id);
    
    if (enableUndo) {
      _lastDeletedTodos = [todo];
    }
    
    await _todoService.deleteTodo(id);
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 撤銷刪除
  Future<void> undoDelete() async {
    if (_lastDeletedTodos.isEmpty) return;
    
    for (final todo in _lastDeletedTodos) {
      _todos.add(todo);
      await _todoService.updateTodo(todo);
    }
    
    _lastDeletedTodos.clear();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 清除最後刪除的記錄
  void clearUndoStack() {
    _lastDeletedTodos.clear();
  }

  /// 批量刪除
  Future<void> deleteTodos(List<String> ids) async {
    final deletedTodos = _todos.where((t) => ids.contains(t.id)).toList();
    _todos.removeWhere((t) => ids.contains(t.id));
    
    _lastDeletedTodos = deletedTodos;
    
    await _todoService.deleteTodos(ids);
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 清除已完成的
  Future<void> clearCompleted() async {
    final completedTodos = _todos.where((t) => t.isCompleted).toList();
    
    _todos.removeWhere((t) => t.isCompleted);
    _lastDeletedTodos = completedTodos;
    
    await _todoService.clearCompleted();
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 設定搜尋關鍵字
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 設定排序選項
  void setSortOption(SortOption option, {bool? ascending}) {
    _sortOption = option;
    if (ascending != null) {
      _ascending = ascending;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 切換排序方向
  void toggleSortDirection() {
    _ascending = !_ascending;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 設定篩選選項
  void setFilterOption(FilterOption option) {
    _filterOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  /// 套用篩選和排序
  void _applyFiltersAndSort() {
    // 1. 套用篩選
    _filteredTodos = _todos.where((todo) {
      // 搜尋篩選
      if (_searchQuery.isNotEmpty) {
        final lowerQuery = _searchQuery.toLowerCase();
        final titleMatch = todo.title.toLowerCase().contains(lowerQuery);
        final descMatch = todo.description?.toLowerCase().contains(lowerQuery) ?? false;
        final categoryMatch = todo.category?.toLowerCase().contains(lowerQuery) ?? false;
        if (!titleMatch && !descMatch && !categoryMatch) {
          return false;
        }
      }
      
      // 狀態篩選
      switch (_filterOption) {
        case FilterOption.all:
          return true;
        case FilterOption.active:
          return !todo.isCompleted;
        case FilterOption.completed:
          return todo.isCompleted;
        case FilterOption.overdue:
          return todo.isOverdue;
      }
    }).toList();
    
    // 2. 套用排序
    switch (_sortOption) {
      case SortOption.createdAt:
        _filteredTodos.sort((a, b) => 
          _ascending ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dueDate:
        _filteredTodos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return _ascending ? -1 : 1;
          if (b.dueDate == null) return _ascending ? 1 : -1;
          return _ascending ? a.dueDate!.compareTo(b.dueDate!) : b.dueDate!.compareTo(a.dueDate!);
        });
        break;
      case SortOption.priority:
        _filteredTodos.sort((a, b) => 
          _ascending ? a.priority.compareTo(b.priority) : b.priority.compareTo(a.priority));
        break;
      case SortOption.title:
        _filteredTodos.sort((a, b) => 
          _ascending ? a.title.compareTo(b.title) : b.title.compareTo(a.title));
        break;
      case SortOption.completed:
        _filteredTodos.sort((a, b) {
          // bool 沒有 compareTo，使用比較邏輯
          if (a.isCompleted == b.isCompleted) return 0;
          return _ascending ? (a.isCompleted ? 1 : -1) : (b.isCompleted ? 1 : -1);
        });
        break;
    }
  }

  /// 釋放資源
  @override
  void dispose() {
    super.dispose();
  }
}

/// 排序選項
enum SortOption {
  createdAt,   // 依建立時間
  dueDate,     // 依截止日期
  priority,    // 依優先級
  title,       // 依標題
  completed,   // 依完成狀態
}

/// 篩選選項
enum FilterOption {
  all,        // 全部
  active,     // 進行中
  completed,  // 已完成
  overdue,    // 已過期
}
