import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/config/supabase_config.dart';

void main() {
  group('SupabaseConfig UUID 驗證', () {
    test('isValidUuid 應能辨識合法 UUID', () {
      const value = '550e8400-e29b-41d4-a716-446655440000';
      expect(SupabaseConfig.isValidUuid(value), isTrue);
    });

    test('normalizeUserId 對非 UUID 應產生合法 UUID', () {
      const raw = 'e856b2e85ccb97ee';
      final normalized = SupabaseConfig.normalizeUserId(raw);

      expect(SupabaseConfig.isValidUuid(normalized), isTrue);
    });

    test('normalizeUserId 對同一輸入應穩定輸出相同 UUID', () {
      const raw = 'device-serial-123';
      final a = SupabaseConfig.normalizeUserId(raw);
      final b = SupabaseConfig.normalizeUserId(raw);

      expect(a, equals(b));
      expect(SupabaseConfig.isValidUuid(a), isTrue);
    });
  });
}
