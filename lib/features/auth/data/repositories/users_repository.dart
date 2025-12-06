import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_result.dart';

/// Repository quản lý dữ liệu user từ Firestore.
class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'users';

  /// Lấy thông tin user hiện tại.
  Future<ApiResult<Map<String, dynamic>?>> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final doc = await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return ApiSuccess(null);
      }

      return ApiSuccess(doc.data());
    } catch (e) {
      return ApiError('Không thể tải thông tin user: ${e.toString()}', e);
    }
  }

  /// Cập nhật thông tin user.
  Future<ApiResult<void>> updateUser(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      await _firestore
          .collection(_collectionName)
          .doc(user.uid)
          .set(
            {
              ...data,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể cập nhật thông tin: ${e.toString()}', e);
    }
  }

  /// Tạo user document khi đăng ký.
  Future<ApiResult<void>> createUser({
    required String userId,
    required String email,
    String? displayName,
    String? phone,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).set({
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể tạo user: ${e.toString()}', e);
    }
  }
}

