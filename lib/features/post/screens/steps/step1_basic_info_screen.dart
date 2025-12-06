import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/room_draft.dart';

class Step1BasicInfoScreen extends StatefulWidget {
  final RoomDraft draft;
  final Function(RoomDraft) onNext;

  const Step1BasicInfoScreen({
    super.key,
    required this.draft,
    required this.onNext,
  });

  @override
  State<Step1BasicInfoScreen> createState() => _Step1BasicInfoScreenState();
}

class _Step1BasicInfoScreenState extends State<Step1BasicInfoScreen> {
  late PostType _postType;
  late RoomType _roomType;
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final Set<String> _selectedAmenities = {};

  @override
  void initState() {
    super.initState();
    _postType = widget.draft.postType;
    _roomType = widget.draft.roomType;
    // Format giá với dấu chấm phân cách
    if (widget.draft.price > 0) {
      _priceController.text = _formatNumber(widget.draft.price.toInt());
    }
    _areaController.text = widget.draft.area > 0
        ? widget.draft.area.toStringAsFixed(0)
        : '';
    _selectedAmenities.addAll(widget.draft.amenities);
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
  }

  void _handleNext() {
    // Parse price: bỏ dấu chấm phân cách
    final priceText = _priceController.text.replaceAll('.', '');
    final price = double.tryParse(priceText) ?? 0;
    final area = double.tryParse(_areaController.text) ?? 0;

    // Validation hợp lý
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá phòng')),
      );
      return;
    }

    if (price < 500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá phòng tối thiểu là 500,000 VND')),
      );
      return;
    }

    if (price > 100000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá phòng tối đa là 100,000,000 VND')),
      );
      return;
    }

    if (area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập diện tích')),
      );
      return;
    }

    if (area < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diện tích tối thiểu là 5 m²')),
      );
      return;
    }

    if (area > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diện tích tối đa là 500 m²')),
      );
      return;
    }

    final updatedDraft = RoomDraft(
      postType: _postType,
      roomType: _roomType,
      price: price,
      area: area,
      amenities: _selectedAmenities.toList(),
      city: widget.draft.city,
      district: widget.draft.district,
      ward: widget.draft.ward,
      streetName: widget.draft.streetName,
      houseNumber: widget.draft.houseNumber,
      directions: widget.draft.directions,
      latitude: widget.draft.latitude,
      longitude: widget.draft.longitude,
      images: widget.draft.images,
      title: widget.draft.title,
      description: widget.draft.description,
      contactName: widget.draft.contactName,
      contactPhone: widget.draft.contactPhone,
      availableItems: widget.draft.availableItems,
    );

    widget.onNext(updatedDraft);
  }

  String _formatPriceText(String priceText) {
    if (priceText.isEmpty) return '';
    // Bỏ dấu chấm để parse
    final price = double.tryParse(priceText.replaceAll('.', '')) ?? 0;
    if (price < 1000) {
      return '${price.toStringAsFixed(0)} nghìn';
    } else if (price < 1000000) {
      return '${(price / 1000).toStringAsFixed(0)} nghìn';
    } else {
      return '${(price / 1000000).toStringAsFixed(1)} triệu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Loại tin
                  Text(
                    'Loại tin',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPostTypeButton(
                          PostType.forRent,
                          'Cho thuê',
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPostTypeButton(
                          PostType.findRoommate,
                          'Tìm ở ghép',
                          null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Loại phòng
                  Text(
                    'Loại phòng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoomTypeButton(RoomType.room, 'Phòng'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRoomTypeButton(
                          RoomType.apartment,
                          'Căn hộ',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoomTypeButton(
                          RoomType.miniApartment,
                          'Căn hộ mini',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRoomTypeButton(
                          RoomType.entirePlace,
                          'Nguyên căn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Giá phòng
                  Text(
                    'Giá phòng (VND)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      _ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Nhập giá phòng',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  if (_priceController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatPriceText(_priceController.text),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Diện tích
                  Text(
                    'Diện tích (m²)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Nhập diện tích',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tiện ích
                  Text(
                    'Tiện ích',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAmenityChip('wifi', 'Wifi'),
                      _buildAmenityChip('wc_rieng', 'WC riêng'),
                      _buildAmenityChip('giu_xe', 'Giữ xe'),
                      _buildAmenityChip('tu_do_gio_gac', 'Tự do giờ giấc'),
                      _buildAmenityChip('bep_rieng', 'Bếp riêng'),
                      _buildAmenityChip('dieu_hoa', 'Điều hoà'),
                      _buildAmenityChip('tu_lanh', 'Tủ lạnh'),
                      _buildAmenityChip('may_giat', 'Máy giặt'),
                    ],
                  ),
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
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Huỷ'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _handleNext,
                    child: const Text('Tiếp theo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTypeButton(
    PostType type,
    String label,
    IconData? icon,
  ) {
    final isSelected = _postType == type;
    return InkWell(
      onTap: () => setState(() => _postType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected && icon != null)
              Icon(icon, color: Colors.white, size: 20),
            if (isSelected && icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeButton(RoomType type, String label) {
    final isSelected = _roomType == type;
    return InkWell(
      onTap: () => setState(() => _roomType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String amenity, String label) {
    final isSelected = _selectedAmenities.contains(amenity);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleAmenity(amenity),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// TextInputFormatter để format số với dấu chấm phân cách hàng nghìn.
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Chỉ cho phép số
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format với dấu chấm phân cách hàng nghìn
    final formatted = _formatWithSeparator(text);
    
    // Tính toán vị trí cursor mới
    final oldLength = oldValue.text.replaceAll('.', '').length;
    final newLength = formatted.replaceAll('.', '').length;
    final offset = formatted.length - (oldValue.text.length - oldValue.selection.extentOffset);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: math.max(0, math.min(offset, formatted.length))),
    );
  }

  String _formatWithSeparator(String value) {
    if (value.isEmpty) return '';
    
    // Đảo ngược chuỗi để thêm dấu chấm từ phải sang trái
    final reversed = value.split('').reversed.join();
    final buffer = StringBuffer();
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(reversed[i]);
    }
    
    // Đảo ngược lại
    return buffer.toString().split('').reversed.join();
  }
}

