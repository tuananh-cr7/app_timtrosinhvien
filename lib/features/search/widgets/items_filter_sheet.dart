import 'package:flutter/material.dart';

/// Bottom sheet filter đồ dùng có sẵn.
class ItemsFilterSheet extends StatefulWidget {
  const ItemsFilterSheet({
    super.key,
    this.initialItems = const [],
  });

  final List<String> initialItems;

  @override
  State<ItemsFilterSheet> createState() => _ItemsFilterSheetState();
}

class _ItemsFilterSheetState extends State<ItemsFilterSheet> {
  final Set<String> _selectedItems = {};

  final List<Map<String, String>> _items = [
    {'key': 'giuong', 'label': 'Giường'},
    {'key': 'tu_quan_ao', 'label': 'Tủ quần áo'},
    {'key': 'ban_ghe', 'label': 'Bàn ghế'},
    {'key': 'bep', 'label': 'Bếp'},
    {'key': 'may_lanh', 'label': 'Máy lạnh'},
    {'key': 'may_giat', 'label': 'Máy giặt'},
    {'key': 'tu_lanh', 'label': 'Tủ lạnh'},
    {'key': 'nem', 'label': 'Nệm'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.initialItems);
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
            'Đồ dùng có sẵn',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Items grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _items.map((item) {
              final isSelected = _selectedItems.contains(item['key']);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedItems.remove(item['key']);
                    } else {
                      _selectedItems.add(item['key']!);
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
                    item['label']!,
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
                      _selectedItems.clear();
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
                    Navigator.of(context).pop(_selectedItems.toList());
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

