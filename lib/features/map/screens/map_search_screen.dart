import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../home/data/repositories/rooms_repository.dart';
import '../../home/models/room.dart';
import '../../home/room_detail_screen.dart';
import '../../../core/models/api_result.dart';

/// Màn hình tìm kiếm phòng trọ bằng bản đồ.
class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({
    super.key,
    this.initialRoom,
    this.initialCenter,
  });

  /// Room để highlight trên bản đồ (khi mở từ RoomDetailScreen)
  final Room? initialRoom;
  
  /// Vị trí center ban đầu (nếu không có initialRoom)
  final LatLng? initialCenter;

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final MapController _mapController = MapController();
  final _roomsRepository = RoomsRepository();
  List<Room> _rooms = [];
  bool _isLoading = true;
  LatLng? _currentLocation;
  double _radiusKm = 5.0; // Bán kính tìm kiếm (km)
  LatLng? _centerLocation;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    // Ưu tiên initialRoom, sau đó initialCenter, cuối cùng là Hà Nội mặc định
    if (widget.initialRoom?.latitude != null && widget.initialRoom?.longitude != null) {
      _centerLocation = LatLng(
        widget.initialRoom!.latitude!,
        widget.initialRoom!.longitude!,
      );
      _selectedRoomId = widget.initialRoom!.id;
    } else if (widget.initialCenter != null) {
      _centerLocation = widget.initialCenter;
    } else {
      _centerLocation = const LatLng(21.0285, 105.8542); // Hà Nội mặc định
    }
    _loadRooms();
    if (widget.initialRoom == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra dịch vụ định vị
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng bật dịch vụ định vị (GPS)'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Kiểm tra và yêu cầu quyền
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cần quyền truy cập vị trí'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Hiển thị loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang lấy vị trí GPS...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Lấy vị trí với độ chính xác cao nhất
      Position? position;
      
      try {
        // Thử lấy vị trí với độ chính xác cao nhất
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Nếu timeout, thử lấy vị trí với độ chính xác thấp hơn
            return Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 5),
            );
          },
        );
      } catch (e) {
        // Nếu vẫn lỗi, thử lấy vị trí cuối cùng đã biết
        print('⚠️ Không thể lấy vị trí mới, thử lấy vị trí cuối cùng: $e');
        position = await Geolocator.getLastKnownPosition();
        
        if (position == null) {
          throw Exception('Không thể lấy vị trí. Vui lòng đảm bảo GPS đã bật và có tín hiệu.');
        }
      }

      if (position != null && mounted) {
        setState(() {
          _currentLocation = LatLng(position!.latitude, position!.longitude);
          // Chỉ update center nếu chưa có initialRoom
          if (widget.initialRoom == null) {
            _centerLocation = _currentLocation;
            // Chỉ move nếu map đã được render
            try {
              _mapController.move(_currentLocation!, 15.0);
            } catch (e) {
              // Map chưa sẵn sàng, bỏ qua
            }
          }
        });
        
        // Hiển thị thông tin về độ chính xác
        if (mounted && widget.initialRoom == null && position != null) {
          final accuracy = position!.accuracy;
          if (accuracy > 50) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Độ chính xác: ${accuracy.toStringAsFixed(0)}m. '
                  'Vui lòng đợi GPS ổn định.',
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Đã lấy vị trí (độ chính xác: ${accuracy.toStringAsFixed(0)}m)',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        
        if (widget.initialRoom == null) {
          _loadRooms();
        }
      }
    } catch (e) {
      print('❌ Lỗi lấy vị trí: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lấy vị trí: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _roomsRepository.getRooms(limit: 100);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case ApiSuccess<List<Room>>(data: final rooms):
            _rooms = rooms;
            // Filter theo radius nếu có center location
            if (_centerLocation != null) {
              _rooms = _rooms.where((room) {
                if (room.latitude == null || room.longitude == null) return false;
                final distance = Geolocator.distanceBetween(
                  _centerLocation!.latitude,
                  _centerLocation!.longitude,
                  room.latitude!,
                  room.longitude!,
                ) / 1000; // Convert to km
                return distance <= _radiusKm;
              }).toList();
            }
            break;
          case ApiError<List<Room>>():
            _rooms = [];
            break;
          case ApiLoading<List<Room>>():
            break;
        }
      });
    }
  }

  void _onMapMoved() {
    if (_mapController.camera.center != null) {
      setState(() {
        _centerLocation = _mapController.camera.center;
      });
      _loadRooms();
    }
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      // Chỉ move nếu map đã được render
      try {
        _mapController.move(_currentLocation!, 15.0);
      } catch (e) {
        // Map chưa sẵn sàng, bỏ qua
      }
      setState(() {
        _centerLocation = _currentLocation;
      });
      _loadRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm bằng bản đồ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
            tooltip: 'Vị trí hiện tại',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerLocation ?? const LatLng(21.0285, 105.8542),
              initialZoom: widget.initialRoom != null ? 15.0 : 13.0,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _onMapMoved();
                }
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedRoomId = null;
                });
              },
            ),
            children: [
              // Tile layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_timtrosinhvien',
                maxZoom: 19,
              ),
              // Markers
              MarkerLayer(
                markers: _buildMarkers(),
              ),
              // Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              // Radius circle
              if (_centerLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _centerLocation!,
                      radius: _radiusKm * 1000, // Convert km to meters
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),
          // Radius filter control
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bán kính',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _radiusKm,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              label: '${_radiusKm.toStringAsFixed(1)} km',
                              onChanged: (value) {
                                setState(() {
                                  _radiusKm = value;
                                });
                                _loadRooms();
                              },
                            ),
                          ),
                          Text(
                            '${_radiusKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Room list bottom sheet
          if (_rooms.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.3,
              minChildSize: 0.1,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_rooms.length} phòng trong bán kính ${_radiusKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                      // Room list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _rooms.length,
                          itemBuilder: (context, index) {
                            final room = _rooms[index];
                            return _buildRoomListItem(room);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _rooms.map((room) {
      if (room.latitude == null || room.longitude == null) {
        return Marker(point: const LatLng(0, 0), width: 0, height: 0, child: const SizedBox());
      }

      final isSelected = room.id == _selectedRoomId;
      
      return Marker(
        point: LatLng(room.latitude!, room.longitude!),
        width: isSelected ? 60 : 50,
        height: isSelected ? 60 : 50,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedRoomId = isSelected ? null : room.id;
            });
            if (!isSelected) {
              _showRoomInfo(room);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home,
                  color: Colors.white,
                  size: isSelected ? 30 : 24,
                ),
              ),
              // Price badge
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '${room.priceMillion.toStringAsFixed(1)}Tr',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRoomListItem(Room room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomDetailScreen(room: room),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  room.thumbnailUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.title.isNotEmpty ? room.title : room.address,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        Expanded(
                          child: Text(
                            room.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.priceMillion.toStringAsFixed(1)} triệu/tháng • ${room.area} m²',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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

  void _showRoomInfo(Room room) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  room.thumbnailUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              room.title.isNotEmpty ? room.title : room.address,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                Expanded(
                  child: Text(
                    room.address,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${room.priceMillion.toStringAsFixed(1)} triệu/tháng • ${room.area} m²',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoomDetailScreen(room: room),
                    ),
                  );
                },
                child: const Text('Xem chi tiết'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

