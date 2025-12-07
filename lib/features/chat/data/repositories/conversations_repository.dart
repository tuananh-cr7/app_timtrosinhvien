import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/models/api_result.dart';
import '../../models/conversation.dart';
import '../../../post/services/storage_service.dart';

/// Repository quản lý conversations và messages từ Firestore.
class ConversationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';
  static const String _chatImagesBucket = 'chat-images'; // Bucket cho ảnh chat
  static const String _chatFilesBucket = 'chat-files'; // Bucket cho file chat

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

      // Tính lại otherUserId và otherUserName cho mỗi conversation
      final conversations = <Conversation>[];
      for (final doc in snapshot.docs) {
        final conversation = await _enrichConversationWithOtherUser(
          Conversation.fromFirestore(doc),
          user.uid,
        );
        conversations.add(conversation);
      }

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
        .asyncMap((snapshot) async {
      // Tính lại otherUserId và otherUserName cho mỗi conversation
      final conversations = <Conversation>[];
      for (final doc in snapshot.docs) {
        final conversation = await _enrichConversationWithOtherUser(
          Conversation.fromFirestore(doc),
          user.uid,
        );
        conversations.add(conversation);
      }
      return conversations;
    });
  }
  
  /// Tính lại otherUserId và otherUserName dựa trên currentUser.
  Future<Conversation> _enrichConversationWithOtherUser(
    Conversation conversation,
    String currentUserId,
  ) async {
    // Tìm otherUserId (người không phải currentUser)
    String? otherUserId;
    for (final id in conversation.participantIds) {
      if (id != currentUserId) {
        otherUserId = id;
        break;
      }
    }
    
    // Nếu không tìm thấy otherUserId hoặc đã đúng, trả về conversation hiện tại
    if (otherUserId == null) {
      return conversation;
    }
    
    // Nếu otherUserId đã đúng, chỉ cần fetch lại tên nếu cần
    if (conversation.otherUserId == otherUserId) {
      // Nếu đã có tên và không phải "Người dùng", dùng luôn
      if (conversation.otherUserName != null &&
          conversation.otherUserName!.isNotEmpty &&
          conversation.otherUserName != 'Người dùng') {
        return conversation;
      }
    }
    
    // Fetch tên từ users collection
    String otherUserName = 'Người dùng';
    String? otherUserAvatar;
    try {
      print('🔍 [_enrichConversationWithOtherUser] Đang fetch user:');
      print('  - otherUserId: $otherUserId');
      print('  - currentUserId: $currentUserId');
      
      // Đảm bảo otherUserId không phải currentUserId
      if (otherUserId == currentUserId) {
        print('❌ LỖI: otherUserId trùng với currentUserId!');
        return conversation;
      }
      
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        otherUserName = userData?['displayName'] ?? 
                        userData?['name'] ?? 
                        userData?['email']?.split('@')[0] ?? 
                        'Người dùng';
        // Thử nhiều field names cho avatar
        otherUserAvatar = userData?['photoURL'] ?? 
                          userData?['photoUrl'] ?? 
                          userData?['avatar'] ?? 
                          userData?['photo_url'];
        
        print('✅ [_enrichConversationWithOtherUser] Tìm thấy:');
        print('  - otherUserName: $otherUserName');
        print('  - otherUserAvatar: $otherUserAvatar');
        print('  - photoURL: ${userData?['photoURL']}');
        print('  - photoUrl: ${userData?['photoUrl']}');
        print('  - avatar: ${userData?['avatar']}');
        print('  - photo_url: ${userData?['photo_url']}');
      } else {
        print('⚠️ [_enrichConversationWithOtherUser] Không tìm thấy user document với ID: $otherUserId');
      }
    } catch (e) {
      print('⚠️ Lỗi lấy tên user $otherUserId: $e');
    }
    
    // Tạo conversation mới với otherUserId và otherUserName đã được tính lại
    return Conversation(
      id: conversation.id,
      participantIds: conversation.participantIds,
      lastMessage: conversation.lastMessage,
      lastMessageAt: conversation.lastMessageAt,
      createdAt: conversation.createdAt,
      roomId: conversation.roomId,
      roomTitle: conversation.roomTitle,
      roomThumbnail: conversation.roomThumbnail,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
      unreadCount: conversation.unreadCount,
      isPinned: conversation.isPinned,
      isMuted: conversation.isMuted,
    );
  }

  /// Lấy chi tiết conversation.
  Future<ApiResult<Conversation?>> getConversationById(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final doc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        return ApiSuccess(null);
      }

      // Enrich conversation với otherUserId và otherUserName đúng
      final conversation = await _enrichConversationWithOtherUser(
        Conversation.fromFirestore(doc),
        user.uid,
      );

      return ApiSuccess(conversation);
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
        .orderBy('createdAt', descending: false) // Cũ nhất trước (ascending)
        .snapshots()
        .map((snapshot) {
      // Convert documents to Messages
      final messages = snapshot.docs
          .map((doc) {
            try {
              return Message.fromFirestore(doc);
            } catch (e) {
              print('⚠️ Lỗi parse message ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Message>()
          .toList();
      
      // Đảm bảo sort lại theo createdAt (phòng trường hợp real-time update không đúng thứ tự)
      // Sort ascending: cũ nhất trước, mới nhất sau
      // Dùng millisecondsSinceEpoch để đảm bảo sort chính xác
      messages.sort((a, b) {
        final aTime = a.createdAt.millisecondsSinceEpoch;
        final bTime = b.createdAt.millisecondsSinceEpoch;
        final compare = aTime.compareTo(bTime);
        if (compare != 0) return compare;
        // Nếu cùng thời gian (cùng millisecond), sort theo id để đảm bảo thứ tự nhất quán
        return a.id.compareTo(b.id);
      });
      
      // Lấy 50 tin nhắn gần nhất (từ cuối list)
      final recentMessages = messages.length > 50 
          ? messages.sublist(messages.length - 50)
          : messages;
      
      // Debug: In ra thứ tự messages để kiểm tra
      if (recentMessages.length > 1) {
        print('📨 Messages order (${recentMessages.length} messages) - SORTED ASCENDING:');
        for (int i = 0; i < recentMessages.length; i++) {
          final msg = recentMessages[i];
          final timeStr = '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}:${msg.createdAt.second.toString().padLeft(2, '0')}';
          print('  [$i] "${msg.content}" - $timeStr');
        }
      }
      
      // ListView với reverse: true sẽ hiển thị:
      // - Item đầu tiên trong list → ở dưới cùng (gần input)
      // - Item cuối cùng trong list → ở trên cùng (xa input)
      // 
      // Muốn hiển thị:
      // - Tin cũ nhất ở trên cùng → phải là item cuối cùng trong list
      // - Tin mới nhất ở dưới cùng → phải là item đầu tiên trong list
      // 
      // Vậy list cần: [mới nhất, ..., cũ nhất] (descending order)
      // Hiện tại messages đã sort ascending (cũ nhất trước), nên cần reverse
      final reversedMessages = recentMessages.reversed.toList();
      
      if (reversedMessages.length > 1) {
        print('📨 Messages order AFTER REVERSE (for ListView reverse:true):');
        print('  [0] "${reversedMessages.first.content}" - ${reversedMessages.first.createdAt.hour}:${reversedMessages.first.createdAt.minute.toString().padLeft(2, '0')} (MỚI NHẤT - sẽ hiển thị ở DƯỚI)');
        print('  [${reversedMessages.length - 1}] "${reversedMessages.last.content}" - ${reversedMessages.last.createdAt.hour}:${reversedMessages.last.createdAt.minute.toString().padLeft(2, '0')} (CŨ NHẤT - sẽ hiển thị ở TRÊN)');
      }
      
      return reversedMessages;
    });
  }

  /// Đánh dấu messages đã đọc.
  Future<ApiResult<void>> markMessagesAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      print('🔍 [markMessagesAsRead] Bắt đầu đánh dấu đã đọc cho conversation: $conversationId');
      print('   - Current user: ${user.uid}');

      // Lấy tất cả messages chưa đọc của conversation này (chỉ của người khác)
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: user.uid) // Chỉ đánh dấu messages của người khác
          .get();

      final unreadCount = snapshot.docs.length;
      print('   - Tìm thấy $unreadCount messages chưa đọc');
      
      final conversationRef = _firestore
          .collection(_conversationsCollection)
          .doc(conversationId);

      if (unreadCount == 0) {
        // Nếu không có messages chưa đọc, vẫn đảm bảo unreadCount = 0
        await conversationRef.update({
          'unreadCount': 0,
        });
        print('✅ Không có messages chưa đọc, đã đảm bảo unreadCount = 0');
        return ApiSuccess(null);
      }

      // Đánh dấu tất cả messages đã đọc
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Cập nhật unreadCount về 0
      batch.update(conversationRef, {
        'unreadCount': 0,
      });
      
      await batch.commit();
      
      print('✅ Đã đánh dấu $unreadCount messages đã đọc và cập nhật unreadCount = 0');
      print('   - Conversation ID: $conversationId');
      print('   - User ID: ${user.uid}');

      return ApiSuccess(null);
    } catch (e, stackTrace) {
      print('❌ Lỗi khi đánh dấu đã đọc: $e');
      print('❌ Stack trace: $stackTrace');
      return ApiError('Không thể đánh dấu đã đọc: ${e.toString()}', e);
    }
  }

  /// Tạo hoặc lấy conversation giữa 2 users.
  Future<ApiResult<Conversation>> createOrGetConversation({
    required String otherUserId,
    String? roomId,
    String? roomTitle,
    String? roomThumbnail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      // Kiểm tra xem đã có conversation chưa
      final existingQuery = await _firestore
          .collection(_conversationsCollection)
          .where('participantIds', arrayContains: user.uid)
          .get();

      for (final doc in existingQuery.docs) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        if (participantIds.contains(otherUserId) && participantIds.length == 2) {
          // Đã có conversation, cập nhật roomId và roomTitle nếu được cung cấp
          final updateData = <String, dynamic>{};
          if (roomId != null && (data['roomId'] == null || data['roomId'].toString().isEmpty)) {
            updateData['roomId'] = roomId;
          }
          if (roomTitle != null && (data['roomTitle'] == null || data['roomTitle'].toString().isEmpty)) {
            updateData['roomTitle'] = roomTitle;
          }
          if (roomThumbnail != null && (data['roomThumbnail'] == null || data['roomThumbnail'].toString().isEmpty)) {
            updateData['roomThumbnail'] = roomThumbnail;
          }
          
          if (updateData.isNotEmpty) {
            await doc.reference.update(updateData);
            print('✅ Đã cập nhật roomId/roomTitle cho conversation: ${doc.id}');
          }
          
          // Enrich conversation với otherUserId và otherUserAvatar đúng
          final conversation = await _enrichConversationWithOtherUser(
            Conversation.fromFirestore(doc),
            user.uid,
          );
          
          print('✅ Trả về conversation đã có với otherUserId: ${conversation.otherUserId}, otherUserAvatar: ${conversation.otherUserAvatar}');
          
          // Trả về conversation (đã được enrich)
          return ApiSuccess(conversation);
        }
      }

      // Chưa có, tạo mới
      // Lấy thông tin other user
      String otherUserName = 'Người dùng';
      String? otherUserAvatar;
      
      // Thử lấy từ users collection
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (otherUserDoc.exists) {
        final otherUserData = otherUserDoc.data();
        otherUserName = otherUserData?['displayName'] ?? 
                        otherUserData?['name'] ?? 
                        otherUserData?['email']?.split('@')[0] ?? 
                        'Người dùng';
        // Thử nhiều field names cho avatar
        otherUserAvatar = otherUserData?['photoURL'] ?? 
                          otherUserData?['photoUrl'] ?? 
                          otherUserData?['avatar'] ?? 
                          otherUserData?['photo_url'];
        
        print('✅ [createOrGetConversation] Tìm thấy otherUser:');
        print('   - otherUserId: $otherUserId');
        print('   - otherUserName: $otherUserName');
        print('   - otherUserAvatar: $otherUserAvatar');
      } else {
        // Nếu không có trong users collection, tạo user document cơ bản
        // Lấy email từ currentUser nếu otherUserId là currentUser (không nên xảy ra)
        // Hoặc tạo với thông tin tối thiểu
        try {
          // Tạo user document với thông tin cơ bản
          // Note: Không thể lấy email của user khác từ Firebase Auth
          // Nên chỉ tạo document với ID, sau đó user có thể cập nhật khi đăng nhập
          await _firestore.collection('users').doc(otherUserId).set({
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ Đã tạo user document cho $otherUserId');
        } catch (e) {
          print('⚠️ Không thể tạo user document: $e');
        }
      }
      
      print('👤 Other user name: $otherUserName (ID: $otherUserId)');

      final conversationRef = _firestore.collection(_conversationsCollection).doc();
      final conversation = Conversation(
        id: conversationRef.id,
        participantIds: [user.uid, otherUserId],
        lastMessage: '',
        lastMessageAt: DateTime.now(),
        createdAt: DateTime.now(),
        roomId: roomId,
        roomTitle: roomTitle,
        roomThumbnail: roomThumbnail,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserAvatar: otherUserAvatar,
      );

      await conversationRef.set({
        'participantIds': conversation.participantIds,
        'lastMessage': conversation.lastMessage,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'roomId': roomId,
        'roomTitle': roomTitle,
        'roomThumbnail': roomThumbnail,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserAvatar': otherUserAvatar,
        'unreadCount': 0,
        'isPinned': false,
        'isMuted': false,
      });

      return ApiSuccess(conversation);
    } catch (e) {
      return ApiError('Không thể tạo cuộc trò chuyện: ${e.toString()}', e);
    }
  }

  /// Gửi tin nhắn text.
  Future<ApiResult<Message>> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? attachmentUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final messageRef = _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesCollection)
          .doc();

      // Lưu message với serverTimestamp
      final now = DateTime.now();
      await messageRef.set({
        'conversationId': conversationId,
        'senderId': user.uid,
        'content': content,
        'type': type.value,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'attachments': attachmentUrls,
        'status': MessageStatus.sent.value,
      });

      // Tạo message object với thời gian client (sẽ được cập nhật khi real-time update)
      final message = Message(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: user.uid,
        content: content,
        type: type,
        createdAt: now, // Dùng client time tạm thời
        attachments: attachmentUrls,
        status: MessageStatus.sent,
      );

      // Cập nhật conversation
      final conversationRef = _firestore.collection(_conversationsCollection).doc(conversationId);
      await conversationRef.update({
        'lastMessage': content,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      // Tạo notification cho người nhận (tạm thời, vì Cloud Functions chưa deploy)
      try {
        print('📬 Bắt đầu tạo notification cho tin nhắn mới...');
        final conversationDoc = await conversationRef.get();
        
        if (!conversationDoc.exists) {
          print('⚠️ Conversation không tồn tại: $conversationId');
        } else {
          final conversationData = conversationDoc.data();
          final participantIds = List<String>.from(conversationData?['participantIds'] ?? []);
          
          print('👥 Participant IDs: $participantIds');
          print('👤 Sender ID: ${user.uid}');
          
          // Tìm người nhận (không phải người gửi)
          String? recipientId;
          for (final id in participantIds) {
            if (id != user.uid) {
              recipientId = id;
              break;
            }
          }

          if (recipientId == null || recipientId.isEmpty) {
            print('⚠️ Không tìm thấy recipient ID');
          } else {
            print('✅ Recipient ID: $recipientId');
            
            // Lấy thông tin sender
            String senderName = 'Người dùng';
            final senderDoc = await _firestore.collection('users').doc(user.uid).get();
            if (senderDoc.exists) {
              final senderData = senderDoc.data();
              senderName = senderData?['displayName'] ?? 
                          senderData?['name'] ?? 
                          senderData?['email']?.split('@')[0] ?? 
                          user.displayName ??
                          user.email?.split('@')[0] ??
                          'Người dùng';
            } else {
              // Nếu không có trong users collection, lấy từ Firebase Auth
              senderName = user.displayName ?? 
                          user.email?.split('@')[0] ?? 
                          'Người dùng';
            }
            
            print('👤 Sender name: $senderName (ID: ${user.uid})');

            // Lấy thông tin conversation
            final roomTitle = conversationData?['roomTitle'] ?? 'Phòng trọ';
            final roomId = conversationData?['roomId'];
            
            print('🏠 Room info từ conversation:');
            print('   - roomId: $roomId');
            print('   - roomTitle: $roomTitle');

            // Preview tin nhắn
            final messagePreview = content.length > 100 ? '${content.substring(0, 100)}...' : content;

            print('📝 Tạo notification với:');
            print('   - userId: $recipientId');
            print('   - title: $senderName');
            print('   - body: $messagePreview');
            print('   - roomId: $roomId');
            print('   - roomTitle: $roomTitle');

            // Tạo notification document
            final notificationRef = await _firestore.collection('notifications').add({
              'userId': recipientId,
              'type': 'new_message',
              'title': senderName,
              'body': messagePreview,
              'data': {
                'conversationId': conversationId,
                'senderId': user.uid,
                'senderName': senderName,
                'roomId': roomId,
                'roomTitle': roomTitle,
              },
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

            print('✅ Đã tạo notification: ${notificationRef.id}');
            print('📱 Notification sẽ hiển thị cho user: $recipientId');

            // Tính lại unreadCount dựa trên số messages chưa đọc thực tế
            // Chỉ đếm messages của người khác (không phải recipient tự gửi)
            final unreadMessagesSnapshot = await _firestore
                .collection(_conversationsCollection)
                .doc(conversationId)
                .collection(_messagesCollection)
                .where('isRead', isEqualTo: false)
                .where('senderId', isNotEqualTo: recipientId) // Chỉ đếm messages của người khác
                .get();
            
            final actualUnreadCount = unreadMessagesSnapshot.docs.length;
            
            // Cập nhật unreadCount với giá trị thực tế
            await conversationRef.update({
              'unreadCount': actualUnreadCount,
            });
            
            print('✅ Đã cập nhật unreadCount = $actualUnreadCount (dựa trên số messages chưa đọc thực tế)');
          }
        }
      } catch (e, stackTrace) {
        // In lỗi chi tiết để debug
        print('❌ Lỗi tạo notification: $e');
        print('❌ Stack trace: $stackTrace');
      }

      return ApiSuccess(message);
    } catch (e) {
      return ApiError('Không thể gửi tin nhắn: ${e.toString()}', e);
    }
  }

  /// Upload ảnh lên Supabase Storage (cho chat).
  Future<ApiResult<List<String>>> uploadChatImages(List<File> imageFiles) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      print('📸 [uploadChatImages] Bắt đầu upload ${imageFiles.length} ảnh');

      final urls = <String>[];
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        try {
          print('📸 [uploadChatImages] Đang upload ảnh ${i + 1}/${imageFiles.length}: ${file.path}');
          
          // Sử dụng StorageService với custom path cho chat
          final customPath = 'chat/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
          print('📸 [uploadChatImages] Custom path: $customPath');
          
          final url = await _storageService.uploadImage(
            file,
            customPath: customPath,
          );
          
          print('✅ [uploadChatImages] Upload thành công ảnh ${i + 1}: $url');
          urls.add(url);
        } catch (e, stackTrace) {
          print('❌ [uploadChatImages] Lỗi upload ảnh ${i + 1}: $e');
          print('❌ Stack trace: $stackTrace');
          // Nếu một ảnh lỗi, vẫn tiếp tục với ảnh khác
        }
      }

      if (urls.isEmpty) {
        print('❌ [uploadChatImages] Không upload được ảnh nào');
        return ApiError('Không thể upload ảnh. Vui lòng thử lại.');
      }

      if (urls.length < imageFiles.length) {
        print('⚠️ [uploadChatImages] Chỉ upload được ${urls.length}/${imageFiles.length} ảnh');
      }

      print('✅ [uploadChatImages] Upload thành công ${urls.length} ảnh');
      return ApiSuccess(urls);
    } catch (e, stackTrace) {
      print('❌ [uploadChatImages] Lỗi tổng quát: $e');
      print('❌ Stack trace: $stackTrace');
      return ApiError('Không thể upload ảnh: ${e.toString()}', e);
    }
  }

  /// Upload file lên Supabase Storage (cho chat).
  Future<ApiResult<String>> uploadChatFile(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      // Sử dụng StorageService với custom path cho file chat
      final url = await _storageService.uploadImage(
        file,
        customPath: 'chat/files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
      );

      return ApiSuccess(url);
    } catch (e) {
      return ApiError('Không thể upload file: ${e.toString()}', e);
    }
  }

  /// Mute/Unmute conversation.
  Future<ApiResult<void>> toggleMuteConversation(String conversationId, bool isMuted) async {
    try {
      await _firestore.collection(_conversationsCollection).doc(conversationId).update({
        'isMuted': isMuted,
      });
      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể ${isMuted ? 'tắt tiếng' : 'bật tiếng'}: ${e.toString()}', e);
    }
  }

  /// Pin/Unpin conversation.
  Future<ApiResult<void>> togglePinConversation(String conversationId, bool isPinned) async {
    try {
      await _firestore.collection(_conversationsCollection).doc(conversationId).update({
        'isPinned': isPinned,
      });
      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể ${isPinned ? 'ghim' : 'bỏ ghim'}: ${e.toString()}', e);
    }
  }

  /// Báo cáo user.
  Future<ApiResult<void>> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? conversationId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      await _firestore.collection('reports').add({
        'reporterId': user.uid,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'conversationId': conversationId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      });

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể báo cáo: ${e.toString()}', e);
    }
  }

  /// Block/Unblock user.
  Future<ApiResult<void>> toggleBlockUser(String userId, bool isBlocked) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return ApiError('Chưa đăng nhập');
      }

      final blockDoc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('blockedUsers')
          .doc(userId);

      if (isBlocked) {
        await blockDoc.set({
          'blockedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await blockDoc.delete();
      }

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể ${isBlocked ? 'chặn' : 'bỏ chặn'}: ${e.toString()}', e);
    }
  }

  /// Kiểm tra user có bị block không.
  Future<bool> isUserBlocked(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final blockDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return blockDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Thêm admin vào conversation (nếu user là admin).
  Future<ApiResult<void>> addAdminToConversation(String conversationId, String adminId) async {
    try {
      // Kiểm tra user có phải admin không (có thể check trong users collection)
      final userDoc = await _firestore.collection('users').doc(adminId).get();
      final isAdmin = userDoc.data()?['role'] == 'admin' || userDoc.data()?['isAdmin'] == true;

      if (!isAdmin) {
        return ApiError('Chỉ admin mới có thể tham gia');
      }

      // Thêm admin vào participantIds
      final conversationDoc = await _firestore.collection(_conversationsCollection).doc(conversationId).get();
      final participantIds = List<String>.from(conversationDoc.data()?['participantIds'] ?? []);

      if (!participantIds.contains(adminId)) {
        participantIds.add(adminId);
        await _firestore.collection(_conversationsCollection).doc(conversationId).update({
          'participantIds': participantIds,
        });
      }

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể thêm admin: ${e.toString()}', e);
    }
  }
}

