import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_udid/flutter_udid.dart';

/// Supabase 設定管理器
/// 使用 SharedPreferences 儲存使用者的 Supabase 連線設定
class SupabaseConfig {
  /// 預設 Supabase URL（Demo 用）
  static const String defaultUrl = 'https://omareqsfkeqslywwvkyg.supabase.co';

  static const String _keyUrl = 'supabase_url';
  static const String _keyAnonKey = 'supabase_anon_key';
  static const String _keyUserId = 'supabase_user_id';
  static const String _keyIsConfigured = 'supabase_is_configured';

  /// 檢查是否已完成設定
  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsConfigured) ?? false;
  }

  /// 取得 Supabase URL（若無則回傳預設值）
  static Future<String> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUrl) ?? defaultUrl;
  }

  /// 取得 Supabase Anon Key
  static Future<String?> getAnonKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAnonKey);
  }

  /// 取得裝置唯一 ID（使用 flutter_udid）
  /// 此 ID 在裝置重裝 App 後仍保持不變
  static Future<String> getDeviceUdid() async {
    try {
      final udid = await FlutterUdid.udid;
      return udid;
    } catch (e) {
      // 若取得失敗（如 Web 平台不支援），生成一個真正的 UUID v4
      final bytes = List<int>.generate(16, (i) => DateTime.now().microsecond);
      bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
      bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant 1
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
    }
  }

  /// 取得使用者 ID（優先使用裝置 UDID，若已快取則直接回傳）
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_keyUserId);
    
    // 若無快取，從裝置 UDID 取得
    if (userId == null || userId.isEmpty) {
      userId = await getDeviceUdid();
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
    await prefs.setString(_keyUrl, url);
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
      'url': prefs.getString(_keyUrl) ?? defaultUrl,
      'anonKey': prefs.getString(_keyAnonKey) ?? '',
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
