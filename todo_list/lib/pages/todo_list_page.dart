import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../config/supabase_config.dart';
import '../models/todo.dart';
import '../widgets/todo_tile.dart';
import '../widgets/todo_form_dialog.dart';
import '../widgets/empty_state.dart';

/// 待辦事項列表頁面
class TodoListPage extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const TodoListPage({super.key, this.onOpenSettings});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        // 顯示錯誤 pop up
        if (todoProvider.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(context, todoProvider.error!);
          });
        }

        if (todoProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('待辦事項'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              // 連線狀態 + 設定按鈕
              FutureBuilder<bool>(
                future: SupabaseConfig.hasAnonKey(),
                builder: (context, snapshot) {
                  final isConnected = snapshot.data ?? false;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: widget.onOpenSettings,
                        tooltip: 'Supabase 設定',
                      ),
                      if (isConnected)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // 重新整理
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => todoProvider.reload(),
                tooltip: '重新整理',
              ),
              // 搜尋按鈕
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchBar(context),
                tooltip: '搜尋',
              ),
              // 篩選選單
              _buildFilterMenu(context, todoProvider),
              // 清除已完成
              if (todoProvider.stats['completed']! > 0)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _confirmClearCompleted(context, todoProvider),
                  tooltip: '清除已完成',
                ),
            ],
          ),
          body: Column(
            children: [
              // 統計資訊卡片
              _buildStatsCard(context, todoProvider),
              const Divider(height: 1),
              // 列表區域
              Expanded(
                child: todoProvider.todos.isEmpty
                    ? _buildEmptyState(todoProvider)
                    : _buildTodoList(context, todoProvider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTodoDialog(context, todoProvider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  /// 建立統計資訊卡片
  Widget _buildStatsCard(BuildContext context, TodoProvider provider) {
    final stats = provider.stats;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.task,
            label: '總計',
            value: stats['total']!,
            color: Colors.blue,
          ),
          _buildStatItem(
            context,
            icon: Icons.pending_actions,
            label: '進行中',
            value: stats['active']!,
            color: Colors.orange,
          ),
          _buildStatItem(
            context,
            icon: Icons.check_circle,
            label: '已完成',
            value: stats['completed']!,
            color: Colors.green,
          ),
          _buildStatItem(
            context,
            icon: Icons.warning,
            label: '已過期',
            value: stats['overdue']!,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  /// 建立空狀態
  Widget _buildEmptyState(TodoProvider provider) {
    IconData icon;
    String title;
    String? subtitle;

    switch (provider.filterOption) {
      case FilterOption.active:
        icon = Icons.check_circle_outline;
        title = '沒有進行中的事項';
        subtitle = '所有事項都已完成！';
        break;
      case FilterOption.completed:
        icon = Icons.inventory_2_outlined;
        title = '沒有已完成的事項';
        subtitle = '繼續努力完成待辦事項吧！';
        break;
      case FilterOption.overdue:
        icon = Icons.event_available;
        title = '沒有已過期的事項';
        subtitle = '太棒了！所有事項都按時完成';
        break;
      case FilterOption.all:
        icon = Icons.task_alt;
        title = '還沒有待辦事項';
        subtitle = '點擊右下角按鈕新增第一項待辦';
        break;
    }

    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: provider.filterOption == FilterOption.all
          ? FilledButton.icon(
              onPressed: () => _showAddTodoDialog(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('新增待辦'),
            )
          : null,
    );
  }

  /// 建立待辦列表
  Widget _buildTodoList(BuildContext context, TodoProvider provider) {
    return RefreshIndicator(
      onRefresh: () async {
        // 重新整理邏輯（可選）
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: provider.todos.length,
        itemBuilder: (context, index) {
          final todo = provider.todos[index];
          return TodoTile(
            todo: todo,
            onToggle: () => provider.toggleTodo(todo.id),
            onDelete: () {
              provider.deleteTodo(todo.id);
              _showUndoSnackbar(context, provider);
            },
            onEdit: () => _showEditTodoDialog(context, todo, provider),
          );
        },
      ),
    );
  }

  /// 顯示搜尋欄
  void _showSearchBar(BuildContext context) {
    showSearch(
      context: context,
      delegate: TodoSearchDelegate(context),
    );
  }

  /// 建立篩選選單
  Widget _buildFilterMenu(BuildContext context, TodoProvider provider) {
    return PopupMenuButton<FilterOption>(
      icon: const Icon(Icons.filter_list),
      tooltip: '篩選',
      onSelected: (option) => provider.setFilterOption(option),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: FilterOption.all,
          child: Row(
            children: [
              Icon(Icons.all_inclusive),
              SizedBox(width: 8),
              Text('全部'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: FilterOption.active,
          child: Row(
            children: [
              Icon(Icons.pending_actions),
              SizedBox(width: 8),
              Text('進行中'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: FilterOption.completed,
          child: Row(
            children: [
              Icon(Icons.check_circle),
              SizedBox(width: 8),
              Text('已完成'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: FilterOption.overdue,
          child: Row(
            children: [
              Icon(Icons.warning),
              SizedBox(width: 8),
              Text('已過期'),
            ],
          ),
        ),
      ],
    );
  }

  /// 顯示新增對話框
  Future<void> _showAddTodoDialog(BuildContext context, TodoProvider provider) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const TodoFormDialog(),
    );

    if (result != null && mounted) {
      await provider.addTodo(
        title: result['title'] as String,
        description: result['description'] as String?,
        priority: result['priority'] as int,
        dueDate: result['dueDate'] as DateTime?,
        category: result['category'] as String?,
      );
    }
  }

  /// 顯示編輯對話框
  Future<void> _showEditTodoDialog(
    BuildContext context,
    Todo todo,
    TodoProvider provider,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TodoFormDialog(todo: todo),
    );

    if (result != null && mounted) {
      final updatedTodo = todo.copyWith(
        title: result['title'] as String,
        description: result['description'] as String?,
        priority: result['priority'] as int,
        dueDate: result['dueDate'] as DateTime?,
        category: result['category'] as String?,
      );
      await provider.updateTodo(updatedTodo);
    }
  }

  /// 確認清除已完成
  Future<void> _confirmClearCompleted(
    BuildContext context,
    TodoProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認清除'),
        content: Text('確定要清除所有 ${provider.stats['completed']} 個已完成的事項嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      provider.clearCompleted();
      _showUndoSnackbar(context, provider);
    }
  }

  /// 顯示撤銷 Snackbar
  void _showUndoSnackbar(BuildContext context, TodoProvider provider) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已刪除'),
        action: SnackBarAction(
          label: '撤銷',
          onPressed: () => provider.undoDelete(),
        ),
        duration: const Duration(seconds: 3),
        onVisible: () {
          // 當 Snackbar 消失時清除撤銷堆疊
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) provider.clearUndoStack();
          });
        },
      ),
    );
  }
}

/// 搜尋委託
class TodoSearchDelegate extends SearchDelegate {
  final BuildContext parentContext;

  TodoSearchDelegate(this.parentContext);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        provider.setSearchQuery(query);
        return ListView.builder(
          itemCount: provider.todos.length,
          itemBuilder: (context, index) {
            final todo = provider.todos[index];
            return TodoTile(
              todo: todo,
              onToggle: () => provider.toggleTodo(todo.id),
              onDelete: () => provider.deleteTodo(todo.id),
              onEdit: () {
                close(context, null);
                _showEditTodoDialog(context, todo, provider);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  void _showEditTodoDialog(
    BuildContext context,
    Todo todo,
    TodoProvider provider,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TodoFormDialog(todo: todo),
    );

    if (result != null && context.mounted) {
      final updatedTodo = todo.copyWith(
        title: result['title'] as String,
        description: result['description'] as String?,
        priority: result['priority'] as int,
        dueDate: result['dueDate'] as DateTime?,
        category: result['category'] as String?,
      );
      await provider.updateTodo(updatedTodo);
    }
  }
}

/// 顯示錯誤訊息 SnackBar
void _showErrorSnackBar(BuildContext context, String error) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('連線錯誤', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            error.length > 100 ? '${error.substring(0, 100)}...' : error,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: '重新整理',
        textColor: Colors.white,
        onPressed: () {
          context.read<TodoProvider>().reload();
        },
      ),
    ),
  );
}
