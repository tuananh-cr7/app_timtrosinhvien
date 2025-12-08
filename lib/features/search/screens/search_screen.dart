import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

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
import '../widgets/people_filter_sheet.dart';
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
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<String> _searchHistory = [];
  SearchFilter _filter = SearchFilter.empty();
  List<Room> _rooms = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  bool _hasSearched = false; // Để biết đã search chưa
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initSpeech();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          print('🎙️ Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mic lỗi: ${error.errorMsg}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onStatus: (status) {
          print('🎙️ Speech status: $status');
        },
      );
      if (!_speechAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể dùng mic. Kiểm tra quyền microphone.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('🎙️ Không thể khởi tạo speech_to_text: $e');
      _speechAvailable = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể khởi tạo mic: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('search_history') ?? [];
    setState(() {
      _searchHistory
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _saveQueryToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > 10) {
      _searchHistory.removeRange(10, _searchHistory.length);
    }
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _removeHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(item);
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.clear();
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _startListening() async {
    // Khởi tạo và xin quyền mỗi lần bấm mic
    final available = await _speech.initialize(
      onError: (error) {
        print('🎙️ Speech error: $error');
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      onStatus: (status) => print('🎙️ Speech status: $status'),
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể dùng mic. Kiểm tra quyền microphone.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ứng dụng cần quyền Microphone. Vào Cài đặt > Quyền > bật Microphone.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    setState(() {
      _isListening = true;
    });
    await _speech.listen(
      localeId: 'vi_VN',
      onResult: (result) {
        final text = result.recognizedWords;
        if (text.isNotEmpty) {
          _searchController.text = text;
          _searchController.selection = TextSelection.collapsed(offset: text.length);
        }
        if (result.finalResult) {
          _stopListening(triggerSearch: true);
        }
      },
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
    );
  }

  Future<void> _stopListening({bool triggerSearch = false}) async {
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      if (triggerSearch) {
        _performSearch();
      }
    }
  }

  String _normalize(String input) {
    // Loại bỏ dấu tiếng Việt để so khớp không dấu
    const withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIUUUUUUUUUUUYYYYYD';
    var result = input;
    for (int i = 0; i < withDiacritics.length && i < withoutDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result.toLowerCase();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore && _hasSearched) {
        _loadMoreRooms();
      }
    }
  }

  void _clearAllFilters() {
    setState(() {
      _filter = SearchFilter.empty();
      _searchController.clear();
      _rooms = [];
      _hasSearched = false;
      _errorMessage = null;
      _isLoading = false;
      _isLoadingMore = false;
      _hasMore = true;
      _currentPage = 0;
    });
  }

  Future<void> _performSearch({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hasSearched = true;
        _rooms = [];
        _currentPage = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

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
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          switch (result) {
            case ApiSuccess<List<Room>>(data: final rooms):
              var filteredRooms = rooms;

              // Local filter: Query (không dấu), amenities, availableItems, roomType, price
              if (updatedFilter.query.isNotEmpty) {
                final queryNorm = _normalize(updatedFilter.query);
                filteredRooms = filteredRooms.where((room) {
                  final title = _normalize(room.title);
                  final address = _normalize(room.address);
                  final desc = _normalize(room.description ?? '');
                  return title.contains(queryNorm) ||
                      address.contains(queryNorm) ||
                      desc.contains(queryNorm);
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

              // Filter price local (đảm bảo không lọt giá thấp)
              if (updatedFilter.minPrice != null) {
                filteredRooms = filteredRooms.where((room) {
                  return room.priceMillion >= updatedFilter.minPrice!;
                }).toList();
              }
              if (updatedFilter.maxPrice != null) {
                filteredRooms = filteredRooms.where((room) {
                  return room.priceMillion <= updatedFilter.maxPrice!;
                }).toList();
              }

              // Filter maxPeople (nếu dữ liệu có)
              if (updatedFilter.maxPeople != null) {
                filteredRooms = filteredRooms.where((room) {
                  if (room.maxPeople == null) return true; // không có dữ liệu thì không lọc
                  return room.maxPeople! <= updatedFilter.maxPeople!;
                }).toList();
              }

              // Filter room type local
              if (updatedFilter.roomType != null) {
                final key = switch (updatedFilter.roomType!) {
                  RoomTypeFilter.room => 'room',
                  RoomTypeFilter.apartment => 'apartment',
                  RoomTypeFilter.miniApartment => 'mini_apartment',
                  RoomTypeFilter.entirePlace => 'entire_place',
                };
                filteredRooms = filteredRooms.where((room) {
                  final type = (room.roomType ?? '').toLowerCase();
                  final display = updatedFilter.roomType!.displayName.toLowerCase();
                  return type == key || type == display;
                }).toList();
              }

              if (reset) {
                _rooms = filteredRooms;
              } else {
                _rooms.addAll(filteredRooms);
              }
              
              _hasMore = filteredRooms.length >= _pageSize;
              _currentPage++;
              _saveQueryToHistory(updatedFilter.query);
              break;
            case ApiError<List<Room>>(message: final message):
              _errorMessage = message;
              if (reset) {
                _rooms = [];
              }
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
          _isLoadingMore = false;
          _errorMessage = e.toString();
          if (reset) {
            _rooms = [];
          }
        });
      }
    }
  }

  Future<void> _loadMoreRooms() async {
    if (_isLoadingMore || !_hasMore) return;
    await _performSearch(reset: false);
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
      if (result is Map && result['clear'] == true) {
        setState(() {
          _filter = _filter.copyWith(
            clearMinPrice: true,
            clearMaxPrice: true,
          );
        });
        _performSearch();
      } else {
        setState(() {
          _filter = _filter.copyWith(
            minPrice: result['minPrice'] as double?,
            maxPrice: result['maxPrice'] as double?,
          );
        });
        _performSearch();
      }
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
      ),
    );

    if (result != null) {
      if (result['clear'] == true) {
        setState(() {
          _filter = _filter.copyWith(clearMinArea: true, clearMaxArea: true);
        });
        _performSearch();
      } else {
        setState(() {
          _filter = _filter.copyWith(
            minArea: result['minArea'] as double?,
            maxArea: result['maxArea'] as double?, // sẽ là null trong sheet mới
          );
        });
        _performSearch();
      }
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PeopleFilterSheet(
        initialMax: _filter.maxPeople,
      ),
    );

    if (result != null) {
      if (result['clear'] == true) {
        setState(() {
          _filter = _filter.copyWith(clearMaxPeople: true);
        });
        _performSearch();
      } else if (result['max'] != null) {
        setState(() {
          _filter = _filter.copyWith(maxPeople: result['max'] as int);
        });
        _performSearch();
      }
    }
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
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
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              ),
                            IconButton(
                              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                              color: _isListening ? Colors.red : null,
                              onPressed: _isListening ? () => _stopListening() : _startListening,
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 16),
                    // Search history
                    if (_searchHistory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tìm kiếm gần đây',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_filter.hasFilters || _searchController.text.isNotEmpty)
                                      TextButton(
                                        onPressed: _clearAllFilters,
                                        child: const Text('Xóa bộ lọc'),
                                      ),
                                    TextButton(
                                      onPressed: _clearHistory,
                                      child: const Text('Xóa hết'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _searchHistory.map((item) {
                                return InputChip(
                                  label: Text(item),
                                  onPressed: () {
                                    _searchController.text = item;
                                    _searchController.selection = TextSelection.collapsed(offset: item.length);
                                    _performSearch();
                                  },
                                  onDeleted: () => _removeHistoryItem(item),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    // Quick filter buttons row 1
                    Row(
                      children: [
                        Expanded(
                          child: _FilterButton(
                          label: _filter.minPrice != null
                              ? 'Giá từ ${_filter.minPrice!.toStringAsFixed(1)} Tr'
                              : 'Giá',
                          isActive: _filter.minPrice != null,
                            onTap: _openPriceFilter,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterButton(
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
                            label: 'Số người',
                          isActive: _filter.maxPeople != null,
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
                          label: _filter.minArea != null || _filter.maxArea != null
                              ? 'Diện tích: ${_filter.minArea?.toStringAsFixed(0) ?? '0'}-${_filter.maxArea?.toStringAsFixed(0) ?? '∞'} m²'
                              : 'Diện tích',
                          isActive: _filter.minArea != null || _filter.maxArea != null,
                          onTap: _openAreaFilter,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterButton(
                          label: _filter.availableItems.isNotEmpty
                              ? 'Đồ dùng (${_filter.availableItems.length})'
                              : 'Đồ dùng',
                          isActive: _filter.availableItems.isNotEmpty,
                          onTap: _openItemsFilter,
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: _buildResults(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Nếu chưa search, hiển thị empty state
    if (!_hasSearched) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: 32, bottom: bottomInset + 32),
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
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: 32, bottom: bottomInset + 32),
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
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: 32, bottom: bottomInset + 32),
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
      onRefresh: () => _performSearch(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length + (_hasMore ? 1 : 0),
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
    required this.label,
    required this.onTap,
    this.icon,
    this.isActive = false,
  });

  final IconData? icon;
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
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? theme.colorScheme.primary
                    : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
            ],
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
