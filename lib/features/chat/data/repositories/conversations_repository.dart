import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_result.dart';
import '../../models/conversation.dart';

/// Repository quản lý conversations và messages từ Firestore.
class ConversationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  /// Lấy danh sách conversations của user hiện tại.
  Future<ApiResult<List<Conversation>>> getConversations({
    int? limit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      Query query = _firestore
          .collection(_conversationsCollection)
          .where('participantIds', arrayContains: user.uid)
          .orderBy('lastMessageAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final conversations = snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList();

      return ApiSuccess(conversations);
    } catch (e) {
      return ApiError('Không thể tải danh sách cuộc trò chuyện: ${e.toString()}', e);
    }
  }

  /// Stream conversations real-time.
  Stream<List<Conversation>> getConversationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_conversationsCollection)
        .where('participantIds', arrayContains: user.uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .toList();
    });
  }

  /// Lấy chi tiết conversation.
  Future<ApiResult<Conversation?>> getConversationById(String conversationId) async {
    try {
      final doc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        return ApiSuccess(null);
      }

      return ApiSuccess(Conversation.fromFirestore(doc));
    } catch (e) {
      return ApiError('Không thể tải cuộc trò chuyện: ${e.toString()}', e);
    }
  }

  /// Lấy danh sách messages trong conversation.
  Future<ApiResult<List<Message>>> getMessages({
    required String conversationId,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();

      // Reverse để có thứ tự từ cũ đến mới
      final reversedMessages = messages.reversed.toList();

      return ApiSuccess(reversedMessages);
    } catch (e) {
      return ApiError('Không thể tải tin nhắn: ${e.toString()}', e);
    }
  }

  /// Stream messages real-time.
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesCollection)
        .orderBy('createdAt', descending: true)
        .limit(50) // Giới hạn 50 tin nhắn gần nhất
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
      // Reverse để có thứ tự từ cũ đến mới
      return messages.reversed.toList();
    });
  }

  /// Đánh dấu messages đã đọc.
  Future<ApiResult<void>> markMessagesAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      // Lấy tất cả messages chưa đọc của conversation này
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: user.uid) // Chỉ đánh dấu messages của người khác
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
      return ApiError('Không thể đánh dấu đã đọc: ${e.toString()}', e);
    }
  }
}

