import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'i18n.dart';
import 'pages/todo_list_page.dart';
import 'providers/todo_provider.dart';
import 'config/supabase_config.dart';
import 'widgets/settings_dialog.dart';
import 'services/supabase_todo_service.dart';

Future<void> _runSupabaseStartupDiagnostics({
  required String url,
  required String anonKey,
}) async {
  final normalizedUrl = SupabaseConfig.normalizeUrl(url);
  final uri = Uri.tryParse(normalizedUrl);

  debugPrint('[Supabase 診斷] rawUrl="$url"');
  debugPrint('[Supabase 診斷] normalizedUrl="$normalizedUrl"');
  debugPrint('[Supabase 診斷] anonKeyLength=${anonKey.length}');

  if (uri == null) {
    debugPrint('[Supabase 診斷] URL 解析失敗');
    return;
  }

  debugPrint('[Supabase 診斷] scheme=${uri.scheme}');
  debugPrint('[Supabase 診斷] host=${uri.host}');
  debugPrint('[Supabase 診斷] path=${uri.path}');
}

Future<void> _runSupabaseHealthCheck() async {
  try {
    final response = await Supabase.instance.client
        .from('todos')
        .select('id')
        .limit(1);
    debugPrint('[Supabase 診斷] health check 成功，rows=${(response as List).length}');
  } catch (e, stackTrace) {
    debugPrint('[Supabase 診斷] health check 失敗：$e');
    debugPrint('[Supabase 診斷] stackTrace: $stackTrace');
  }
}

Future<String> _buildStartupErrorDetails(Object error) async {
  final url = await SupabaseConfig.getUrl();
  final anonKey = await SupabaseConfig.getAnonKey() ?? '';
  final uri = Uri.tryParse(url);

  final scheme = uri?.scheme.isNotEmpty == true ? uri!.scheme : '(empty)';
  final host = uri?.host.isNotEmpty == true ? uri!.host : '(empty)';

  return [
    '啟動初始化失敗：$error',
    'URL：$url',
    'scheme：$scheme',
    'host：$host',
    'anonKey 長度：${anonKey.length}',
  ].join('\n');
}

/// 應用程式入口函式
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 檢查是否已有 Anon Key
  final hasKey = await SupabaseConfig.hasAnonKey();
  String? startupError;

  if (hasKey) {
    // 已有設定：初始化 Supabase
    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey();

    if (anonKey != null && anonKey.isNotEmpty) {
      try {
        await _runSupabaseStartupDiagnostics(url: url, anonKey: anonKey);
        await SupabaseTodoService.initialize(
          url: url,
          anonKey: anonKey,
        );
        await _runSupabaseHealthCheck();
      } catch (e) {
        startupError = await _buildStartupErrorDetails(e);
      }
    }
  }

  // 初始化 Provider
  final todoProvider = TodoProvider();
  if (hasKey) {
    await todoProvider.init();
  }

  runApp(TodoApp(isConfigured: hasKey, startupError: startupError));
}

/// 全域 Navigator Key（用於在任意位置取得 context）
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 待辦事項應用程式主體
class TodoApp extends StatefulWidget {
  final bool isConfigured;
  final String? startupError;

  const TodoApp({super.key, required this.isConfigured, this.startupError});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late bool _hasKey;
  late TodoProvider _todoProvider;
  String? _connectionError;

  Future<String> _buildConnectionDiagnostics(Object error) async {
    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey() ?? '';
    final uri = Uri.tryParse(url);

    final scheme = uri?.scheme.isNotEmpty == true ? uri!.scheme : '(empty)';
    final host = uri?.host.isNotEmpty == true ? uri!.host : '(empty)';

    return [
      '錯誤：$error',
      'URL：$url',
      'scheme：$scheme',
      'host：$host',
      'anonKey 長度：${anonKey.length}',
    ].join('\n');
  }

  @override
  void initState() {
    super.initState();
    _hasKey = widget.isConfigured;
    _todoProvider = TodoProvider();
    if (widget.startupError != null && widget.startupError!.isNotEmpty) {
      _connectionError = widget.startupError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConnectionErrorDialog();
      });
    }
    if (_hasKey) {
      _initProvider();
    }
  }

  /// 初始化 Provider（等 Supabase 就緒後）
  Future<void> _initProvider() async {
    try {
      await _todoProvider.init();
    } catch (e) {
      final diagnostic = await _buildConnectionDiagnostics(e);
      if (mounted) {
        setState(() {
          _connectionError = diagnostic;
        });
        _showConnectionErrorDialog();
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// 顯示連線錯誤對話框
  void _showConnectionErrorDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
        title: const Text('Supabase 連線錯誤'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('連線到 Supabase 伺服器失敗，請檢查：'),
              const SizedBox(height: 12),
              Text('• 網路連線是否正常', style: const TextStyle(fontSize: 13)),
              Text('• Anon Key 是否正確', style: const TextStyle(fontSize: 13)),
              Text('• Supabase 專案是否正常運作', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _connectionError ?? '未知錯誤',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showSettingsDialog();
            },
            icon: const Icon(Icons.settings),
            label: const Text('重新設定'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _initProvider();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重試'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 重新初始化 Supabase 並重新載入資料
  Future<void> _reinitializeSupabase() async {
    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey();

    if (anonKey != null && anonKey.isNotEmpty) {
      try {
        await _runSupabaseStartupDiagnostics(url: url, anonKey: anonKey);
        await SupabaseTodoService.initialize(
          url: url,
          anonKey: anonKey,
        );
        await _runSupabaseHealthCheck();

        if (mounted) {
          setState(() {
            _hasKey = true;
            _connectionError = null;
          });
          await _todoProvider.init();
        }
      } catch (e) {
        final diagnostic = await _buildConnectionDiagnostics(e);
        if (mounted) {
          setState(() {
            _connectionError = diagnostic;
          });
          _showConnectionErrorDialog();
        }
      }
    }
  }

  /// 顯示設定對話框（使用 navigatorKey 取得 context）
  void _showSettingsDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog<bool>(
      context: context,
      barrierDismissible: _hasKey,
      builder: (dialogContext) => SettingsDialog(
        onConfigSaved: () async {
          await _reinitializeSupabase();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _todoProvider,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 480;

          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'To Do List (Supabase)',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode: ThemeMode.system,
            home: _HomeContent(
              isWideScreen: isWideScreen,
              onOpenSettings: _showSettingsDialog,
              hasKey: _hasKey,
            ),
            localizationsDelegates: [
              const AppLocalizationsDelegate(AppLocale.zhTW),
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: const [
              Locale('zh', 'TW'),
              Locale('en', 'US'),
            ],
            locale: const Locale('zh', 'TW'),
          );
        },
      ),
    );
  }
}

/// 首頁內容（處理首次啟動設定對話框）
class _HomeContent extends StatefulWidget {
  final bool isWideScreen;
  final VoidCallback onOpenSettings;
  final bool hasKey;

  const _HomeContent({
    required this.isWideScreen,
    required this.onOpenSettings,
    required this.hasKey,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _hasShownSettings = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 只有在沒有 Key 且第一次 build 時才顯示設定對話框
    if (!widget.hasKey && !_hasShownSettings) {
      _hasShownSettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOpenSettings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isWideScreen
        ? Center(
            child: SizedBox(
              width: 480,
              child: TodoListPage(
                onOpenSettings: widget.onOpenSettings,
              ),
            ),
          )
        : TodoListPage(
            onOpenSettings: widget.onOpenSettings,
          );
  }
}
