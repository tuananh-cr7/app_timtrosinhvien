import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_result.dart';
import '../../models/room.dart';
import 'rooms_repository.dart';

/// Repository quản lý favorites từ Firestore và local cache.
class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RoomsRepository _roomsRepository = RoomsRepository();
  static const String _collectionName = 'favorites';

  /// Lấy danh sách phòng yêu thích của user hiện tại.
  Future<ApiResult<List<Room>>> getFavoriteRooms() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return ApiSuccess([]);
      }

      // Lấy room IDs
      final roomIds = snapshot.docs
          .map((doc) => doc.data()['roomId'] as String)
          .toList();

      // Lấy thông tin các phòng
      final rooms = <Room>[];
      for (final roomId in roomIds) {
        final result = await _roomsRepository.getRoomById(roomId);
        if (result.isSuccess && result.dataOrNull != null) {
          rooms.add(result.dataOrNull!);
        }
      }

      return ApiSuccess(rooms);
    } catch (e) {
      return ApiError('Không thể tải danh sách yêu thích: ${e.toString()}', e);
    }
  }

  /// Thêm phòng vào yêu thích.
  Future<ApiResult<void>> addFavorite(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      // Kiểm tra đã có chưa
      final existing = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('roomId', isEqualTo: roomId)
          .get();

      if (existing.docs.isNotEmpty) {
        return ApiSuccess(null); // Đã có rồi
      }

      // Thêm mới
      final docRef = await _firestore.collection(_collectionName).add({
        'userId': user.uid,
        'roomId': roomId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Đã thêm favorite: docId=${docRef.id}, userId=${user.uid}, roomId=$roomId');

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể thêm vào yêu thích: ${e.toString()}', e);
    }
  }

  /// Xóa phòng khỏi yêu thích.
  Future<ApiResult<void>> removeFavorite(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('roomId', isEqualTo: roomId)
          .get();

      if (snapshot.docs.isEmpty) {
        return ApiSuccess(null); // Không có để xóa
      }

      // Xóa tất cả documents (nếu có duplicate)
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể xóa khỏi yêu thích: ${e.toString()}', e);
    }
  }

  /// Kiểm tra phòng có trong yêu thích không.
  Future<ApiResult<bool>> isFavorite(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiSuccess(false);
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('roomId', isEqualTo: roomId)
          .limit(1)
          .get();

      return ApiSuccess(snapshot.docs.isNotEmpty);
    } catch (e) {
      return ApiError('Không thể kiểm tra yêu thích: ${e.toString()}', e);
    }
  }
}

