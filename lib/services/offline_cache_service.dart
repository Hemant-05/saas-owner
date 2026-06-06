import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheEntry {
  final Object? value;
  final DateTime savedAt;

  const OfflineCacheEntry({
    required this.value,
    required this.savedAt,
  });
}

class OfflineCacheService {
  OfflineCacheService._();

  static const String _prefix = 'offline_cache_';

  static Future<void> writeJson(String key, Object? value) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'savedAt': DateTime.now().toIso8601String(),
      'value': value,
    };
    await prefs.setString('$_prefix$key', jsonEncode(payload));
  }

  static Future<OfflineCacheEntry?> readEntry(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final savedAt = DateTime.tryParse('${decoded['savedAt']}');
      if (savedAt == null) return null;
      return OfflineCacheEntry(value: decoded['value'], savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> readJsonMap(String key) async {
    final entry = await readEntry(key);
    final value = entry?.value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Future<List<dynamic>?> readJsonList(String key) async {
    final entry = await readEntry(key);
    final value = entry?.value;
    if (value is List) return value;
    return null;
  }

  static Future<DateTime?> savedAt(String key) async {
    return (await readEntry(key))?.savedAt;
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}
