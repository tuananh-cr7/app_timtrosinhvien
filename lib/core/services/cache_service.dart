import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../cache/hive_service.dart';

/// Service quản lý cache thông minh với invalidation strategy.
class CacheService {
  static const String _cacheBoxName = 'smart_cache';
  static const Duration _defaultExpiry = Duration(hours: 1);
  
  Box? _cacheBox;

  Future<void> _ensureBox() async {
    if (_cacheBox == null) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    }
  }

  /// Lưu data vào cache với key và expiry.
  Future<void> set<T>(String key, T data, {Duration? expiry}) async {
    await _ensureBox();
    
    final expiryDuration = expiry ?? _defaultExpiry;
    final expiresAt = DateTime.now().add(expiryDuration);
    
    final cacheEntry = {
      'data': _serialize(data),
      'expiresAt': expiresAt.toIso8601String(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    
    await _cacheBox!.put(key, jsonEncode(cacheEntry));
    print('💾 Đã cache: $key (expires: $expiresAt)');
  }

  /// Lấy data từ cache nếu còn hợp lệ.
  T? get<T>(String key) {
    if (_cacheBox == null) return null;
    
    final json = _cacheBox!.get(key) as String?;
    if (json == null) return null;
    
    try {
      final cacheEntry = jsonDecode(json) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(cacheEntry['expiresAt'] as String);
      
      if (DateTime.now().isAfter(expiresAt)) {
        // Cache đã hết hạn
        _cacheBox!.delete(key);
        print('⏰ Cache hết hạn: $key');
        return null;
      }
      
      print('✅ Đã lấy từ cache: $key');
      return _deserialize<T>(cacheEntry['data']);
    } catch (e) {
      print('⚠️ Lỗi đọc cache $key: $e');
      _cacheBox!.delete(key);
      return null;
    }
  }

  /// Xóa cache theo key.
  Future<void> invalidate(String key) async {
    await _ensureBox();
    await _cacheBox!.delete(key);
    print('🗑️ Đã invalidate cache: $key');
  }

  /// Xóa tất cả cache có pattern trong key.
  Future<void> invalidatePattern(String pattern) async {
    await _ensureBox();
    final keys = _cacheBox!.keys.where((k) => k.toString().contains(pattern)).toList();
    for (final key in keys) {
      await _cacheBox!.delete(key);
    }
    print('🗑️ Đã invalidate ${keys.length} cache với pattern: $pattern');
  }

  /// Xóa tất cả cache đã hết hạn.
  Future<void> clearExpired() async {
    await _ensureBox();
    final keys = _cacheBox!.keys.toList();
    int cleared = 0;
    
    for (final key in keys) {
      final json = _cacheBox!.get(key) as String?;
      if (json == null) continue;
      
      try {
        final cacheEntry = jsonDecode(json) as Map<String, dynamic>;
        final expiresAt = DateTime.parse(cacheEntry['expiresAt'] as String);
        
        if (DateTime.now().isAfter(expiresAt)) {
          await _cacheBox!.delete(key);
          cleared++;
        }
      } catch (e) {
        // Nếu lỗi parse, xóa luôn
        await _cacheBox!.delete(key);
        cleared++;
      }
    }
    
    if (cleared > 0) {
      print('🧹 Đã xóa $cleared cache đã hết hạn');
    }
  }

  /// Xóa toàn bộ cache.
  Future<void> clearAll() async {
    await _ensureBox();
    await _cacheBox!.clear();
    print('🗑️ Đã xóa toàn bộ cache');
  }

  dynamic _serialize<T>(T data) {
    if (data is List) {
      return data.map((e) => _serialize(e)).toList();
    } else if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), _serialize(v)));
    } else if (data is String || data is num || data is bool || data == null) {
      return data;
    } else {
      // Try to convert to JSON
      try {
        return jsonDecode(jsonEncode(data));
      } catch (e) {
        return data.toString();
      }
    }
  }

  T? _deserialize<T>(dynamic data) {
    return data as T?;
  }
}

/// Cache keys constants.
class CacheKeys {
  static String roomsList({int? limit}) => 'rooms_list${limit != null ? "_$limit" : ""}';
  static String roomDetail(String roomId) => 'room_detail_$roomId';
  static String searchResults(String query) => 'search_results_$query';
  static String favorites(String userId) => 'favorites_$userId';
  static String viewHistory(String userId) => 'view_history_$userId';
  static String postedRooms(String userId, String status) => 'posted_rooms_${userId}_$status';
}

