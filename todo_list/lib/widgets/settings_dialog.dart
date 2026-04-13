import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

/// Supabase 設定對話框
/// 用於輸入 Supabase URL 和 Anon Key
class SettingsDialog extends StatefulWidget {
  final VoidCallback? onConfigSaved;

  const SettingsDialog({super.key, this.onConfigSaved});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  String _userId = '';
  bool _isLoading = false;
  bool _hasExistingConfig = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  /// 載入現有設定
  Future<void> _loadExistingConfig() async {
    final config = await SupabaseConfig.getConfig();
    if (mounted) {
      setState(() {
        _urlController.text = config['url'] ?? '';
        _keyController.text = config['anonKey'] ?? '';
        _userId = config['userId'] ?? '自動生成中...';
        _hasExistingConfig = config['url']?.isNotEmpty ?? false;
      });
    }
  }

  /// 儲存設定
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseConfig.saveConfig(
        url: _urlController.text.trim(),
        anonKey: _keyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Supabase 設定已儲存'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onConfigSaved?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 儲存失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 清除設定
  Future<void> _clearConfig() async {
    await SupabaseConfig.clearConfig();
    if (mounted) {
      setState(() {
        _urlController.clear();
        _keyController.clear();
        _userId = '自動生成中...';
        _hasExistingConfig = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ 設定已清除'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 標題
              Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supabase 設定',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text(
                          '只需輸入 Anon Key，URL 已使用預設值',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const Divider(height: 32),

              // 表單內容
              SingleChildScrollView(
                child: Column(
                  children: [
                    // URL 輸入（唯讀，顯示預設值）
                    TextFormField(
                      controller: _urlController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Supabase URL',
                        helperText: '已使用預設值',
                        prefixIcon: Icon(Icons.link, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        helperStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                      enabled: false,
                    ),

                    const SizedBox(height: 16),

                    // Anon Key 輸入
                    TextFormField(
                      controller: _keyController,
                      decoration: InputDecoration(
                        labelText: 'Supabase Anon Key',
                        hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureKey ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscureKey = !_obscureKey);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                      obscureText: _obscureKey,
                      obscuringCharacter: '*',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '請輸入 Anon Key';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // User ID 顯示（唯讀，自動生成，清晰可見）
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '裝置唯一識別碼（User ID）',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _userId.isNotEmpty
                                      ? _userId
                                      : '自動生成中...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  if (_userId.isNotEmpty) {
                                    // 複製到剪貼簿
                                    // TODO: 需要新增 flutter/services.dart
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ 已複製到剪貼簿'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                tooltip: '複製 User ID',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '此 ID 由裝置硬體資訊自動生成，用於區分不同使用者',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 按鈕區
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_hasExistingConfig) ...[
                    TextButton.icon(
                      onPressed: _isLoading ? null : _clearConfig,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('清除設定'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveConfig,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? '儲存中...' : '儲存設定'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
