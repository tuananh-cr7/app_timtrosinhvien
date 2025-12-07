import 'package:flutter/material.dart';
import '../../features/home/room_detail_screen.dart';
import '../../features/home/data/repositories/rooms_repository.dart';
import '../../features/home/models/room.dart';
import '../../features/post/screens/posted_rooms_management_screen.dart';
import '../../features/chat/screens/conversation_detail_screen.dart';
import '../../features/chat/data/repositories/conversations_repository.dart';
import '../../features/chat/models/conversation.dart';
import '../../core/models/api_result.dart';

/// Service xử lý navigation khi user tap vào notification
class NotificationNavigationService {
  static final NotificationNavigationService _instance = NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  final GlobalKey<NavigatorState>? _navigatorKey = GlobalKey<NavigatorState>();

  /// Set navigator key (gọi từ main.dart)
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    // Note: Không thể set lại key, chỉ dùng để reference
  }

  /// Xử lý khi user tap vào notification
  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) {
      print('⚠️ NotificationNavigation: No type in data');
      return;
    }

    print('🧭 NotificationNavigation: Handling type: $type');

    // Lấy navigator context từ root
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      print('⚠️ NotificationNavigation: No navigator context available');
      // Lưu data để xử lý sau khi app khởi động xong
      _pendingNotification = data;
      return;
    }

    _navigateToScreen(context, type, data);
  }

  Map<String, dynamic>? _pendingNotification;

  /// Xử lý notification đang chờ (khi app chưa khởi động xong)
  void handlePendingNotification(BuildContext context) {
    if (_pendingNotification != null) {
      final data = _pendingNotification!;
      _pendingNotification = null;
      final type = data['type'] as String?;
      if (type != null) {
        _navigateToScreen(context, type, data);
      }
    }
  }

  /// Navigate đến màn hình tương ứng
  void _navigateToScreen(BuildContext context, String type, Map<String, dynamic> data) {
    switch (type) {
      case 'new_message':
        _handleNewMessage(context, data);
        break;
      case 'room_approved':
      case 'room_rejected':
        _handleRoomStatus(context, data);
        break;
      case 'room_price_changed':
      case 'room_matched':
        _handleRoomNotification(context, data);
        break;
      default:
        print('⚠️ NotificationNavigation: Unknown type: $type');
    }
  }

  /// Xử lý notification tin nhắn mới
  Future<void> _handleNewMessage(BuildContext context, Map<String, dynamic> data) async {
    final conversationId = data['conversationId'] as String?;
    final roomId = data['roomId'] as String?;
    final roomTitle = data['roomTitle'] as String?;
    final senderId = data['senderId'] as String?;
    final senderName = data['senderName'] as String?;

    if (conversationId != null) {
      // Lấy thông tin conversation
      final repository = ConversationsRepository();
      final result = await repository.getConversationById(conversationId);

      if (result is ApiSuccess<Conversation?>) {
        final conversation = result.data;
        if (conversation != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationDetailScreen(
                conversationId: conversationId,
                otherUserId: conversation.otherUserId ?? senderId ?? '',
                otherUserName: conversation.otherUserName ?? senderName ?? 'Người dùng',
                otherUserAvatar: conversation.otherUserAvatar,
                roomId: conversation.roomId ?? roomId,
                roomTitle: conversation.roomTitle ?? roomTitle,
              ),
            ),
          );
          return;
        }
      }

      // Nếu không lấy được conversation, dùng data từ notification
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(
              conversationId: conversationId,
              otherUserId: senderId ?? '',
              otherUserName: senderName ?? 'Người dùng',
              roomId: roomId,
              roomTitle: roomTitle,
            ),
          ),
        );
      }
    } else if (roomId != null) {
      // Nếu không có conversationId, mở room detail
      _openRoomDetail(context, roomId);
    } else {
      print('⚠️ NotificationNavigation: No conversationId or roomId for new_message');
    }
  }

  /// Xử lý notification tin đăng được duyệt/từ chối
  void _handleRoomStatus(BuildContext context, Map<String, dynamic> data) {
    final roomId = data['roomId'] as String?;
    final type = data['type'] as String;

    // Mở màn hình quản lý tin đã đăng
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostedRoomsManagementScreen(),
      ),
    );
    // TODO: Thêm logic để tự động chuyển đến tab tương ứng khi PostedRoomsManagementScreen hỗ trợ
  }

  /// Xử lý notification về phòng trọ (giá thay đổi, tin mới phù hợp)
  void _handleRoomNotification(BuildContext context, Map<String, dynamic> data) {
    final roomId = data['roomId'] as String?;
    if (roomId != null) {
      _openRoomDetail(context, roomId);
    } else {
      print('⚠️ NotificationNavigation: No roomId for room notification');
    }
  }

  /// Mở màn hình chi tiết phòng trọ
  Future<void> _openRoomDetail(BuildContext context, String roomId) async {
    final repository = RoomsRepository();
    final result = await repository.getRoomById(roomId);

    switch (result) {
      case ApiSuccess<Room?>(:final data):
        if (data != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomDetailScreen(room: data),
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy thông tin phòng'),
            ),
          );
        }
        break;
      case ApiError<Room?>(:final message):
        print('❌ NotificationNavigation: Error loading room: $message');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải thông tin phòng: $message'),
            ),
          );
        }
        break;
      case ApiLoading<Room?>():
        // Đang loading, không làm gì
        break;
    }
  }
}

