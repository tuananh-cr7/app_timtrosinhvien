import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'favorites_manager.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/rooms_repository.dart';
import 'models/room.dart';
import 'room_detail_screen.dart';
import 'widgets/room_card.dart';
import '../../core/models/api_result.dart';
import '../../core/widgets/loading_error_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesRepository = FavoritesRepository();
  final _roomsRepository = RoomsRepository();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _reload() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem phòng yêu thích'),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('favorites')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yêu thích',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0 phòng đã lưu',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 48),
                    Icon(Icons.favorite_border,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có phòng yêu thích nào',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Bấm vào icon trái tim trên các phòng trọ để lưu yêu thích',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Lấy room IDs từ favorites
            final favoriteDocs = snapshot.data!.docs;
            final favoriteCount = favoriteDocs.length;
            print('📊 FavoritesScreen: Tìm thấy $favoriteCount favorites');
            
            final roomIds = <String>[];
            for (final doc in favoriteDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final roomId = data['roomId'] as String?;
              if (roomId != null) {
                roomIds.add(roomId);
                print('  - Room ID: $roomId');
              }
            }
            
            print('📊 Tổng cộng ${roomIds.length} room IDs để load');

            // Load thông tin các phòng
            return FutureBuilder<List<Room>>(
              future: _loadRoomsByIds(roomIds),
              builder: (context, roomsSnapshot) {
                if (roomsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = roomsSnapshot.data ?? [];
                final countText = '$favoriteCount phòng đã lưu';

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yêu thích',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          countText,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 48),
                        Icon(Icons.favorite_border,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có phòng yêu thích nào',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    // Header với "Yêu thích" và số phòng đã lưu (căn giữa)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Yêu thích',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countText,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    // Danh sách phòng
                    ...rooms.map((room) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RoomCard(
                        room: room,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(room: room),
                            ),
                          );
                          // Stream sẽ tự động update
                        },
                      ),
                    )),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Room>> _loadRoomsByIds(List<String> roomIds) async {
    final rooms = <Room>[];
    print('📊 Bắt đầu load ${roomIds.length} phòng...');
    for (final roomId in roomIds) {
      print('  - Đang load roomId: $roomId');
      final result = await _roomsRepository.getRoomById(roomId);
      if (result.isSuccess) {
        final room = switch (result) {
          ApiSuccess<Room?>(data: final data) => data,
          _ => null,
        };
        if (room != null) {
          print('    ✅ Tìm thấy: ${room.title}');
          rooms.add(room);
        } else {
          print('    ⚠️  Room null cho roomId: $roomId');
        }
      } else {
        print('    ❌ Lỗi khi load roomId: $roomId - ${switch (result) { ApiError<Room?>(message: final msg) => msg, _ => 'Unknown error' }}');
      }
    }
    print('📊 Hoàn tất: Load được ${rooms.length}/${roomIds.length} phòng');
    return rooms;
  }
}


