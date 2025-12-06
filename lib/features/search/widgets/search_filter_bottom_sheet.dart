import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/search_filter.dart';

/// Bottom sheet bộ lọc tìm kiếm.
class SearchFilterBottomSheet extends StatefulWidget {
  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilter,
  });

  final SearchFilter initialFilter;

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilter _filter;

  // Controllers
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();

  // Selected values
  String? _selectedCity;
  String? _selectedDistrict;
  bool? _selectedIsShared;
  final Set<String> _selectedAmenities = {};
  final Set<String> _selectedAvailableItems = {};
  RoomTypeFilter? _selectedRoomType;

  // Options
  final List<String> _cities = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
  ];

  final List<String> _amenities = [
    'wifi',
    'wc_rieng',
    'giu_xe',
    'tu_do_gio_gac',
    'bep_rieng',
    'dieu_hoa',
    'tu_lanh',
    'may_giat',
  ];

  final List<String> _availableItems = [
    'giuong',
    'tu_quan_ao',
    'ban_ghe',
    'bep',
    'may_lanh',
    'may_giat',
    'tu_lanh',
    'nem',
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _loadInitialValues();
  }

  void _loadInitialValues() {
    _selectedCity = _filter.city;
    _selectedDistrict = _filter.district;
    _selectedIsShared = _filter.isShared;
    _selectedAmenities.addAll(_filter.amenities);
    _selectedAvailableItems.addAll(_filter.availableItems);
    _selectedRoomType = _filter.roomType;

    _minPriceController.text = _filter.minPrice?.toString() ?? '';
    _maxPriceController.text = _filter.maxPrice?.toString() ?? '';
    _minAreaController.text = _filter.minArea?.toString() ?? '';
    _maxAreaController.text = _filter.maxArea?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final minPrice = double.tryParse(_minPriceController.text);
    final maxPrice = double.tryParse(_maxPriceController.text);
    final minArea = double.tryParse(_minAreaController.text);
    final maxArea = double.tryParse(_maxAreaController.text);

    final updatedFilter = _filter.copyWith(
      city: _selectedCity,
      district: _selectedDistrict,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minArea: minArea,
      maxArea: maxArea,
      isShared: _selectedIsShared,
      amenities: _selectedAmenities.toList(),
      availableItems: _selectedAvailableItems.toList(),
      roomType: _selectedRoomType,
    );

    Navigator.of(context).pop(updatedFilter);
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedIsShared = null;
      _selectedAmenities.clear();
      _selectedAvailableItems.clear();
      _selectedRoomType = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minAreaController.clear();
      _maxAreaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bộ lọc',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Đặt lại'),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Giá
                    _buildSection(
                      theme,
                      'Giá phòng (triệu VND/tháng)',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Từ',
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Đến',
                                  hintText: '100',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Diện tích
                    _buildSection(
                      theme,
                      'Diện tích (m²)',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minAreaController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Từ',
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxAreaController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Đến',
                                  hintText: '500',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Loại tin
                    _buildSection(
                      theme,
                      'Loại tin',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceChip(
                                'Tất cả',
                                _selectedIsShared == null,
                                () => setState(() => _selectedIsShared = null),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceChip(
                                'Cho thuê riêng',
                                _selectedIsShared == false,
                                () => setState(() => _selectedIsShared = false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildChoiceChip(
                                'Ở ghép',
                                _selectedIsShared == true,
                                () => setState(() => _selectedIsShared = true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Loại phòng
                    _buildSection(
                      theme,
                      'Loại phòng',
                      [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: RoomTypeFilter.values.map((type) {
                            return _buildChoiceChip(
                              type.displayName,
                              _selectedRoomType == type,
                              () => setState(() {
                                _selectedRoomType =
                                    _selectedRoomType == type ? null : type;
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Thành phố
                    _buildSection(
                      theme,
                      'Thành phố',
                      [
                        DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Chọn thành phố',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Tất cả'),
                            ),
                            ..._cities.map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCity = value;
                              _selectedDistrict = null; // Reset district khi đổi city
                            });
                          },
                        ),
                      ],
                    ),
                    // Quận/Huyện
                    _buildSection(
                      theme,
                      'Quận/Huyện',
                      [
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _selectedDistrict = value.isEmpty ? null : value;
                            });
                          },
                          controller: TextEditingController(text: _selectedDistrict ?? ''),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Nhập quận/huyện',
                          ),
                        ),
                      ],
                    ),
                    // Tiện ích
                    _buildSection(
                      theme,
                      'Tiện ích',
                      [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _amenities.map((amenity) {
                            final label = _getAmenityLabel(amenity);
                            return FilterChip(
                              label: Text(label),
                              selected: _selectedAmenities.contains(amenity),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAmenities.add(amenity);
                                  } else {
                                    _selectedAmenities.remove(amenity);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Đồ dùng có sẵn
                    _buildSection(
                      theme,
                      'Đồ dùng có sẵn',
                      [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableItems.map((item) {
                            final label = _getItemLabel(item);
                            return FilterChip(
                              label: Text(label),
                              selected: _selectedAvailableItems.contains(item),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAvailableItems.add(item);
                                  } else {
                                    _selectedAvailableItems.remove(item);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _applyFilters,
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

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
        return amenity;
    }
  }

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
        return item;
    }
  }
}

