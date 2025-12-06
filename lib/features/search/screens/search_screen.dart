import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home/data/repositories/rooms_repository.dart';
import '../../home/models/room.dart';
import '../../home/widgets/room_card.dart';
import '../../home/room_detail_screen.dart';
import '../../../core/models/api_result.dart';
import '../widgets/search_filter_bottom_sheet.dart';
import '../widgets/price_filter_sheet.dart';
import '../widgets/amenities_filter_sheet.dart';
import '../widgets/room_type_filter_sheet.dart';
import '../widgets/area_filter_sheet.dart';
import '../widgets/items_filter_sheet.dart';
import '../models/search_filter.dart';
import '../../map/screens/map_search_screen.dart';

/// Màn hình tìm kiếm phòng trọ với filter.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _roomsRepository = RoomsRepository();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  SearchFilter _filter = SearchFilter.empty();
  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false; // Để biết đã search chưa

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      // Update filter với query từ search bar
      final updatedFilter = _filter.copyWith(
        query: _searchController.text.trim(),
      );

      final result = await _roomsRepository.searchRooms(
        city: updatedFilter.city,
        district: updatedFilter.district,
        minPrice: updatedFilter.minPrice,
        maxPrice: updatedFilter.maxPrice,
        minArea: updatedFilter.minArea?.toInt(),
        maxArea: updatedFilter.maxArea?.toInt(),
        isShared: updatedFilter.isShared,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          switch (result) {
            case ApiSuccess<List<Room>>(data: final rooms):
              var filteredRooms = rooms;

              // Local filter: Query, amenities, availableItems, roomType
              if (updatedFilter.query.isNotEmpty) {
                final queryLower = updatedFilter.query.toLowerCase();
                filteredRooms = filteredRooms.where((room) {
                  return room.title.toLowerCase().contains(queryLower) ||
                      room.address.toLowerCase().contains(queryLower) ||
                      (room.description?.toLowerCase().contains(queryLower) ?? false);
                }).toList();
              }

              // Filter amenities
              if (updatedFilter.amenities.isNotEmpty) {
                filteredRooms = filteredRooms.where((room) {
                  final roomAmenities = room.amenities ?? [];
                  return updatedFilter.amenities
                      .every((amenity) => roomAmenities.contains(amenity));
                }).toList();
              }

              // Filter availableItems
              if (updatedFilter.availableItems.isNotEmpty) {
                filteredRooms = filteredRooms.where((room) {
                  final roomItems = room.availableItems ?? [];
                  return updatedFilter.availableItems
                      .every((item) => roomItems.contains(item));
                }).toList();
              }

              _rooms = filteredRooms;
              break;
            case ApiError<List<Room>>(message: final message):
              _errorMessage = message;
              _rooms = [];
              break;
            case ApiLoading<List<Room>>():
              // Không nên xảy ra ở đây
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _rooms = [];
        });
      }
    }
  }

  Future<void> _openPriceFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PriceFilterSheet(
        initialMinPrice: _filter.minPrice,
        initialMaxPrice: _filter.maxPrice,
      ),
    );

    if (result != null) {
      setState(() {
        _filter = _filter.copyWith(
          minPrice: result['minPrice'] as double?,
          maxPrice: result['maxPrice'] as double?,
        );
      });
      _performSearch();
    }
  }

  Future<void> _openAmenitiesFilter() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AmenitiesFilterSheet(
        initialAmenities: _filter.amenities,
      ),
    );

    if (result != null) {
      setState(() {
        _filter = _filter.copyWith(amenities: result);
      });
      _performSearch();
    }
  }

  Future<void> _openRoomTypeFilter() async {
    final result = await showModalBottomSheet<RoomTypeFilter?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RoomTypeFilterSheet(
        initialRoomType: _filter.roomType,
      ),
    );

    if (result != null) {
      setState(() {
        _filter = _filter.copyWith(roomType: result);
      });
      _performSearch();
    }
  }

  Future<void> _openAreaFilter() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AreaFilterSheet(
        initialMinArea: _filter.minArea,
        initialMaxArea: _filter.maxArea,
      ),
    );

    if (result != null) {
      setState(() {
        _filter = _filter.copyWith(
          minArea: result['minArea'] as double?,
          maxArea: result['maxArea'] as double?,
        );
      });
      _performSearch();
    }
  }

  Future<void> _openItemsFilter() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ItemsFilterSheet(
        initialItems: _filter.availableItems,
      ),
    );

    if (result != null) {
      setState(() {
        _filter = _filter.copyWith(availableItems: result);
      });
      _performSearch();
    }
  }

  Future<void> _openNumberOfPeopleFilter() async {
    // TODO: Implement number of people filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng lọc theo số người đang phát triển')),
    );
  }

  void _openMapSearch() {
      Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapSearchScreen(),
      ),
    );
  }

  void _openLocationPicker() {
    // TODO: Open location picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng chọn địa điểm đang phát triển')),
    );
  }

  void _openLocationBasedFilter() {
    // TODO: Open location-based filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng lọc theo vị trí đang phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Tìm kiếm phòng trọ',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    'Chọn từ khóa và bộ lọc để tìm phòng phù hợp',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Map search button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openMapSearch,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Tìm bằng bản đồ'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, địa chỉ...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16),
                  // Quick filter buttons row 1
                  Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.attach_money_outlined,
                          label: _filter.minPrice != null || _filter.maxPrice != null
                              ? 'Giá: ${_filter.minPrice?.toStringAsFixed(1) ?? '0'}-${_filter.maxPrice?.toStringAsFixed(1) ?? '∞'} Tr'
                              : 'Giá',
                          isActive: _filter.minPrice != null || _filter.maxPrice != null,
                          onTap: _openPriceFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.star_outline,
                          label: _filter.amenities.isNotEmpty
                              ? 'Tiện ích (${_filter.amenities.length})'
                              : 'Tiện ích',
                          isActive: _filter.amenities.isNotEmpty,
                          onTap: _openAmenitiesFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.home_outlined,
                          label: _filter.roomType != null
                              ? _filter.roomType!.displayName
                              : 'Loại phòng',
                          isActive: _filter.roomType != null,
                          onTap: _openRoomTypeFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.people_outline,
                          label: 'Số người',
                          onTap: _openNumberOfPeopleFilter,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick filter buttons row 2
                  Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.location_on_outlined,
                          label: _filter.city != null || _filter.district != null
                              ? '${_filter.city ?? ''}${_filter.district != null ? ', ${_filter.district}' : ''}'
                              : 'Chọn địa điểm',
                          isActive: _filter.city != null || _filter.district != null,
                          onTap: _openLocationPicker,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.square_foot_outlined,
                          label: _filter.minArea != null || _filter.maxArea != null
                              ? 'Diện tích: ${_filter.minArea?.toStringAsFixed(0) ?? '0'}-${_filter.maxArea?.toStringAsFixed(0) ?? '∞'} m²'
                              : 'Diện tích',
                          isActive: _filter.minArea != null || _filter.maxArea != null,
                          onTap: _openAreaFilter,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick filter buttons row 3
                  Row(
                    children: [
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.chair_outlined,
                          label: _filter.availableItems.isNotEmpty
                              ? 'Đồ dùng (${_filter.availableItems.length})'
                              : 'Đồ dùng',
                          isActive: _filter.availableItems.isNotEmpty,
                          onTap: _openItemsFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          icon: Icons.my_location_outlined,
                          label: 'Theo vị trí',
                          onTap: _openLocationBasedFilter,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Results Section
            Expanded(
              child: _buildResults(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    // Nếu chưa search, hiển thị empty state
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa hoặc chọn bộ lọc để tìm kiếm',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy phòng trọ nào',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RoomDetailScreen(room: room),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RoomCard(room: room),
            ),
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? theme.colorScheme.primary
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.grey.shade700,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 18,
              color: isActive
                  ? theme.colorScheme.primary
                  : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}
