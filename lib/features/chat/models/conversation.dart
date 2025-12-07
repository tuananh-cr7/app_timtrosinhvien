import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cuộc trò chuyện.
class Conversation {
  Conversation({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.roomId,
    this.roomTitle,
    this.roomThumbnail,
    this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  final String id;
  final List<String> participantIds; // [currentUserId, otherUserId]
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final String? roomId;
  final String? roomTitle;
  final String? roomThumbnail;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserAvatar;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  /// Tạo từ Firestore document.
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      roomId: data['roomId'],
      roomTitle: data['roomTitle'],
      roomThumbnail: data['roomThumbnail'],
      otherUserId: data['otherUserId'],
      otherUserName: data['otherUserName'],
      otherUserAvatar: data['otherUserAvatar'],
      unreadCount: data['unreadCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      isMuted: data['isMuted'] ?? false,
    );
  }
}

/// Model tin nhắn.
class Message {
  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.attachments,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final List<String>? attachments; // URLs của ảnh/file
  final MessageStatus status; // Trạng thái: sending, sent, delivered, read

  /// Tạo từ Firestore document.
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse createdAt từ Timestamp
    DateTime createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is DateTime) {
        createdAt = data['createdAt'] as DateTime;
      } else {
        // Fallback nếu không parse được
        createdAt = DateTime.now();
        print('⚠️ Message ${doc.id} có createdAt không hợp lệ: ${data['createdAt']}');
      }
    } else {
      // Nếu không có createdAt, dùng thời gian hiện tại
      createdAt = DateTime.now();
      print('⚠️ Message ${doc.id} không có createdAt');
    }
    
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.fromString(data['type'] ?? 'text'),
      createdAt: createdAt,
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      status: MessageStatus.fromString(data['status'] ?? 'sent'),
    );
  }
}

/// Trạng thái tin nhắn.
enum MessageStatus {
  sending, // Đang gửi
  sent, // Đã gửi
  delivered, // Đã gửi đến
  read, // Đã đọc
  failed; // Gửi thất bại

  static MessageStatus fromString(String value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  String get value {
    switch (this) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }
}

enum MessageType {
  text,
  image,
  file,
  location,
  unknown;

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.unknown;
    }
  }

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.location:
        return 'location';
      case MessageType.unknown:
        return 'unknown';
    }
  }
}

