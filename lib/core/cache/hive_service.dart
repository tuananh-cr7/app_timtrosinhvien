import 'package:hive_flutter/hive_flutter.dart';

/// Service quản lý Hive local cache.
class HiveService {
  static const String _roomsBoxName = 'rooms_cache';
  static const String _viewHistoryBoxName = 'view_history_cache';
  static const String _favoritesBoxName = 'favorites_cache';

  /// Khởi tạo Hive và mở các boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    // Mở các boxes
    await Hive.openBox(_roomsBoxName);
    await Hive.openBox(_viewHistoryBoxName);
    await Hive.openBox(_favoritesBoxName);
  }

  /// Lấy box cho rooms cache.
  static Box get roomsBox => Hive.box(_roomsBoxName);

  /// Lấy box cho view history cache.
  static Box get viewHistoryBox => Hive.box(_viewHistoryBoxName);

  /// Lấy box cho favorites cache.
  static Box get favoritesBox => Hive.box(_favoritesBoxName);

  /// Xóa toàn bộ cache.
  static Future<void> clearAll() async {
    await roomsBox.clear();
    await viewHistoryBox.clear();
    await favoritesBox.clear();
  }

  /// Xóa cache của một box cụ thể.
  static Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }
}

