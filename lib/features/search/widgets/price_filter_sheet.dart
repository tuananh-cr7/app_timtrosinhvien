import 'package:flutter/material.dart';

/// Bottom sheet filter giá phòng.
class PriceFilterSheet extends StatefulWidget {
  const PriceFilterSheet({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  final double? initialMinPrice;
  final double? initialMaxPrice;

  @override
  State<PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<PriceFilterSheet> {
  late double _minPrice;
  late double _maxPrice;
  final double _minRange = 0;
  final double _maxRange = 20; // 20 triệu VND

  @override
  void initState() {
    super.initState();
    _minPrice = widget.initialMinPrice ?? 0;
    _maxPrice = widget.initialMaxPrice ?? 20;
  }

  String _formatPrice(double price) {
    if (price >= 1) {
      return '${price.toStringAsFixed(price % 1 == 0 ? 0 : 1)} Tr đ';
    }
    return '${(price * 1000).toStringAsFixed(0)} K đ';
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
            'Khoảng giá (VND)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Range slider
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: _minRange,
            max: _maxRange,
            divisions: 200, // 0.1 triệu mỗi bước
            labels: RangeLabels(
              _formatPrice(_minPrice),
              _formatPrice(_maxPrice),
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          const SizedBox(height: 8),
          // Price values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatPrice(_minPrice),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatPrice(_maxPrice),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'minPrice': _minPrice,
                      'maxPrice': _maxPrice,
                    });
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

