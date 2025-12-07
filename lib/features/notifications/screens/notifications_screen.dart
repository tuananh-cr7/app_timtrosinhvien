import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/notifications_repository.dart';
import '../models/notification.dart';
import '../../home/room_detail_screen.dart';
import '../../home/data/repositories/rooms_repository.dart';
import '../../home/models/room.dart';
import '../../chat/screens/conversation_detail_screen.dart';
import '../../chat/data/repositories/conversations_repository.dart';
import '../../chat/models/conversation.dart';
import '../../../core/models/api_result.dart';
import '../../../core/widgets/loading_error_widget.dart';

/// Màn hình thông báo trong app.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationsRepository = NotificationsRepository();
  final _roomsRepository = RoomsRepository();
  final _conversationsRepository = ConversationsRepository();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thông báo'),
        ),
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem thông báo'),
        ),
      );
    }

    // Debug: In UID ra console
    print('🔍 DEBUG: User UID hiện tại: ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          StreamBuilder<int>(
            stream: _notificationsRepository.getUnreadCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '$unreadCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                final result = await _notificationsRepository.markAllAsRead();
                if (mounted) {
                  if (result is ApiError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${result.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu tất cả đã đọc'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } else if (value == 'delete_read') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa thông báo đã đọc'),
                    content: const Text(
                      'Bạn có chắc chắn muốn xóa tất cả thông báo đã đọc?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final result =
                      await _notificationsRepository.deleteAllRead();
                  if (mounted) {
                    if (result is ApiError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: ${result.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa thông báo đã đọc'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: 8),
                    Text('Đánh dấu tất cả đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Xóa thông báo đã đọc'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationsRepository.getNotificationsStream(),
        builder: (context, snapshot) {
          // Debug log
          if (snapshot.hasError) {
            print('❌ NotificationsScreen Stream Error: ${snapshot.error}');
            if (snapshot.stackTrace != null) {
              print('❌ Error details: ${snapshot.stackTrace}');
            }
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.error.toString().contains('index'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Cần tạo Firestore index. Xem console log để biết link tạo index.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          print('📱 NotificationsScreen: Displaying ${notifications.length} notifications');

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Debug info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🔍 Debug Info',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User ID: ${user.uid}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade800,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tạo notification trong Firestore với userId = User ID ở trên',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDelete: () => _deleteNotification(notification.id),
                  onMarkRead: notification.isRead
                      ? null
                      : () => _markAsRead(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Đánh dấu đã đọc
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    // Navigate dựa trên type
    switch (notification.type) {
      case NotificationType.roomApproved:
      case NotificationType.roomRejected:
      case NotificationType.roomPriceChanged:
      case NotificationType.roomMatched:
        // Navigate đến room detail nếu có roomId
        if (notification.data != null &&
            notification.data!['roomId'] != null) {
          final roomId = notification.data!['roomId'] as String;
          final result = await _roomsRepository.getRoomById(roomId);
          if (result is ApiSuccess<Room?> && result.data != null) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RoomDetailScreen(room: result.data!),
                ),
              );
            }
          }
        }
        break;
      case NotificationType.newMessage:
        // Navigate đến ConversationDetailScreen
        if (notification.data != null) {
          final conversationId = notification.data!['conversationId'] as String?;
          final senderId = notification.data!['senderId'] as String?;
          final senderName = notification.data!['senderName'] as String?;
          final roomId = notification.data!['roomId'] as String?;
          final roomTitle = notification.data!['roomTitle'] as String?;

          if (conversationId != null) {
            // Lấy thông tin conversation
            final result = await _conversationsRepository.getConversationById(conversationId);
            
            if (result is ApiSuccess<Conversation?>) {
              final conversation = result.data;
              if (conversation != null && mounted) {
                // Conversation đã được enrich với otherUserId và otherUserName đúng
                // Đảm bảo otherUserId không null và không trùng với currentUserId
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final finalOtherUserId = conversation.otherUserId;
                
                if (finalOtherUserId == null || finalOtherUserId.isEmpty) {
                  print('❌ Conversation không có otherUserId hợp lệ');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
                  );
                  return;
                }
                
                if (finalOtherUserId == currentUserId) {
                  print('❌ otherUserId trùng với currentUserId: $finalOtherUserId');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi: Không thể xác định người đối thoại')),
                  );
                  return;
                }
                
                print('✅ Mở chat với:');
                print('  - conversationId: $conversationId');
                print('  - otherUserId: $finalOtherUserId');
                print('  - otherUserName: ${conversation.otherUserName}');
                print('  - otherUserAvatar: ${conversation.otherUserAvatar}');
                print('  - currentUserId: $currentUserId');
                
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConversationDetailScreen(
                      conversationId: conversationId,
                      otherUserId: finalOtherUserId,
                      otherUserName: conversation.otherUserName ?? 'Người dùng',
                      otherUserAvatar: conversation.otherUserAvatar,
                      roomId: conversation.roomId ?? roomId,
                      roomTitle: conversation.roomTitle ?? roomTitle,
                    ),
                  ),
                );
              } else if (mounted) {
                // Nếu không lấy được conversation, không mở (vì không có otherUserId đúng)
                print('❌ Không lấy được conversation với ID: $conversationId');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
                );
              }
            } else if (mounted) {
              // Nếu không lấy được conversation, không mở (vì không có otherUserId đúng)
              print('❌ Lỗi lấy conversation: ${(result as ApiError).message}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy thông tin cuộc trò chuyện')),
            );
          }
        }
        break;
      default:
        break;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final result = await _notificationsRepository.markAsRead(notificationId);
    if (mounted && result is ApiError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final result = await _notificationsRepository.deleteNotification(notificationId);
    if (mounted) {
      if (result is ApiError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
    this.onMarkRead,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      // Format thủ công: dd/MM/yyyy
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      return '$day/$month/$year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.type.icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatTime(notification.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (onMarkRead != null)
                          Flexible(
                            child: TextButton(
                              onPressed: onMarkRead,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Đánh dấu đã đọc',
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: onDelete,
                          tooltip: 'Xóa',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

