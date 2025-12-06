import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_result.dart';
import '../../models/room.dart';
import 'rooms_repository.dart';

/// Repository quản lý lịch sử xem phòng từ Firestore.
class ViewHistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RoomsRepository _roomsRepository = RoomsRepository();
  static const String _collectionName = 'viewHistory';

  /// Ghi lại lịch sử xem phòng.
  Future<ApiResult<void>> logView(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      // Kiểm tra xem đã có chưa
      final existing = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('roomId', isEqualTo: roomId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Cập nhật thời gian xem
        await existing.docs.first.reference.update({
          'viewedAt': FieldValue.serverTimestamp(),
        });
        return ApiSuccess(null);
      }

      // Thêm mới
      await _firestore.collection(_collectionName).add({
        'userId': user.uid,
        'roomId': roomId,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể ghi lịch sử xem: ${e.toString()}', e);
    }
  }

  /// Lấy lịch sử xem phòng của user hiện tại.
  Future<ApiResult<List<ViewHistoryEntry>>> getHistory({int limit = 100}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .orderBy('viewedAt', descending: true)
          .limit(limit)
          .get();

      if (snapshot.docs.isEmpty) {
        return ApiSuccess([]);
      }

      // Lấy room IDs
      final historyDocs = snapshot.docs;
      final entries = <ViewHistoryEntry>[];

      for (final doc in historyDocs) {
        final data = doc.data();
        final roomId = data['roomId'] as String;
        final viewedAt = (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        // Lấy thông tin phòng
        final roomResult = await _roomsRepository.getRoomById(roomId);
        if (roomResult.isSuccess) {
          final room = switch (roomResult) {
            ApiSuccess<Room?>(data: final data) => data,
            _ => null,
          };
          if (room != null) {
            entries.add(ViewHistoryEntry(
              room: room,
              viewedAt: viewedAt,
            ));
          }
        }
      }

      return ApiSuccess(entries);
    } catch (e) {
      // Nếu lỗi orderBy, thử query không orderBy
      try {
        final user = _auth.currentUser;
        if (user == null) {
          return ApiError('Chưa đăng nhập');
        }

        final snapshot = await _firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: user.uid)
            .limit(limit)
            .get();

        final historyDocs = snapshot.docs;
        final entries = <ViewHistoryEntry>[];

        for (final doc in historyDocs) {
          final data = doc.data();
          final roomId = data['roomId'] as String;
          final viewedAt = (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

          final roomResult = await _roomsRepository.getRoomById(roomId);
          if (roomResult.isSuccess) {
            final room = switch (roomResult) {
              ApiSuccess<Room?>(data: final data) => data,
              _ => null,
            };
            if (room != null) {
              entries.add(ViewHistoryEntry(
                room: room,
                viewedAt: viewedAt,
              ));
            }
          }
        }

        // Sắp xếp theo thời gian xem (mới nhất trước)
        entries.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));

        return ApiSuccess(entries);
      } catch (e2) {
        return ApiError('Không thể tải lịch sử xem: ${e2.toString()}', e2);
      }
    }
  }

  /// Xóa tất cả lịch sử xem.
  Future<ApiResult<void>> clearHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        return ApiSuccess(null);
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể xóa lịch sử: ${e.toString()}', e);
    }
  }
}

/// Entry trong lịch sử xem.
class ViewHistoryEntry {
  ViewHistoryEntry({required this.room, required this.viewedAt});

  final Room room;
  final DateTime viewedAt;
}

