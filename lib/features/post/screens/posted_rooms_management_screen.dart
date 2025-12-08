import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/data/repositories/rooms_repository.dart';
import '../../home/models/room.dart';
import '../../home/widgets/room_card.dart';
import '../../home/room_detail_screen.dart';
import '../../../core/models/api_result.dart';
import '../../../core/widgets/loading_error_widget.dart';
import '../screens/post_listing_flow.dart';

/// Màn hình quản lý tin đã đăng với tabs và actions.
class PostedRoomsManagementScreen extends StatefulWidget {
  const PostedRoomsManagementScreen({super.key});

  @override
  State<PostedRoomsManagementScreen> createState() =>
      _PostedRoomsManagementScreenState();
}

class _PostedRoomsManagementScreenState
    extends State<PostedRoomsManagementScreen> with SingleTickerProviderStateMixin {
  final _roomsRepository = RoomsRepository();
  late TabController _tabController;
  int _selectedTab = 0;

  final List<RoomStatus> _statuses = [
    RoomStatus.pending, // Đang chờ duyệt (tab đầu tiên - nơi tin mới xuất hiện)
    RoomStatus.active, // Đang hiển thị
    RoomStatus.hidden, // Đã ẩn
    RoomStatus.rented, // Đã cho thuê
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Room>> _loadRooms(RoomStatus status, {bool loadMore = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️  _loadRooms: User chưa đăng nhập');
      return [];
    }

    // Chuyển đổi RoomStatus enum sang string
    final statusString = _statusToString(status);
    print('📊 _loadRooms: Đang load rooms với status=$statusString cho user=${user.uid}, loadMore=$loadMore');

    final result = await _roomsRepository.getRoomsByOwner(user.uid);
    return switch (result) {
      ApiSuccess<List<Room>>(data: final rooms) => 
        () {
          final filtered = rooms.where((room) => room.status == statusString).toList();
          print('📊 _loadRooms: Tìm thấy ${rooms.length} rooms, sau khi filter status=$statusString còn ${filtered.length} rooms');
          return filtered;
        }(),
      _ => () {
        print('⚠️  _loadRooms: Lỗi khi load rooms');
        return <Room>[];
      }(),
    };
  }

  /// Chuyển đổi RoomStatus enum sang string.
  String _statusToString(RoomStatus status) {
    switch (status) {
      case RoomStatus.active:
        return 'active';
      case RoomStatus.pending:
        return 'pending';
      case RoomStatus.hidden:
        return 'hidden';
      case RoomStatus.rented:
        return 'rented';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin đã đăng'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Đang chờ duyệt'),
            Tab(text: 'Đang hiển thị'),
            Tab(text: 'Đã ẩn'),
            Tab(text: 'Đã cho thuê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          return _buildStatusTab(status);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PostListingFlow(loadDraft: false), // Bắt đầu mới
            ),
          );
          if (result == true && mounted) {
            setState(() {}); // Refresh
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Đăng tin mới'),
      ),
    );
  }

  Widget _buildStatusTab(RoomStatus status) {
    return FutureBuilder<List<Room>>(
      future: _loadRooms(status),
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

        final rooms = snapshot.data ?? [];

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có tin đăng nào',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
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
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _buildRoomCard(room, status);
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(Room room, RoomStatus status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomDetailScreen(room: room),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (room.thumbnailUrl.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    room.thumbnailUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColorFromString(room.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusLabelFromString(room.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${room.priceMillion.toStringAsFixed(1)} triệu /tháng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Title/Address
                Text(
                  room.title.isNotEmpty ? room.title : room.address,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Stats
                Row(
                  children: [
                    Text(
                      'Lượt xem: 0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Liên hệ: 0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions - Hiển thị các nút phù hợp với status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(room),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.active:
        return Colors.green;
      case RoomStatus.pending:
        return Colors.orange;
      case RoomStatus.hidden:
        return Colors.grey;
      case RoomStatus.rented:
        return Colors.blue;
    }
  }

  String _getStatusLabel(RoomStatus status) {
    switch (status) {
      case RoomStatus.active:
        return 'Đang hiển thị';
      case RoomStatus.pending:
        return 'Đang chờ duyệt';
      case RoomStatus.hidden:
        return 'Đã ẩn';
      case RoomStatus.rented:
        return 'Đã cho thuê';
    }
  }

  /// Chuyển đổi status string sang label tiếng Việt.
  String _getStatusLabelFromString(String status) {
    switch (status) {
      case 'active':
        return 'Đang hiển thị';
      case 'pending':
        return 'Đang chờ duyệt';
      case 'hidden':
        return 'Đã ẩn';
      case 'rented':
        return 'Đã cho thuê';
      default:
        return 'Không rõ';
    }
  }

  /// Chuyển đổi status string sang màu.
  Color _getStatusColorFromString(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'hidden':
        return Colors.grey;
      case 'rented':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _editRoom(Room room) async {
    // TODO: Navigate to edit flow với room data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostListingFlow(roomId: room.id),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  /// Xây dựng danh sách action buttons dựa trên status của room.
  List<Widget> _buildActionButtons(Room room) {
    final buttons = <Widget>[];

    // Nút Chỉnh sửa - chỉ hiển thị cho pending và active
    if (room.status == 'pending' || room.status == 'active') {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editRoom(room),
          tooltip: 'Chỉnh sửa',
        ),
      );
    }

    // Nút Ẩn/Hiện - chỉ cho active và hidden
    if (room.status == 'active' || room.status == 'hidden') {
      buttons.add(
        IconButton(
          icon: Icon(
            room.status == 'hidden' ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () => _toggleVisibility(room),
          tooltip: room.status == 'hidden' ? 'Hiện lại' : 'Ẩn tin',
        ),
      );
    }

    // Nút "Đã cho thuê" - chỉ cho active
    if (room.status == 'active') {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
          onPressed: () => _markAsRented(room),
          tooltip: 'Đánh dấu đã cho thuê',
        ),
      );
    }

    // Nút "Hiện lại" - chỉ cho rented
    if (room.status == 'rented') {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.green),
          onPressed: () => _markAsActive(room),
          tooltip: 'Hiện lại (còn trống)',
        ),
      );
    }

    // Nút Xóa - luôn hiển thị
    buttons.add(
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteRoom(room),
        tooltip: 'Xóa tin',
      ),
    );

    return buttons;
  }

  /// Chuyển đổi giữa Ẩn/Hiện (active ↔ hidden).
  void _toggleVisibility(Room room) async {
    final newStatus = room.status == 'hidden' ? 'active' : 'hidden';
    final action = newStatus == 'active' ? 'hiện' : 'ẩn';

    // Hiển thị loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang $action tin...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final result = await _roomsRepository.updateRoom(
      roomId: room.id,
      updates: {'status': newStatus},
    );

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
          SnackBar(
            content: Text('Đã $action tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh để cập nhật UI
      }
    }
  }

  /// Đánh dấu phòng đã cho thuê (active → rented).
  void _markAsRented(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh dấu đã cho thuê'),
        content: const Text(
          'Bạn có chắc chắn muốn đánh dấu phòng này đã được cho thuê? '
          'Tin đăng sẽ không hiển thị trên trang chủ nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Hiển thị loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang cập nhật...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final result = await _roomsRepository.updateRoom(
      roomId: room.id,
      updates: {'status': 'rented'},
    );

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
            content: Text('Đã đánh dấu phòng đã cho thuê'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh để cập nhật UI
      }
    }
  }

  /// Đánh dấu phòng còn trống (rented → active).
  void _markAsActive(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hiện lại tin đăng'),
        content: const Text(
          'Bạn có chắc chắn muốn hiện lại tin đăng này? '
          'Tin đăng sẽ hiển thị trên trang chủ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Hiển thị loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang cập nhật...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final result = await _roomsRepository.updateRoom(
      roomId: room.id,
      updates: {'status': 'active'},
    );

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
            content: Text('Đã hiện lại tin đăng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh để cập nhật UI
      }
    }
  }

  void _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tin đăng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _roomsRepository.deleteRoom(room.id);
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
              content: Text('Đã xóa tin đăng'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      }
    }
  }
}

enum RoomStatus {
  active, // Đang hiển thị
  pending, // Đang chờ duyệt
  hidden, // Đã ẩn
  rented, // Đã cho thuê
}

