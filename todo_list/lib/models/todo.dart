/// 優先級列舉
enum Priority {
  low,    // 低
  medium, // 中
  high,   // 高
}

/// 待辦事項資料模型
class Todo {
  String id;          // 唯一識別碼
  String userId;      // 使用者識別碼（多使用者隔離）
  String title;       // 事項標題
  bool isCompleted;   // 是否已完成
  String? description;  // 詳細描述（可選）
  int priority;       // 優先級 (0: low, 1: medium, 2: high)
  DateTime? dueDate;  // 截止日期（可選）
  String? category;   // 分類（可選）
  DateTime createdAt; // 建立時間
  DateTime? completedAt; // 完成時間

  Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    this.description,
    this.priority = 1,  // 預設為中
    this.dueDate,
    this.category,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 獲取優先級列舉
  Priority get priorityLevel => Priority.values[priority];

  /// 是否已過期
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// 是否即將到期（24 小時內）
  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays <= 1 && difference.inDays >= 0;
  }

  /// 複製並修改
  Todo copyWith({
    String? id,
    String? userId,
    String? title,
    bool? isCompleted,
    String? description,
    int? priority,
    DateTime? dueDate,
    String? category,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 轉換為 JSON（對應 Supabase 欄位：snake_case）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'is_completed': isCompleted,
      'description': description,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// 從 JSON 建立（對應 Supabase 欄位：snake_case）
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      description: json['description'] as String?,
      priority: json['priority'] as int? ?? 1,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      category: json['category'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isCompleted: $isCompleted, priority: ${priorityLevel.name})';
  }
}
