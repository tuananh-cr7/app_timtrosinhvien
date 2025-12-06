import 'package:flutter/material.dart';
import '../models/search_filter.dart';

/// Bottom sheet filter loại phòng.
class RoomTypeFilterSheet extends StatefulWidget {
  const RoomTypeFilterSheet({
    super.key,
    this.initialRoomType,
  });

  final RoomTypeFilter? initialRoomType;

  @override
  State<RoomTypeFilterSheet> createState() => _RoomTypeFilterSheetState();
}

class _RoomTypeFilterSheetState extends State<RoomTypeFilterSheet> {
  RoomTypeFilter? _selectedRoomType;

  @override
  void initState() {
    super.initState();
    _selectedRoomType = widget.initialRoomType;
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
            'Loại phòng',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Room type options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: RoomTypeFilter.values.map((type) {
              final isSelected = _selectedRoomType == type;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRoomType = isSelected ? null : type;
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
                    type.displayName,
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
                      _selectedRoomType = null;
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
                    Navigator.of(context).pop(_selectedRoomType);
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

