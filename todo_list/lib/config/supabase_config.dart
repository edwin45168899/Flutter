import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:uuid/uuid.dart';

/// Supabase 設定管理器
/// 使用 SharedPreferences 儲存使用者的 Supabase 連線設定
class SupabaseConfig {
  /// 預設 Supabase URL（Demo 用）
  static const String defaultUrl = 'https://omareqsfkeqslywwvkyg.supabase.co';
  
  /// 預設 Supabase Anon Key（必須由使用者輸入，預設為空）
  static const String defaultAnonKey = '';

  static const String _keyUrl = 'supabase_url';
  static const String _keyAnonKey = 'supabase_anon_key';
  static const String _keyUserId = 'supabase_user_id';
  static const String _keyIsConfigured = 'supabase_is_configured';
  static const Uuid _uuid = Uuid();

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  /// 檢查字串是否為合法 UUID
  static bool isValidUuid(String? value) {
    if (value == null) return false;
    return _uuidRegex.hasMatch(value.trim());
  }

  /// 正規化 Supabase URL（去空白、移除尾端斜線）
  static String normalizeUrl(String input) {
    final clean = input.replaceAll(RegExp(r'\s+'), '').trim();
    return clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean;
  }

  /// 檢查是否已完成設定
  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsConfigured) ?? false;
  }

  /// 取得 Supabase URL（若無則回傳預設值）
  static Future<String> getUrl() async {
    return normalizeUrl(defaultUrl);
  }

  /// 取得 Supabase Anon Key
  static Future<String?> getAnonKey() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_keyAnonKey) ?? defaultAnonKey).trim();
  }

  /// 取得裝置唯一 ID（使用 flutter_udid）
  /// 此 ID 在裝置重裝 App 後仍保持不變
  static Future<String> getDeviceUdid() async {
    try {
      final udid = await FlutterUdid.udid;
      return normalizeUserId(udid);
    } catch (e) {
      // 若取得失敗（如 Web 平台不支援），生成 UUID v4
      return _uuid.v4();
    }
  }

  /// 將任意裝置識別字串正規化為合法 UUID
  static String normalizeUserId(String raw) {
    final value = raw.trim();
    if (isValidUuid(value)) {
      return value.toLowerCase();
    }
    // 將非 UUID 的裝置識別字串穩定映射為 UUID v5
    try {
      final v5 = _uuid.v5(Uuid.NAMESPACE_URL, value);
      if (isValidUuid(v5)) return v5;
    } catch (_) {
      // v5 生成失敗時降級為 v4
    }
    return _uuid.v4();
  }

  /// 取得使用者 ID（優先使用裝置 UDID，若已快取則直接回傳）
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_keyUserId);

    // 若無快取，從裝置 UDID 取得
    if (userId == null || userId.isEmpty) {
      userId = await getDeviceUdid();
      await prefs.setString(_keyUserId, userId);
    } else {
      // 相容舊版：若快取不是 UUID，立即遷移為合法 UUID
      userId = normalizeUserId(userId);
      await prefs.setString(_keyUserId, userId);
    }

    // 最終安全保障：確保無論任何情況都回傳合法 UUID
    if (!isValidUuid(userId)) {
      userId = _uuid.v4();
      await prefs.setString(_keyUserId, userId);
    }

    return userId;
  }

  /// 儲存設定
  static Future<void> saveConfig({
    required String url,
    required String anonKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = normalizeUrl(defaultUrl);
    await prefs.setString(_keyUrl, cleanUrl);
    await prefs.setString(_keyAnonKey, anonKey);
    await prefs.setBool(_keyIsConfigured, true);
    
    // 若無 userId，自動從裝置 UDID 取得
    if (prefs.getString(_keyUserId) == null) {
      final udid = await getDeviceUdid();
      await prefs.setString(_keyUserId, udid);
    }
  }

  /// 清除設定
  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyAnonKey);
    await prefs.remove(_keyUserId);
    await prefs.setBool(_keyIsConfigured, false);
  }

  /// 取得完整設定（用於顯示）
  static Future<Map<String, String>> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': normalizeUrl(defaultUrl),
      'anonKey': prefs.getString(_keyAnonKey) ?? defaultAnonKey,
      'userId': prefs.getString(_keyUserId) ?? '',
      'isConfigured': (prefs.getBool(_keyIsConfigured) ?? false).toString(),
    };
  }

  /// 檢查是否已有 Anon Key（已連線）
  static Future<bool> hasAnonKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyAnonKey);
    return key != null && key.isNotEmpty;
  }
}
