import 'package:flutter/material.dart';

import 'models/room.dart';
import 'room_detail_screen.dart';
import 'data/repositories/rooms_repository.dart';
import '../../../core/models/api_result.dart';

/// Màn hình danh sách phòng với infinite scroll.
class RoomListScreen extends StatefulWidget {
  const RoomListScreen({
    super.key,
    required this.title,
    this.initialRooms,
    this.loadMoreRooms,
  });

  final String title;
  final List<Room>? initialRooms;
  final Future<ApiResult<List<Room>>> Function({int limit, int offset})? loadMoreRooms;

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _roomsRepository = RoomsRepository();
  final _scrollController = ScrollController();
  
  List<Room> _rooms = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 20;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialRooms != null) {
      _rooms = List.from(widget.initialRooms!);
      _offset = _rooms.length;
      _hasMore = _rooms.length >= _pageSize;
    } else {
      _loadMoreRooms();
    }
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreRooms();
      }
    }
  }

  Future<void> _loadMoreRooms() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ApiResult<List<Room>> result;
      
      if (widget.loadMoreRooms != null) {
        result = await widget.loadMoreRooms!(
          limit: _pageSize,
          offset: _offset,
        );
      } else {
        // Default: load all rooms
        result = await _roomsRepository.getRooms(limit: _pageSize);
      }

      if (mounted) {
        setState(() {
          switch (result) {
            case ApiSuccess<List<Room>>(data: final newRooms):
              if (newRooms.isEmpty) {
                _hasMore = false;
              } else {
                _rooms.addAll(newRooms);
                _offset = _rooms.length;
                _hasMore = newRooms.length >= _pageSize;
              }
              break;
            case ApiError<List<Room>>(message: final message):
              _errorMessage = message;
              break;
            case ApiLoading<List<Room>>():
              break;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _rooms.clear();
            _offset = 0;
            _hasMore = true;
          });
          await _loadMoreRooms();
        },
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _rooms.length + (_hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= _rooms.length) {
              // Loading indicator ở cuối
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final room = _rooms[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoomDetailScreen(room: room),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      room.thumbnailUrl,
                      width: 110,
                      height: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 110,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 110,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${room.priceMillion.toStringAsFixed(1)} triệu',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                room.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.square_foot_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Diện tích ${room.area.toStringAsFixed(0)} m2',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


