import 'package:flutter/material.dart';

/// Bottom sheet filter tiện ích.
class AmenitiesFilterSheet extends StatefulWidget {
  const AmenitiesFilterSheet({
    super.key,
    this.initialAmenities = const [],
  });

  final List<String> initialAmenities;

  @override
  State<AmenitiesFilterSheet> createState() => _AmenitiesFilterSheetState();
}

class _AmenitiesFilterSheetState extends State<AmenitiesFilterSheet> {
  final Set<String> _selectedAmenities = {};

  final List<Map<String, String>> _amenities = [
    {'key': 'wifi', 'label': 'Wifi'},
    {'key': 'wc_rieng', 'label': 'WC riêng'},
    {'key': 'giu_xe', 'label': 'Giữ xe'},
    {'key': 'tu_do_gio_gac', 'label': 'Tự do giờ giấc'},
    {'key': 'bep_rieng', 'label': 'Bếp riêng'},
    {'key': 'dieu_hoa', 'label': 'Điều hoà'},
    {'key': 'tu_lanh', 'label': 'Tủ lạnh'},
    {'key': 'may_giat', 'label': 'Máy giặt'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAmenities.addAll(widget.initialAmenities);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Text(
            'Tiện ích',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Amenities grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _amenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity['key']);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAmenities.remove(amenity['key']);
                    } else {
                      _selectedAmenities.add(amenity['key']!);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : Colors.grey.shade100,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    amenity['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAmenities.clear();
                    });
                  },
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedAmenities.toList());
                  },
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

