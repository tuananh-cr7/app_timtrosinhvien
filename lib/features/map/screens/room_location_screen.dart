import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../home/models/room.dart';

/// Màn hình xem vị trí chi tiết của một phòng trọ
class RoomLocationScreen extends StatefulWidget {
  const RoomLocationScreen({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  State<RoomLocationScreen> createState() => _RoomLocationScreenState();
}

class _RoomLocationScreenState extends State<RoomLocationScreen> {
  late final MapController _mapController;
  late final LatLng _roomLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _roomLocation = LatLng(
      widget.room.latitude!,
      widget.room.longitude!,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vị trí phòng trọ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Về vị trí phòng',
            onPressed: () {
              try {
                _mapController.move(_roomLocation, 15.0);
              } catch (e) {
                // Map chưa render xong, bỏ qua
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _roomLocation,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app_timtrosinhvien',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _roomLocation,
                    width: 50,
                    height: 50,
                    child: Container(
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
            ],
          ),
          // Card hiển thị thông tin địa chỉ
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Địa chỉ',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.room.address,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (widget.room.district != null && widget.room.district!.isNotEmpty)
                      Text(
                        '${widget.room.district}, ${widget.room.city}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Tọa độ: ${widget.room.latitude!.toStringAsFixed(6)}, ${widget.room.longitude!.toStringAsFixed(6)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
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

