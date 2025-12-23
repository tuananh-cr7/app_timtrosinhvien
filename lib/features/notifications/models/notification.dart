import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model thông báo trong app.
class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.data, // Extra data (roomId, conversationId, etc.)
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? data; // Extra data

  /// Tạo từ Firestore document.
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.fromString(data['type'] ?? ''),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
    );
  }

  /// Chuyển thành JSON để lưu Firestore.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
    };
  }
}

/// Loại thông báo.
enum NotificationType {
  roomApproved, // Tin đăng được duyệt
  roomRejected, // Tin đăng bị từ chối
  roomPriceChanged, // Phòng yêu thích thay đổi giá
  newMessage, // Tin nhắn mới
  roomHidden, // Tin bị ẩn bởi admin
  reviewNew, // Có đánh giá mới cho phòng
  reviewRemoved, // Đánh giá bị gỡ
  roomMatched, // Tin mới phù hợp với tìm kiếm
  system, // Thông báo hệ thống

  unknown;

  String get value {
    switch (this) {
      case NotificationType.roomApproved:
        return 'room_approved';
      case NotificationType.roomRejected:
        return 'room_rejected';
      case NotificationType.roomPriceChanged:
        return 'room_price_changed';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.roomHidden:
        return 'room_hidden';
      case NotificationType.reviewNew:
        return 'review_new';
      case NotificationType.reviewRemoved:
        return 'review_removed';
      case NotificationType.roomMatched:
        return 'room_matched';
      case NotificationType.system:
        return 'system';
      case NotificationType.unknown:
        return 'unknown';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'room_approved':
        return NotificationType.roomApproved;
      case 'room_rejected':
        return NotificationType.roomRejected;
      case 'room_price_changed':
        return NotificationType.roomPriceChanged;
      case 'new_message':
        return NotificationType.newMessage;
      case 'room_hidden':
        return NotificationType.roomHidden;
      case 'review_new':
        return NotificationType.reviewNew;
      case 'review_removed':
        return NotificationType.reviewRemoved;
      case 'room_matched':
        return NotificationType.roomMatched;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.roomApproved:
        return 'Tin đăng được duyệt';
      case NotificationType.roomRejected:
        return 'Tin đăng bị từ chối';
      case NotificationType.roomPriceChanged:
        return 'Giá thay đổi';
      case NotificationType.newMessage:
        return 'Tin nhắn mới';
      case NotificationType.roomHidden:
        return 'Tin bị ẩn';
      case NotificationType.reviewNew:
        return 'Đánh giá mới';
      case NotificationType.reviewRemoved:
        return 'Đánh giá bị gỡ';
      case NotificationType.roomMatched:
        return 'Tin mới phù hợp';
      case NotificationType.system:
        return 'Thông báo hệ thống';
      case NotificationType.unknown:
        return 'Thông báo';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.roomApproved:
        return Icons.check_circle;
      case NotificationType.roomRejected:
        return Icons.cancel;
      case NotificationType.roomPriceChanged:
        return Icons.trending_down;
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.roomHidden:
        return Icons.visibility_off;
      case NotificationType.reviewNew:
        return Icons.reviews;
      case NotificationType.reviewRemoved:
        return Icons.delete_outline;
      case NotificationType.roomMatched:
        return Icons.home;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }
}

