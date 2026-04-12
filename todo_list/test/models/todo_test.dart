import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/models/todo.dart';

void main() {
  group('Todo 模型測試', () {
    test('建立 Todo 實例', () {
      final todo = Todo(
        id: 'test-1',
        userId: 'test-user-123',
        title: '測試待辦',
        description: '這是測試描述',
        priority: 2,
        category: '工作',
      );

      expect(todo.id, 'test-1');
      expect(todo.title, '測試待辦');
      expect(todo.description, '這是測試描述');
      expect(todo.priority, 2);
      expect(todo.category, '工作');
      expect(todo.isCompleted, false);
      expect(todo.priorityLevel, Priority.high);
    });

    test('copyWith 方法', () {
      final todo = Todo(
        id: 'test-1',
        userId: 'test-user-123',
        title: '原始標題',
        priority: 1,
      );

      final updated = todo.copyWith(
        title: '更新後的標題',
        isCompleted: true,
      );

      expect(updated.title, '更新後的標題');
      expect(updated.isCompleted, true);
      expect(updated.id, todo.id); // ID 保持不變
      expect(updated.priority, todo.priority); // 優先級保持不變
    });

    test('isOverdue 屬性', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      // 已過期
      final overdueTodo = Todo(
        id: 'test-1',
        userId: 'test-user-123',
        title: '已過期',
        dueDate: yesterday,
        isCompleted: false,
      );
      expect(overdueTodo.isOverdue, true);

      // 未過期
      final activeTodo = Todo(
        id: 'test-2',
        userId: 'test-user-123',
        title: '未過期',
        dueDate: tomorrow,
        isCompleted: false,
      );
      expect(activeTodo.isOverdue, false);

      // 已完成不算過期
      final completedTodo = Todo(
        id: 'test-3',
        userId: 'test-user-123',
        title: '已完成',
        dueDate: yesterday,
        isCompleted: true,
      );
      expect(completedTodo.isOverdue, false);
    });

    test('isDueSoon 屬性', () {
      final now = DateTime.now();
      final in6Hours = now.add(const Duration(hours: 6));
      final in2Days = now.add(const Duration(days: 2));

      // 即將到期（6 小時內）
      final dueSoonTodo = Todo(
        id: 'test-1',
        userId: 'test-user-123',
        title: '即將到期',
        dueDate: in6Hours,
        isCompleted: false,
      );
      expect(dueSoonTodo.isDueSoon, true);

      // 不緊急（2 天後）
      final normalTodo = Todo(
        id: 'test-2',
        userId: 'test-user-123',
        title: '不緊急',
        dueDate: in2Days,
        isCompleted: false,
      );
      expect(normalTodo.isDueSoon, false);
    });

    test('toJson 和 fromJson', () {
      final original = Todo(
        id: 'test-1',
        userId: 'test-user-123',
        title: '測試',
        description: '描述',
        priority: 2,
        dueDate: DateTime(2024, 12, 31),
        category: '工作',
      );

      final json = original.toJson();
      final restored = Todo.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.priority, original.priority);
      expect(restored.category, original.category);
      expect(restored.dueDate, original.dueDate);
    });

    test('優先級列舉對應', () {
      final low = Todo(id: '1', userId: 'test-user', title: '低', priority: 0);
      final medium = Todo(id: '2', userId: 'test-user', title: '中', priority: 1);
      final high = Todo(id: '3', userId: 'test-user', title: '高', priority: 2);

      expect(low.priorityLevel, Priority.low);
      expect(medium.priorityLevel, Priority.medium);
      expect(high.priorityLevel, Priority.high);
    });
  });
}
