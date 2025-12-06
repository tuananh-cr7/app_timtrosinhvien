import 'package:shared_preferences/shared_preferences.dart';

import 'data/mock_rooms.dart';
import 'models/room.dart';

const _kFavoriteRoomIdsKey = 'favorite_room_ids';

class FavoritesManager {
  FavoritesManager._();

  static Future<Set<String>> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavoriteRoomIdsKey) ?? <String>[];
    return list.toSet();
  }

  static Future<void> _saveIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFavoriteRoomIdsKey, ids.toList());
  }

  static Future<bool> isFavorite(String roomId) async {
    final ids = await _loadIds();
    return ids.contains(roomId);
  }

  static Future<bool> toggleFavorite(Room room) async {
    final ids = await _loadIds();
    if (ids.contains(room.id)) {
      ids.remove(room.id);
    } else {
      ids.add(room.id);
    }
    await _saveIds(ids);
    return ids.contains(room.id);
  }

  /// Lấy danh sách phòng yêu thích từ mock data hiện tại.
  /// Sau này sẽ thay bằng query Firestore.
  static Future<List<Room>> getFavoriteRooms() async {
    final ids = await _loadIds();
    final all = mockAllRooms;
    return all.where((r) => ids.contains(r.id)).toList();
  }
}


