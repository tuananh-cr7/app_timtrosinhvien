import 'package:flutter/material.dart';

import 'data/mock_rooms.dart';
import 'data/repositories/rooms_repository.dart';
import 'models/room.dart';
import 'room_detail_screen.dart';
import 'widgets/room_card.dart';
import '../account/account_screen.dart';
import '../post/screens/post_listing_flow.dart';
import 'favorites_screen.dart';
import 'room_list_screen.dart';
import '../../core/models/api_result.dart';
import '../../core/widgets/loading_error_widget.dart';
import '../../core/widgets/offline_indicator.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/offline_queue_service.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/view_history_repository.dart';
import '../notifications/screens/notifications_screen.dart';
import '../notifications/data/repositories/notifications_repository.dart';
import '../search/screens/search_screen.dart';

/// Shell Trang chủ + BottomNavigationBar 5 tab theo thiết kế.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.connectivityService,
    required this.offlineQueueService,
  });

  final ConnectivityService connectivityService;
  final OfflineQueueService offlineQueueService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Trang chủ'),
    _TabItem(icon: Icons.search_rounded, label: 'Tìm kiếm'),
    _TabItem(icon: Icons.favorite_rounded, label: 'Yêu thích'),
    _TabItem(icon: Icons.notifications_rounded, label: 'Thông báo'),
    _TabItem(icon: Icons.person_rounded, label: 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    switch (_currentIndex) {
      case 0:
        body = const _HomeTab();
        break;
      case 1:
        body = const SearchScreen();
        break;
      case 2:
        body = const FavoritesScreen();
        break;
      case 3:
        body = const NotificationsScreen();
        break;
      case 4:
        body = const AccountScreen();
        break;
      default:
        body = Center(
          child: Text(
            _tabs[_currentIndex].label,
            style: theme.textTheme.headlineSmall,
          ),
        );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OfflineIndicator(connectivityService: widget.connectivityService),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme) {
    return StreamBuilder<int>(
      stream: NotificationsRepository().getUnreadCountStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          items: _tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            return BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(tab.icon),
                  if (index == 3 && unreadCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: tab.label,
            );
          }).toList(),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        );
      },
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _roomsRepository = RoomsRepository();
   final _favoritesRepository = FavoritesRepository();
   final _viewHistoryRepository = ViewHistoryRepository();
  late Future<ApiResult<List<Room>>> _latestRoomsFuture;
  late Future<ApiResult<List<Room>>> _sharedRoomsFuture;
  late Future<ApiResult<List<Room>>> _allRoomsFuture;
   late Future<ApiResult<List<Room>>> _recommendedFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _latestRoomsFuture = _roomsRepository.getLatestRooms(limit: 6);
      _sharedRoomsFuture = _roomsRepository.getSharedRooms(limit: 6);
      _allRoomsFuture = _roomsRepository.getRooms(limit: 6);
      _recommendedFuture = _loadRecommendations();
    });
  }

  List<Room> _getFallbackRooms(String type) {
    switch (type) {
      case 'latest':
        return mockLatestRooms;
      case 'shared':
        return mockSharedRooms;
      case 'all':
        return mockAllRooms;
      default:
        return [];
    }
  }

  Future<ApiResult<List<Room>>> _loadRecommendations() async {
    try {
      // Lấy phòng gốc từ favorites hoặc view history để xác định khu vực/giá tham chiếu
      Room? anchor;
      final favResult = await _favoritesRepository.getFavoriteRooms();
      if (favResult is ApiSuccess<List<Room>> && favResult.data.isNotEmpty) {
        anchor = favResult.data.first;
      } else {
        final historyResult = await _viewHistoryRepository.getHistory(limit: 50);
        if (historyResult is ApiSuccess<List<ViewHistoryEntry>> && historyResult.data.isNotEmpty) {
          anchor = historyResult.data.first.room;
        }
      }

      // Lấy danh sách phòng mới nhất để đề xuất
      final roomsResult = await _roomsRepository.getRooms(limit: 50, useCache: true);
      if (roomsResult is! ApiSuccess<List<Room>>) {
        return ApiSuccess(_getFallbackRooms('latest'));
      }
      var rooms = roomsResult.data;

      // Nếu có anchor, lọc theo khu vực và giá ±20%
      if (anchor != null) {
        final targetCity = anchor.city;
        final targetDistrict = anchor.district;
        final targetPrice = anchor.priceMillion;
        rooms = rooms.where((r) {
          final matchCity = targetCity == null || r.city == targetCity;
          final matchDistrict = targetDistrict == null || r.district == targetDistrict;
          final matchPrice = targetPrice == null
              ? true
              : (r.priceMillion >= targetPrice * 0.8 && r.priceMillion <= targetPrice * 1.2);
          return matchCity && matchDistrict && matchPrice && r.id != anchor!.id;
        }).toList();
      }

      // Nếu lọc xong trống, fallback về phòng mới đăng
      if (rooms.isEmpty) {
        rooms = _getFallbackRooms('latest');
      }

      // Giới hạn 6 mục
      return ApiSuccess(rooms.take(6).toList());
    } catch (e) {
      print('⚠️ Lỗi load recommendations: $e');
      return ApiSuccess(_getFallbackRooms('latest'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhà Trọ 360',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng mới cập nhật tại Hà Nội',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PostListingFlow(),
                        ),
                      );
                      if (result == true) {
                        _loadData(); // Refresh data
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Đăng tin'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Gợi ý cho bạn
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Gợi ý cho bạn',
            onSeeAll: () => _openListFromFuture(
              context,
              'Gợi ý cho bạn',
              _recommendedFuture,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FutureBuilder<ApiResult<List<Room>>>(
            future: _recommendedFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final result = snapshot.data!;
              final rooms = result.dataOrNull ?? _getFallbackRooms('latest');

              if (rooms.isEmpty) {
                return const SizedBox.shrink();
              }

              return LoadingErrorWidget(
                result: result,
                onRetry: _loadData,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: rooms.length.clamp(0, 6),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return RoomCard(
                        room: room,
                        onTap: () => _openDetail(context, room),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        // Phòng mới đăng
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Phòng mới đăng',
            onSeeAll: () => _openListFromFuture(
              context,
              'Phòng mới đăng',
              _roomsRepository.getLatestRooms(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FutureBuilder<ApiResult<List<Room>>>(
            future: _latestRoomsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final result = snapshot.data!;
              final rooms = result.dataOrNull ?? _getFallbackRooms('latest');

              return LoadingErrorWidget(
                result: result,
                onRetry: _loadData,
                child: rooms.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: rooms.length.clamp(0, 6),
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomCard(
                              room: room,
                              onTap: () => _openDetail(context, room),
                            );
                          },
                        ),
                      ),
              );
            },
          ),
        ),
        // Phòng ở ghép
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Phòng ở ghép',
            onSeeAll: () => _openListFromFuture(
              context,
              'Phòng ở ghép',
              _roomsRepository.getSharedRooms(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FutureBuilder<ApiResult<List<Room>>>(
            future: _sharedRoomsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final result = snapshot.data!;
              final rooms = result.dataOrNull ?? _getFallbackRooms('shared');

              return LoadingErrorWidget(
                result: result,
                onRetry: _loadData,
                child: rooms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          'Chưa có tin ở ghép',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: rooms.length.clamp(0, 6),
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomCard(
                              room: room,
                              onTap: () => _openDetail(context, room),
                            );
                          },
                        ),
                      ),
              );
            },
          ),
        ),
        // Tất cả phòng
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Tất cả phòng',
            onSeeAll: () => _openListFromFuture(
              context,
              'Tất cả phòng',
              _roomsRepository.getRooms(),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FutureBuilder<ApiResult<List<Room>>>(
            future: _allRoomsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final result = snapshot.data!;
              final rooms = result.dataOrNull ?? _getFallbackRooms('all');
              
              print('📊 Tất cả phòng: Hiển thị ${rooms.length} phòng');

              return LoadingErrorWidget(
                result: result,
                onRetry: _loadData,
                child: rooms.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          top: 0,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: rooms.length.clamp(0, 6),
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return RoomCard(
                              room: room,
                              onTap: () => _openDetail(context, room),
                            );
                          },
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _openDetail(BuildContext context, room) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RoomDetailScreen(room: room),
    ),
  );
}

void _openList(BuildContext context, String title, List<Room> rooms) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RoomListScreen(
        title: title,
        initialRooms: List.from(rooms),
      ),
    ),
  );
}

void _openListFromFuture(
  BuildContext context,
  String title,
  Future<ApiResult<List<Room>>> future,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _RoomListScreenFromFuture(
        title: title,
        future: future,
      ),
    ),
  );
}

class _RoomListScreenFromFuture extends StatelessWidget {
  const _RoomListScreenFromFuture({
    required this.title,
    required this.future,
  });

  final String title;
  final Future<ApiResult<List<Room>>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiResult<List<Room>>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data!;
        final initialRooms = result.dataOrNull ?? [];

        return RoomListScreen(
          title: title,
          initialRooms: initialRooms,
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Xem thêm'),
            ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

