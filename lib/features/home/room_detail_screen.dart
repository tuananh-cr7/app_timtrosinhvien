import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'models/room.dart';
import 'favorites_manager.dart';
import 'history_manager.dart';
import 'data/repositories/favorites_repository.dart';
import '../../core/models/api_result.dart';
import '../map/widgets/map_preview_widget.dart';
import '../map/screens/room_location_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.room});

  final Room room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;
  final _favoritesRepository = FavoritesRepository();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    HistoryManager.logView(widget.room);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    // Kiểm tra cả Firestore và local
    final firestoreResult = await _favoritesRepository.isFavorite(widget.room.id);
    final localFavorite = await FavoritesManager.isFavorite(widget.room.id);
    
    if (mounted) {
      setState(() {
        // Sử dụng pattern matching để lấy data
        final firestoreFavorite = switch (firestoreResult) {
          ApiSuccess<bool>(data: final data) => data,
          _ => null,
        };
        _isFavorite = firestoreFavorite ?? localFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newValue = !_isFavorite;
      
      if (newValue) {
        // Thêm vào yêu thích
        print('❤️ Đang thêm favorite cho roomId: ${widget.room.id}');
        final result = await _favoritesRepository.addFavorite(widget.room.id);
        switch (result) {
          case ApiError<void>(message: final msg):
            print('❌ Lỗi khi thêm favorite: $msg');
            throw Exception(msg);
          case ApiSuccess<void>():
            print('✅ Đã thêm favorite thành công cho roomId: ${widget.room.id}');
            // Thành công
            break;
          case ApiLoading<void>():
            // Không nên xảy ra
            break;
        }
        // Sync local
        if (!await FavoritesManager.isFavorite(widget.room.id)) {
          await FavoritesManager.toggleFavorite(widget.room);
        }
      } else {
        // Xóa khỏi yêu thích
        final result = await _favoritesRepository.removeFavorite(widget.room.id);
        switch (result) {
          case ApiError<void>(message: final msg):
            throw Exception(msg);
          case ApiSuccess<void>():
            // Thành công
            break;
          case ApiLoading<void>():
            // Không nên xảy ra
            break;
        }
        // Sync local
        if (await FavoritesManager.isFavorite(widget.room.id)) {
          await FavoritesManager.toggleFavorite(widget.room);
        }
      }

      if (mounted) {
        setState(() {
          _isFavorite = newValue;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue 
              ? 'Đã thêm vào yêu thích' 
              : 'Đã xóa khỏi yêu thích'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = widget.room;
    
    // Debug: Kiểm tra dữ liệu
    print('🔍 Room Detail - amenities: ${room.amenities}');
    print('🔍 Room Detail - availableItems: ${room.availableItems}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header + nội dung scroll
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh phòng (Carousel)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image carousel
                              _buildImageCarousel(room),
                              // Back button
                              Positioned(
                                top: 8,
                                left: 8,
                                child: IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withOpacity(0.4),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              // Menu button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withOpacity(0.4),
                                  ),
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      _showActionsBottomSheet(context),
                                ),
                              ),
                              // Image indicator (số ảnh và vị trí hiện tại)
                              if (_getImageList(room).length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      _getImageList(room).length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentImageIndex == index
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tiêu đề bài đăng
                              Text(
                                room.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${room.priceMillion.toStringAsFixed(1)} triệu /tháng',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.redAccent,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            _isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.redAccent,
                                          ),
                                    onPressed: _isLoading ? null : _toggleFavorite,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 18, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${room.address}, ${room.city}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Người đăng: ${room.ownerName ?? 'Chưa rõ'}',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_enabled_outlined,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    room.ownerPhone ?? 'Chưa có số liên hệ',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatRelativeTime(room.createdAt),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _makePhoneCall,
                                      icon: const Icon(Icons.call),
                                      label: const Text('Gọi ngay'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _sendSMS,
                                      icon: const Icon(Icons.sms_outlined),
                                      label: const Text('Gửi SMS'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _InfoChip(
                                    icon: Icons.square_foot_outlined,
                                    label:
                                        '${room.area.toStringAsFixed(0)} m²',
                                  ),
                                  const _InfoChip(
                                    icon: Icons.apartment_outlined,
                                    label: 'room',
                                  ),
                                  _InfoChip(
                                    icon: Icons.group_outlined,
                                    label: room.isShared
                                        ? 'Ở ghép'
                                        : 'Cho thuê riêng',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Mô tả
                              Text(
                                'Mô tả',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                room.description ??
                                    'Chưa có mô tả. Đây là nội dung mô tả mẫu cho phòng trọ.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              // Tiện ích
                              if (room.amenities != null && room.amenities!.isNotEmpty) ...[
                                Text(
                                  'Tiện ích',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: room.amenities!.map((amenity) {
                                    return Chip(
                                      label: Text(_getAmenityLabel(amenity)),
                                      backgroundColor: Colors.blue.shade50,
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Đồ dùng có sẵn
                              if (room.availableItems != null && room.availableItems!.isNotEmpty) ...[
                                Text(
                                  'Đồ dùng có sẵn',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: room.availableItems!.map((item) {
                                    return Chip(
                                      label: Text(_getItemLabel(item)),
                                      backgroundColor: Colors.green.shade50,
                                      labelStyle: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                              Text(
                                'Vị trí',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MapPreviewWidget(
                                latitude: room.latitude,
                                longitude: room.longitude,
                                height: 200,
                                markerTitle: room.title.isNotEmpty ? room.title : room.address,
                                onTap: () {
                                  // Mở màn hình xem vị trí chi tiết của phòng
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RoomLocationScreen(
                                        room: room,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (room.latitude != null && room.longitude != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tọa độ: ${room.latitude!.toStringAsFixed(6)}, ${room.longitude!.toStringAsFixed(6)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.call,
                label: 'Gọi điện',
                onTap: () {
                  Navigator.of(context).pop();
                  _makePhoneCall();
                },
              ),
              _ActionTile(
                icon: Icons.sms_outlined,
                label: 'Gửi SMS',
                onTap: () {
                  Navigator.of(context).pop();
                  _sendSMS();
                },
              ),
              _ActionTile(
                icon: Icons.navigation_outlined,
                label: 'Chỉ đường',
                onTap: () {
                  Navigator.of(context).pop();
                  _openDirections();
                },
              ),
              _ActionTile(
                icon: Icons.share_outlined,
                label: 'Chia sẻ',
                onTap: () {
                  Navigator.of(context).pop();
                  _shareRoom();
                },
              ),
              _ActionTile(
                icon: Icons.chat_bubble_outline,
                label: 'Chat với chủ trọ',
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Gọi điện thoại
  Future<void> _makePhoneCall() async {
    final phoneNumber = widget.room.ownerPhone;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có số điện thoại liên hệ'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Loại bỏ khoảng trắng và ký tự đặc biệt, chỉ giữ lại số
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    
    try {
      // Sử dụng LaunchMode.externalApplication để mở app bên ngoài
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở ứng dụng gọi điện'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi gọi điện: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Gửi SMS
  Future<void> _sendSMS() async {
    final phoneNumber = widget.room.ownerPhone;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có số điện thoại liên hệ'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Loại bỏ khoảng trắng và ký tự đặc biệt, chỉ giữ lại số
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('sms:$cleanPhone');
    
    try {
      // Sử dụng LaunchMode.externalApplication để mở app bên ngoài
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Thử với format khác: sms://
        final uri2 = Uri.parse('sms://$cleanPhone');
        if (await canLaunchUrl(uri2)) {
          await launchUrl(
            uri2,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể mở ứng dụng nhắn tin. Vui lòng kiểm tra lại số điện thoại.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi khi gửi SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Chia sẻ thông tin phòng trọ
  Future<void> _shareRoom() async {
    final room = widget.room;
    
    try {
      // Tạo nội dung chia sẻ
      final buffer = StringBuffer();
      
      // Tiêu đề
      buffer.writeln('🏠 ${room.title}');
      buffer.writeln('');
      
      // Giá
      if (room.priceMillion >= 1) {
        buffer.writeln('💰 Giá: ${room.priceMillion.toStringAsFixed(1)} triệu/tháng');
      } else {
        buffer.writeln('💰 Giá: ${(room.priceMillion * 1000).toStringAsFixed(0)} nghìn/tháng');
      }
      
      // Diện tích
      buffer.writeln('📐 Diện tích: ${room.area.toStringAsFixed(0)} m²');
      
      // Loại phòng
      buffer.writeln('🏘️ ${room.isShared ? "Ở ghép" : "Cho thuê riêng"}');
      buffer.writeln('');
      
      // Địa chỉ
      if (room.address != null && room.address!.isNotEmpty) {
        buffer.write('📍 Địa chỉ: ${room.address}');
        if (room.district.isNotEmpty) {
          buffer.write(', ${room.district}');
        }
        if (room.city.isNotEmpty) {
          buffer.write(', ${room.city}');
        }
        buffer.writeln('');
        buffer.writeln('');
      }
      
      // Mô tả (nếu có)
      if (room.description != null && room.description!.isNotEmpty) {
        buffer.writeln('📝 Mô tả:');
        buffer.writeln(room.description!);
        buffer.writeln('');
      }
      
      // Tiện ích (nếu có)
      if (room.amenities != null && room.amenities!.isNotEmpty) {
        buffer.writeln('✨ Tiện ích:');
        final amenityLabels = room.amenities!.map((a) => _getAmenityLabel(a)).join(', ');
        buffer.writeln(amenityLabels);
        buffer.writeln('');
      }
      
      // Thông tin liên hệ
      if (room.ownerName != null && room.ownerName!.isNotEmpty) {
        buffer.writeln('👤 Người đăng: ${room.ownerName}');
      }
      if (room.ownerPhone != null && room.ownerPhone!.isNotEmpty) {
        buffer.writeln('📞 Liên hệ: ${room.ownerPhone}');
      }
      buffer.writeln('');
      
      // Thông tin app
      buffer.writeln('📱 Tìm thấy trên Nhà Trọ 360');
      
      final shareText = buffer.toString();
      
      // Chia sẻ
      final result = await Share.share(
        shareText,
        subject: room.title,
      );
      
      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã chia sẻ thành công'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi chia sẻ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chia sẻ: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Mở Google Maps để chỉ đường
  Future<void> _openDirections() async {
    final room = widget.room;
    
    try {
      Uri uri;
      
      // Nếu có tọa độ GPS, ưu tiên sử dụng tọa độ
      if (room.latitude != null && room.longitude != null) {
        // Sử dụng Google Maps với tọa độ (chế độ chỉ đường)
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${room.latitude},${room.longitude}',
        );
      } else if (room.address != null && room.address!.isNotEmpty) {
        // Nếu không có tọa độ, sử dụng địa chỉ
        final encodedAddress = Uri.encodeComponent(room.address!);
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có thông tin địa chỉ để chỉ đường'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Mở Google Maps
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Thử với format native: geo:
        if (room.latitude != null && room.longitude != null) {
          final geoUri = Uri.parse('geo:${room.latitude},${room.longitude}');
          if (await canLaunchUrl(geoUri)) {
            await launchUrl(
              geoUri,
              mode: LaunchMode.externalApplication,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không thể mở Google Maps. Vui lòng cài đặt Google Maps.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể mở Google Maps'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi khi mở Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Chuyển đổi amenity code sang label tiếng Việt.
  String _getAmenityLabel(String amenity) {
    switch (amenity) {
      case 'wifi':
        return 'Wifi';
      case 'wc_rieng':
        return 'WC riêng';
      case 'giu_xe':
        return 'Giữ xe';
      case 'tu_do_gio_gac':
        return 'Tự do giờ giấc';
      case 'bep_rieng':
        return 'Bếp riêng';
      case 'dieu_hoa':
        return 'Điều hoà';
      case 'tu_lanh':
        return 'Tủ lạnh';
      case 'may_giat':
        return 'Máy giặt';
      default:
        return amenity.replaceAll('_', ' ');
    }
  }

  /// Chuyển đổi item code sang label tiếng Việt.
  String _getItemLabel(String item) {
    switch (item) {
      case 'giuong':
        return 'Giường';
      case 'tu_quan_ao':
        return 'Tủ quần áo';
      case 'ban_ghe':
        return 'Bàn ghế';
      case 'bep':
        return 'Bếp';
      case 'may_lanh':
        return 'Máy lạnh';
      case 'may_giat':
        return 'Máy giặt';
      case 'tu_lanh':
        return 'Tủ lạnh';
      case 'nem':
        return 'Nệm';
      default:
        return item.replaceAll('_', ' ');
    }
  }

  /// Format thời gian tương đối (ví dụ: "2 giờ trước", "3 ngày trước").
  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Chưa có thông tin';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Đã đăng 1 ngày trước';
      } else if (difference.inDays < 7) {
        return 'Đã đăng ${difference.inDays} ngày trước';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 
            ? 'Đã đăng 1 tuần trước'
            : 'Đã đăng $weeks tuần trước';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 
            ? 'Đã đăng 1 tháng trước'
            : 'Đã đăng $months tháng trước';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 
            ? 'Đã đăng 1 năm trước'
            : 'Đã đăng $years năm trước';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 
          ? 'Đã đăng 1 giờ trước'
          : 'Đã đăng ${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 
          ? 'Đã đăng 1 phút trước'
          : 'Đã đăng ${difference.inMinutes} phút trước';
    } else {
      return 'Vừa đăng';
    }
  }

  /// Lấy danh sách ảnh (ưu tiên images, fallback về thumbnailUrl).
  List<String> _getImageList(Room room) {
    if (room.images != null && room.images!.isNotEmpty) {
      return room.images!;
    }
    // Fallback về thumbnailUrl nếu không có images
    return [room.thumbnailUrl];
  }

  /// Xây dựng image carousel.
  Widget _buildImageCarousel(Room room) {
    final imageList = _getImageList(room);

    if (imageList.length == 1) {
      // Chỉ có 1 ảnh, hiển thị bình thường
      return Image.network(
        imageList[0],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    // Nhiều ảnh, dùng PageView
    return PageView.builder(
      controller: _pageController,
      itemCount: imageList.length,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemBuilder: (context, index) {
        return Image.network(
          imageList[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: theme.colorScheme.primary,
      ),
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}


