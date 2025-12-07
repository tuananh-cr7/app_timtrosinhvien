import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/repositories/conversations_repository.dart';
import '../models/conversation.dart';
import '../../../core/models/api_result.dart';
import '../../../core/widgets/loading_error_widget.dart';

/// Màn hình chat chi tiết.
class ConversationDetailScreen extends StatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.roomId,
    this.roomTitle,
  });

  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? roomId;
  final String? roomTitle;

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  final _repository = ConversationsRepository();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isSending = false;
  
  String? _displayName;
  String? _displayAvatar;

  @override
  void initState() {
    super.initState();
    // Khởi tạo với giá trị từ widget (sẽ được cập nhật sau khi fetch)
    _displayName = widget.otherUserName;
    _displayAvatar = widget.otherUserAvatar;
    
    print('🔍 [ConversationDetailScreen] initState:');
    print('   - widget.otherUserId: ${widget.otherUserId}');
    print('   - widget.otherUserName: ${widget.otherUserName}');
    print('   - widget.otherUserAvatar: ${widget.otherUserAvatar}');
    print('   - _displayAvatar (initial): $_displayAvatar');
    
    // Đánh dấu messages đã đọc khi mở màn hình (await để đảm bảo hoàn thành)
    _markMessagesAsRead();
    
    // Load user info (fetch lại từ users collection) - gọi ngay để cập nhật avatar
    _loadUserInfo();
    
    // Listen for new messages và tạo notification nếu cần
    _setupMessageListener();
  }
  
  Future<void> _markMessagesAsRead() async {
    try {
      print('🔍 [ConversationDetailScreen] Bắt đầu đánh dấu messages đã đọc...');
      print('   - Conversation ID: ${widget.conversationId}');
      
      final result = await _repository.markMessagesAsRead(widget.conversationId);
      
      if (result is ApiError) {
        print('⚠️ [ConversationDetailScreen] Lỗi đánh dấu đã đọc: ${result.message}');
      } else {
        print('✅ [ConversationDetailScreen] Đã đánh dấu messages đã đọc thành công');
        print('   - Stream sẽ tự động cập nhật unreadCount = 0');
      }
    } catch (e, stackTrace) {
      print('❌ [ConversationDetailScreen] Lỗi khi đánh dấu đã đọc: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> _loadUserInfo() async {
    final otherUserId = widget.otherUserId;
    if (otherUserId.isEmpty) {
      setState(() {
        _displayName = widget.otherUserName;
        _displayAvatar = widget.otherUserAvatar;
      });
      return;
    }

    // Luôn fetch lại từ users collection để đảm bảo tên đúng
    try {
      final currentUserId = _auth.currentUser?.uid;
      print('🔍 Đang fetch tên user:');
      print('  - otherUserId: $otherUserId');
      print('  - currentUserId: $currentUserId');
      print('  - widget.otherUserName: ${widget.otherUserName}');
      print('  - widget.otherUserAvatar: ${widget.otherUserAvatar}');
      
      // Đảm bảo otherUserId không phải currentUserId
      if (otherUserId == currentUserId) {
        print('❌ LỖI: otherUserId trùng với currentUserId! Đang lấy avatar của chính mình.');
        setState(() {
          _displayName = widget.otherUserName;
          _displayAvatar = widget.otherUserAvatar;
        });
        return;
      }
      
      String? name;
      String? avatar;
      
      // Thử lấy từ users collection trước
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        name = userData?['displayName'] ?? 
               userData?['name'] ?? 
               userData?['email']?.split('@')[0];
        // Thử nhiều field names cho avatar
        avatar = userData?['photoURL'] ?? 
                 userData?['photoUrl'] ?? 
                 userData?['avatar'] ?? 
                 userData?['photo_url'];
        
        print('✅ Tìm thấy trong users collection:');
        print('  - name: $name');
        print('  - avatar: $avatar');
        print('  - displayName: ${userData?['displayName']}');
        print('  - name field: ${userData?['name']}');
        print('  - email: ${userData?['email']}');
        print('  - photoURL: ${userData?['photoURL']}');
        print('  - photoUrl: ${userData?['photoUrl']}');
        print('  - avatar field: ${userData?['avatar']}');
        print('  - photo_url: ${userData?['photo_url']}');
      } else {
        print('⚠️ Không tìm thấy user document với ID: $otherUserId');
      }
      
      // Nếu không tìm thấy avatar trong users collection, thử lấy từ Firebase Auth
      if (avatar == null || avatar.isEmpty) {
        try {
          // Lấy user từ Firebase Auth (chỉ có thể lấy currentUser, không thể lấy user khác)
          // Nên chúng ta sẽ bỏ qua bước này và chỉ dùng users collection
          print('⚠️ Avatar không có trong users collection, không thể lấy từ Auth (chỉ có thể lấy currentUser)');
        } catch (e) {
          print('⚠️ Lỗi khi thử lấy avatar từ Auth: $e');
        }
      }
      
      // Nếu không tìm thấy trong users collection, thử lấy từ Firebase Auth
      if ((name == null || name.isEmpty || name == 'Người dùng') && mounted) {
        try {
          // Lấy tất cả users hiện tại để tìm user với ID này
          // Note: Firebase Auth không cho phép query user by ID trực tiếp từ client
          // Nên chúng ta sẽ dùng cách khác: lưu user info vào users collection khi đăng nhập
          print('⚠️ Không tìm thấy trong users collection, cần lưu user info khi đăng nhập');
        } catch (e) {
          print('⚠️ Lỗi khi thử lấy từ Auth: $e');
        }
      }
      
      // Nếu vẫn không có tên, dùng email từ otherUserId (nếu có thể)
      if ((name == null || name.isEmpty || name == 'Người dùng') && mounted) {
        // Thử tạo tên từ ID (fallback cuối cùng)
        name = widget.otherUserName;
        if (name == 'Người dùng' || name.isEmpty) {
          // Nếu vẫn là "Người dùng", thử lấy từ conversation document
          try {
            final convDoc = await _firestore.collection('conversations').doc(widget.conversationId).get();
            if (convDoc.exists) {
              final convData = convDoc.data();
              final convName = convData?['otherUserName'];
              if (convName != null && convName.isNotEmpty && convName != 'Người dùng') {
                name = convName;
                print('✅ Lấy tên từ conversation document: $name');
              }
            }
          } catch (e) {
            print('⚠️ Lỗi lấy từ conversation: $e');
          }
        }
      }
      
      // Cập nhật UI - luôn cập nhật avatar nếu có
      if (mounted) {
        // Ưu tiên avatar mới fetch được, nếu không có thì dùng từ widget
        final finalAvatar = (avatar != null && avatar.isNotEmpty) 
            ? avatar 
            : widget.otherUserAvatar;
        
        print('📸 Avatar sau khi fetch:');
        print('  - avatar từ users collection: $avatar');
        print('  - widget.otherUserAvatar: ${widget.otherUserAvatar}');
        print('  - finalAvatar (sẽ set vào _displayAvatar): $finalAvatar');
        print('  - _displayAvatar (trước setState): $_displayAvatar');
        
        setState(() {
          if (name != null && name.isNotEmpty && name != 'Người dùng') {
            _displayName = name;
          } else {
            _displayName = widget.otherUserName;
          }
          // Set avatar - luôn cập nhật nếu có avatar mới
          if (finalAvatar != null && finalAvatar.isNotEmpty) {
            _displayAvatar = finalAvatar;
            print('  ✅ Đã set _displayAvatar = $finalAvatar');
          } else {
            print('  ⚠️ finalAvatar là null hoặc empty, giữ nguyên _displayAvatar');
          }
        });
        
        print('  - _displayAvatar (sau setState): $_displayAvatar');
        print('  - Avatar sẽ hiển thị: ${_displayAvatar ?? widget.otherUserAvatar}');
        
        // Cập nhật conversation với tên và avatar mới nếu có
        if (name != null && name.isNotEmpty && name != 'Người dùng') {
          try {
            final updateData = <String, dynamic>{
              'otherUserName': name,
            };
            if (avatar != null && avatar.isNotEmpty) {
              updateData['otherUserAvatar'] = avatar;
            }
            
            await _firestore
                .collection('conversations')
                .doc(widget.conversationId)
                .update(updateData);
            print('✅ Đã cập nhật conversation với tên: $name, avatar: $avatar');
          } catch (e) {
            print('⚠️ Lỗi cập nhật conversation: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi lấy tên user ${otherUserId}: $e');
      if (mounted) {
        setState(() {
          _displayName = widget.otherUserName;
          _displayAvatar = widget.otherUserAvatar;
        });
      }
    }
  }

  void _setupMessageListener() {
    // Listen for new messages từ người khác
    _repository.getMessagesStream(widget.conversationId).listen((messages) {
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        final currentUserId = _auth.currentUser?.uid;
        
        // Nếu tin nhắn mới nhất không phải từ user hiện tại và chưa đọc
        if (lastMessage.senderId != currentUserId && !lastMessage.isRead) {
          // Notification sẽ được tạo tự động khi gửi tin nhắn (trong sendMessage)
          // Nhưng nếu user nhận tin nhắn khi đang ở màn hình khác, cần tạo notification
          // Logic này đã được xử lý trong sendMessage của người gửi
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Nếu có ảnh, upload trước
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        print('📸 [_sendMessage] Bắt đầu upload ${_selectedImages.length} ảnh');
        final uploadResult = await _repository.uploadChatImages(_selectedImages);
        if (uploadResult is ApiSuccess<List<String>>) {
          imageUrls = uploadResult.data;
          print('✅ [_sendMessage] Upload thành công ${imageUrls?.length ?? 0} ảnh');
        } else {
          print('❌ [_sendMessage] Lỗi upload ảnh: ${(uploadResult as ApiError).message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi upload ảnh: ${(uploadResult as ApiError).message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            _isSending = false;
          });
          return;
        }
      }

      // Gửi tin nhắn
      final messageContent = content.isEmpty && imageUrls != null
          ? 'Đã gửi ${imageUrls!.length} ảnh'
          : content;

      final result = await _repository.sendMessage(
        conversationId: widget.conversationId,
        content: messageContent,
        type: imageUrls != null ? MessageType.image : MessageType.text,
        attachmentUrls: imageUrls,
      );

      if (result is ApiSuccess) {
        _messageController.clear();
        setState(() {
          _selectedImages.clear();
          _isSending = false;
        });
        // Scroll xuống tin nhắn mới
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi gửi tin nhắn: ${(result as ApiError).message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showOptionsMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Tắt tiếng'),
              onTap: () => Navigator.pop(context, 'mute'),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Báo cáo'),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Chặn'),
              onTap: () => Navigator.pop(context, 'block'),
            ),
            if (widget.roomId != null)
              ListTile(
                leading: const Icon(Icons.home),
                title: Text('Xem phòng: ${widget.roomTitle ?? "Phòng trọ"}'),
                onTap: () => Navigator.pop(context, 'view_room'),
              ),
          ],
        ),
      ),
    );

    if (result == null) return;

    switch (result) {
      case 'mute':
        _toggleMute();
        break;
      case 'report':
        _showReportDialog();
        break;
      case 'block':
        _showBlockDialog();
        break;
      case 'view_room':
        // TODO: Navigate to room detail
        break;
    }
  }

  Future<void> _toggleMute() async {
    // TODO: Get current mute status from conversation
    final result = await _repository.toggleMuteConversation(widget.conversationId, true);
    if (mounted) {
      if (result is ApiSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tắt tiếng cuộc trò chuyện')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${(result as ApiError).message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reasonController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo người dùng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                hintText: 'Spam, quấy rối, lừa đảo...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết (tùy chọn)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi báo cáo'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      final reportResult = await _repository.reportUser(
        reportedUserId: widget.otherUserId,
        reason: reasonController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        conversationId: widget.conversationId,
      );

      if (mounted) {
        if (reportResult is ApiSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi báo cáo. Cảm ơn bạn đã phản hồi!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${(reportResult as ApiError).message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showBlockDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chặn người dùng'),
        content: const Text('Bạn có chắc chắn muốn chặn người dùng này? Bạn sẽ không thể nhận tin nhắn từ họ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Chặn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final blockResult = await _repository.toggleBlockUser(widget.otherUserId, true);
      if (mounted) {
        if (blockResult is ApiSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chặn người dùng'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Quay lại màn hình trước
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${(blockResult as ApiError).message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Builder(
              builder: (context) {
                final avatarUrl = _displayAvatar ?? widget.otherUserAvatar;
                print('🖼️ [CircleAvatar] Đang render avatar:');
                print('   - _displayAvatar: $_displayAvatar');
                print('   - widget.otherUserAvatar: ${widget.otherUserAvatar}');
                print('   - avatarUrl (final): $avatarUrl');
                
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    print('❌ Lỗi load avatar: $exception');
                    print('  - Avatar URL: $avatarUrl');
                    print('  - _displayAvatar: $_displayAvatar');
                    print('  - widget.otherUserAvatar: ${widget.otherUserAvatar}');
                    // Nếu load avatar thất bại, set về null để hiển thị chữ cái đầu
                    if (mounted) {
                      setState(() {
                        _displayAvatar = null;
                      });
                    }
                  },
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          (_displayName ?? widget.otherUserName).isNotEmpty
                              ? (_displayName ?? widget.otherUserName)[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(fontSize: 16),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _displayName ?? widget.otherUserName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.roomTitle != null)
                    Text(
                      widget.roomTitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected images preview
          if (_selectedImages.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.red,
                          onPressed: () => _removeImage(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _repository.getMessagesStream(widget.conversationId),
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

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có tin nhắn nào',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                // Scroll to bottom when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                // Messages từ repository đã được reverse: [mới nhất, ..., cũ nhất]
                // ListView với reverse: true sẽ hiển thị:
                // - Item đầu tiên (mới nhất) → ở dưới cùng ✓
                // - Item cuối cùng (cũ nhất) → ở trên cùng ✓
                // 
                // Đảm bảo sort descending (mới nhất trước) để chắc chắn
                final sortedMessages = List<Message>.from(messages)
                  ..sort((a, b) {
                    final aTime = a.createdAt.millisecondsSinceEpoch;
                    final bTime = b.createdAt.millisecondsSinceEpoch;
                    // Descending: mới nhất trước (sẽ hiển thị ở dưới với reverse: true)
                    final compare = bTime.compareTo(aTime);
                    if (compare != 0) return compare;
                    // Nếu cùng thời gian, sort theo id (ngược lại để nhất quán)
                    return b.id.compareTo(a.id);
                  });
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedMessages.length,
                  itemBuilder: (context, index) {
                    final message = sortedMessages[index];
                    final isMe = message.senderId == user?.uid;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImages,
                    tooltip: 'Chọn ảnh',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _sendMessage,
                    tooltip: 'Gửi',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  final Message message;
  final bool isMe;

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case MessageStatus.sent:
        return const Icon(Icons.done, size: 16, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      case MessageStatus.failed:
        return const Icon(Icons.error, size: 16, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? theme.colorScheme.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text content
                  if (message.type == MessageType.text)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),

                  // Image attachments
                  if (message.attachments != null && message.attachments!.isNotEmpty)
                    ...message.attachments!.map((url) {
                      if (message.type == MessageType.image) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: () {
                              // Mở màn hình full-screen để zoom ảnh
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _ImageZoomScreen(imageUrl: url),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                  // Time and status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Màn hình full-screen để zoom ảnh.
class _ImageZoomScreen extends StatelessWidget {
  const _ImageZoomScreen({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

