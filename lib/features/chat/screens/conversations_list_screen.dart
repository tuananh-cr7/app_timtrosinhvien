import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../data/repositories/conversations_repository.dart';
import '../models/conversation.dart';
import 'conversation_detail_screen.dart';
import '../../../core/widgets/loading_error_widget.dart';

/// Màn hình danh sách cuộc trò chuyện.
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final _repository = ConversationsRepository();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  /// Lấy tên user từ users collection hoặc conversation
  Future<String> _getUserName(String? userId, String? currentName) async {
    // Nếu đã có tên và không phải "Người dùng", dùng luôn
    if (currentName != null && currentName.isNotEmpty && currentName != 'Người dùng') {
      return currentName;
    }
    
    // Nếu không có userId, trả về tên hiện tại
    if (userId == null || userId.isEmpty) {
      return currentName ?? 'Người dùng';
    }
    
    // Fetch từ users collection
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final name = userData?['displayName'] ?? 
                     userData?['name'] ?? 
                     userData?['email']?.split('@')[0];
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    } catch (e) {
      print('⚠️ Lỗi lấy tên user $userId: $e');
    }
    
    return currentName ?? 'Người dùng';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tin nhắn'),
        ),
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem tin nhắn'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _repository.getConversationsStream(),
        builder: (context, snapshot) {
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
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có cuộc trò chuyện nào',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            );
          }

          // Sắp xếp: pinned trước, sau đó theo lastMessageAt
          final sortedConversations = List<Conversation>.from(conversations)
            ..sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return b.lastMessageAt.compareTo(a.lastMessageAt);
            });

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedConversations.length,
              itemBuilder: (context, index) {
                final conversation = sortedConversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  currentUserId: user.uid,
                  onTap: (displayName, avatar, otherUserId) {
                    final finalOtherUserId = otherUserId?.isNotEmpty == true
                        ? otherUserId!
                        : (conversation.otherUserId ?? '');
                    // Mở conversation detail screen
                    // Stream sẽ tự động cập nhật khi unreadCount thay đổi trong Firestore
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConversationDetailScreen(
                          conversationId: conversation.id,
                          otherUserId: finalOtherUserId,
                          otherUserName:
                              displayName ?? conversation.otherUserName ?? 'Người dùng',
                          otherUserAvatar: avatar ?? conversation.otherUserAvatar,
                          roomId: conversation.roomId,
                          roomTitle: conversation.roomTitle,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  final Conversation conversation;
  final String currentUserId;
  final void Function(String?, String?, String?) onTap;

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  String? _displayName;
  String? _avatar;
  String? _resolvedOtherUserId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    // Xác định ID của người còn lại trong cuộc trò chuyện
    String? otherUserId = widget.conversation.otherUserId;
    bool forceFetch = false;

    // Nếu otherUserId đang trùng với currentUserId (do cuộc trò chuyện được tạo
    // từ phía bên kia) thì lấy ID còn lại trong participantIds
    if (otherUserId == null ||
        otherUserId.isEmpty ||
        otherUserId == widget.currentUserId) {
      forceFetch = true; // bắt buộc fetch lại tên/avatar của người còn lại
      if (widget.conversation.participantIds.length >= 2) {
        otherUserId = widget.conversation.participantIds
            .firstWhere(
              (id) => id != widget.currentUserId,
              orElse: () => otherUserId ?? '',
            );
      }
    }
    if (otherUserId == null || otherUserId.isEmpty) {
      setState(() {
        _displayName = widget.conversation.otherUserName ?? 'Người dùng';
        _avatar = widget.conversation.otherUserAvatar;
        _resolvedOtherUserId = null;
      });
      return;
    }
    _resolvedOtherUserId = otherUserId;

    // Nếu đã có tên hợp lệ và không phải tên của chính mình, dùng luôn
    // trừ khi forceFetch (tức otherUserId ban đầu trùng currentUser)
    final existingName = widget.conversation.otherUserName;
    final currentUserName = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        '';
    final existingLooksLikeSelf = existingName != null &&
        existingName.isNotEmpty &&
        currentUserName.isNotEmpty &&
        existingName.toLowerCase() == currentUserName.toLowerCase();
    if (!forceFetch &&
        existingName != null &&
        existingName.isNotEmpty &&
        existingName != 'Người dùng' &&
        !existingLooksLikeSelf) {
      setState(() {
        _displayName = existingName;
        _avatar = widget.conversation.otherUserAvatar;
        _resolvedOtherUserId = otherUserId;
      });
      return;
    }

    // Fetch từ users collection
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      
      if (userDoc.exists && mounted) {
        final userData = userDoc.data();
        final name = userData?['displayName'] ?? 
                     userData?['name'] ?? 
                     userData?['email']?.split('@')[0];
        // Thử nhiều field names cho avatar
        final avatar = userData?['photoURL'] ?? 
                       userData?['photoUrl'] ?? 
                       userData?['avatar'] ?? 
                       userData?['photo_url'];
        
        print('📸 [_ConversationTile] Fetch avatar cho $otherUserId:');
        print('  - photoURL: ${userData?['photoURL']}');
        print('  - photoUrl: ${userData?['photoUrl']}');
        print('  - avatar: ${userData?['avatar']}');
        print('  - photo_url: ${userData?['photo_url']}');
        print('  - final avatar: $avatar');
        print('  - conversation.otherUserAvatar: ${widget.conversation.otherUserAvatar}');
        
        setState(() {
          final currentUserName = FirebaseAuth.instance.currentUser?.displayName ??
              FirebaseAuth.instance.currentUser?.email?.split('@').first ??
              '';
          final sanitizedName = (name != null &&
                  currentUserName.isNotEmpty &&
                  name.toLowerCase() == currentUserName.toLowerCase())
              ? 'Người dùng'
              : name;
          _displayName = sanitizedName ?? widget.conversation.otherUserName ?? 'Người dùng';
          // Ưu tiên avatar mới fetch được
          _avatar = (avatar != null && avatar.isNotEmpty) 
              ? avatar 
              : widget.conversation.otherUserAvatar;
          _resolvedOtherUserId = otherUserId;
        });
        
        print('  - _avatar sau setState: $_avatar');
        
        // Cập nhật conversation với tên, avatar & otherUserId chuẩn nếu cần
        if (name != null && name.isNotEmpty && name != 'Người dùng') {
          final updateData = <String, dynamic>{
            'otherUserName': name,
          };
          if (avatar != null && avatar.isNotEmpty) {
            updateData['otherUserAvatar'] = avatar;
          }
          // Nếu otherUserId trong document đang sai (trùng currentUserId)
          // thì sửa lại thành ID của người còn lại
          if (widget.conversation.otherUserId == widget.currentUserId) {
            updateData['otherUserId'] = otherUserId;
          }
          
          await FirebaseFirestore.instance
              .collection('conversations')
              .doc(widget.conversation.id)
              .update(updateData);
          
          print('✅ Đã cập nhật conversation với tên: $name, avatar: $avatar');
        }
      } else if (mounted) {
        setState(() {
          _displayName = widget.conversation.otherUserName ?? 'Người dùng';
          _avatar = widget.conversation.otherUserAvatar;
          _resolvedOtherUserId = otherUserId;
        });
      }
    } catch (e) {
      print('⚠️ Lỗi lấy tên user ${otherUserId}: $e');
      if (mounted) {
        setState(() {
          _displayName = widget.conversation.otherUserName ?? 'Người dùng';
          _avatar = widget.conversation.otherUserAvatar;
          _resolvedOtherUserId = otherUserId;
        });
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = widget.conversation.unreadCount > 0;
    final currentUserName = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        '';
    // Ưu tiên otherUserId đã resolve; nếu trùng currentUser hoặc trống, tìm trong participantIds
    String? candidateOtherId = _resolvedOtherUserId ?? widget.conversation.otherUserId;
    if (candidateOtherId == null ||
        candidateOtherId.isEmpty ||
        candidateOtherId == widget.currentUserId) {
      candidateOtherId = widget.conversation.participantIds
          .firstWhere((id) => id != widget.currentUserId, orElse: () => '');
    }
    final isSelf = candidateOtherId == widget.currentUserId || candidateOtherId.isEmpty;
    String finalName =
        isSelf ? 'Người dùng' : (_displayName ?? widget.conversation.otherUserName ?? 'Người dùng');
    if (finalName.isNotEmpty &&
        currentUserName.isNotEmpty &&
        finalName.toLowerCase() == currentUserName.toLowerCase()) {
      finalName = 'Người dùng';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: _avatar != null && _avatar!.isNotEmpty
              ? NetworkImage(_avatar!)
              : null,
          onBackgroundImageError: (exception, stackTrace) {
            print('❌ Lỗi load avatar trong conversations list: $exception');
            print('  - Avatar URL: $_avatar');
            // Nếu load avatar thất bại, set về null để hiển thị chữ cái đầu
            if (mounted) {
              setState(() {
                _avatar = null;
              });
            }
          },
          child: _avatar == null || _avatar!.isEmpty
              ? Text(
                  (finalName.isNotEmpty ? finalName[0] : 'U').toUpperCase(),
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                finalName,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.conversation.isPinned)
              const Icon(Icons.push_pin, size: 16, color: Colors.orange),
            if (widget.conversation.isMuted)
              const Icon(Icons.volume_off, size: 16, color: Colors.grey),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                widget.conversation.lastMessage,
                style: TextStyle(
                  color: isUnread ? Colors.black87 : Colors.grey.shade600,
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(widget.conversation.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () => widget.onTap(_displayName, _avatar, candidateOtherId),
      ),
    );
  }
}

