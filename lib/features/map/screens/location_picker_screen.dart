import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Màn hình chọn vị trí từ bản đồ (dùng trong Step2AddressScreen).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedLocation = const LatLng(21.0285, 105.8542); // Hà Nội mặc định
    }
    // Không gọi move() trong initState, sẽ dùng initialCenter trong MapOptions
    _getCurrentLocation();
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
                content: Text('Cần quyền truy cập vị trí để lấy vị trí hiện tại'),
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
              content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt'),
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

      // Lấy vị trí với độ chính xác cao nhất và timeout
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
        });
        
        // Di chuyển map đến vị trí hiện tại
        try {
          _mapController.move(_currentLocation!, 16.0);
        } catch (e) {
          // Map chưa sẵn sàng, bỏ qua
        }
        
        // Hiển thị thông tin về độ chính xác
        if (mounted && position != null) {
          final accuracy = position!.accuracy;
          if (accuracy > 50) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Độ chính xác: ${accuracy.toStringAsFixed(0)}m. '
                  'Vui lòng đợi GPS ổn định hoặc di chuyển ra nơi thoáng hơn.',
                ),
                duration: const Duration(seconds: 4),
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

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    // Chỉ move nếu map đã được render
    try {
      _mapController.move(point, _mapController.camera.zoom);
    } catch (e) {
      // Map chưa sẵn sàng, bỏ qua
    }
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      setState(() {
        _selectedLocation = _currentLocation;
      });
      // Chỉ move nếu map đã được render
      try {
        _mapController.move(_currentLocation!, 15.0);
      } catch (e) {
        // Map chưa sẵn sàng, bỏ qua
      }
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí từ bản đồ'),
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(21.0285, 105.8542),
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_timtrosinhvien',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Center crosshair
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedLocation != null)
                      Text(
                        'Vị trí đã chọn: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _confirmSelection,
                        child: const Text('Xác nhận vị trí'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

