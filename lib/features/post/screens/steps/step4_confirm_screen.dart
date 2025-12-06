import 'package:flutter/material.dart';
import '../../models/room_draft.dart';

class Step4ConfirmScreen extends StatefulWidget {
  final RoomDraft draft;
  final VoidCallback onBack;
  final Function(RoomDraft) onComplete; // Thay đổi để nhận draft đã cập nhật

  const Step4ConfirmScreen({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onComplete,
  });

  @override
  State<Step4ConfirmScreen> createState() => _Step4ConfirmScreenState();
}

class _Step4ConfirmScreenState extends State<Step4ConfirmScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.draft.title;
    _descriptionController.text = widget.draft.description;
    _contactNameController.text = widget.draft.contactName;
    _contactPhoneController.text = widget.draft.contactPhone;
    _selectedItems.addAll(widget.draft.availableItems);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _toggleItem(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  bool _isValidPhone(String phone) {
    // Validate số điện thoại Việt Nam: 10 số, bắt đầu bằng 0 hoặc +84
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 10 && cleaned.startsWith('0') ||
        cleaned.length == 11 && cleaned.startsWith('84');
  }

  void _handleComplete() {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề bài đăng')),
      );
      return;
    }

    if (_titleController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiêu đề phải có ít nhất 10 ký tự')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mô tả chi tiết')),
      );
      return;
    }

    if (_contactNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên liên hệ')),
      );
      return;
    }

    final phone = _contactPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại liên hệ')),
      );
      return;
    }

    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số điện thoại không hợp lệ. Vui lòng nhập 10 số bắt đầu bằng 0'),
        ),
      );
      return;
    }

    // Cập nhật draft với thông tin từ Step 4
    final updatedDraft = RoomDraft(
      postType: widget.draft.postType,
      roomType: widget.draft.roomType,
      price: widget.draft.price,
      area: widget.draft.area,
      amenities: widget.draft.amenities,
      city: widget.draft.city,
      district: widget.draft.district,
      ward: widget.draft.ward,
      streetName: widget.draft.streetName,
      houseNumber: widget.draft.houseNumber,
      directions: widget.draft.directions,
      latitude: widget.draft.latitude,
      longitude: widget.draft.longitude,
      images: widget.draft.images,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      contactName: _contactNameController.text.trim(),
      contactPhone: phone.replaceAll(RegExp(r'[^\d]'), ''), // Chỉ lưu số
      availableItems: _selectedItems.toList(),
    );

    // Gọi callback với draft đã cập nhật
    widget.onComplete(updatedDraft);
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} triệu';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} nghìn';
    }
    return price.toStringAsFixed(0);
  }

  String _buildAddress() {
    final parts = <String>[];
    if (widget.draft.houseNumber.isNotEmpty) {
      parts.add(widget.draft.houseNumber);
    }
    if (widget.draft.ward.isNotEmpty) {
      parts.add(widget.draft.ward);
    }
    if (widget.draft.district.isNotEmpty) {
      parts.add(widget.draft.district);
    }
    if (widget.draft.city.isNotEmpty) {
      parts.add(widget.draft.city);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Chưa có địa chỉ';
  }

  String _getAmenityName(String amenity) {
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
                  // Tiêu đề bài đăng
                  Text(
                    'Tiêu đề bài đăng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập tiêu đề bài đăng',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mô tả chi tiết
                  Text(
                    'Mô tả chi tiết',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Mô tả chi tiết về phòng trọ',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tên liên hệ
                  Text(
                    'Tên liên hệ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập tên liên hệ',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Số điện thoại liên hệ
                  Text(
                    'Số điện thoại liên hệ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Nhập số điện thoại',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Đồ dùng có sẵn
                  Text(
                    'Đồ dùng có sẵn',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildItemChip('giuong', 'Giường'),
                      _buildItemChip('tu_quan_ao', 'Tủ quần áo'),
                      _buildItemChip('ban_ghe', 'Bàn ghế'),
                      _buildItemChip('bep', 'Bếp'),
                      _buildItemChip('may_lanh', 'Máy lạnh'),
                      _buildItemChip('may_giat', 'Máy giặt'),
                      _buildItemChip('tu_lanh', 'Tủ lạnh'),
                      _buildItemChip('nem', 'Nệm'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tóm tắt
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tóm tắt',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Loại tin', widget.draft.postType.displayName),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Loại phòng', widget.draft.roomType.displayName),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Giá', '${_formatPrice(widget.draft.price)} /tháng'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Diện tích', '${widget.draft.area.toStringAsFixed(0)} m²'),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Địa chỉ',
                          _buildAddress(),
                        ),
                        if (widget.draft.amenities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Tiện ích',
                            widget.draft.amenities
                                .map((a) => _getAmenityName(a))
                                .join(', '),
                          ),
                        ],
                        if (_selectedItems.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Đồ dùng có sẵn',
                            _selectedItems
                                .map((item) => _getItemName(item))
                                .join(', '),
                          ),
                        ],
                        if (widget.draft.images.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Hình ảnh',
                            '${widget.draft.images.length} hình',
                          ),
                        ],
                      ],
                    ),
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
                    onPressed: widget.onBack,
                    child: const Text('Quay lại'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _handleComplete,
                    child: const Text('Đăng tin'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemChip(String item, String label) {
    final isSelected = _selectedItems.contains(item);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleItem(item),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  /// Chuyển đổi item code sang tên tiếng Việt.
  String _getItemName(String item) {
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
}

