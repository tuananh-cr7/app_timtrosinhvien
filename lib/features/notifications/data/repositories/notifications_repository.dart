import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_result.dart';
import '../../models/notification.dart';

/// Repository quản lý thông báo từ Firestore.
class NotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'notifications';

  /// Lấy danh sách thông báo của user hiện tại.
  Future<ApiResult<List<AppNotification>>> getNotifications({
    int? limit,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      query = query.orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();

      return ApiSuccess(notifications);
    } catch (e) {
      return ApiError('Không thể tải thông báo: ${e.toString()}', e);
    }
  }

  /// Stream thông báo real-time.
  Stream<List<AppNotification>> getNotificationsStream({
    bool unreadOnly = false,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query query = _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: user.uid);

    if (unreadOnly) {
      query = query.where('isRead', isEqualTo: false);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Đếm số thông báo chưa đọc.
  Future<ApiResult<int>> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiSuccess(0);
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return ApiSuccess(snapshot.docs.length);
    } catch (e) {
      return ApiError('Không thể đếm thông báo: ${e.toString()}', e);
    }
  }

  /// Stream số thông báo chưa đọc real-time.
  Stream<int> getUnreadCountStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Đánh dấu thông báo đã đọc.
  Future<ApiResult<void>> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      await _firestore.collection(_collectionName).doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể đánh dấu đã đọc: ${e.toString()}', e);
    }
  }

  /// Đánh dấu tất cả thông báo đã đọc.
  Future<ApiResult<void>> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return ApiSuccess(null);
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể đánh dấu tất cả đã đọc: ${e.toString()}', e);
    }
  }

  /// Xóa thông báo.
  Future<ApiResult<void>> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      await _firestore.collection(_collectionName).doc(notificationId).delete();

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể xóa thông báo: ${e.toString()}', e);
    }
  }

  /// Xóa tất cả thông báo đã đọc.
  Future<ApiResult<void>> deleteAllRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: true)
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
      return ApiError('Không thể xóa thông báo: ${e.toString()}', e);
    }
  }
}

