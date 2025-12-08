import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet filter diện tích.
class AreaFilterSheet extends StatefulWidget {
  const AreaFilterSheet({
    super.key,
    this.initialMinArea,
  });

  final double? initialMinArea;

  @override
  State<AreaFilterSheet> createState() => _AreaFilterSheetState();
}

class _AreaFilterSheetState extends State<AreaFilterSheet> {
  final double _minRange = 0;
  final double _maxRange = 300; // tối đa 300 m²
  double _minArea = 0;

  @override
  void initState() {
    super.initState();
    _minArea = (widget.initialMinArea ?? 0).clamp(_minRange, _maxRange);
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
            'Diện tích tối thiểu (m²)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Slider
          Slider(
            value: _minArea,
            min: _minRange,
            max: _maxRange,
            divisions: (_maxRange - _minRange).toInt(), // bước 1 m²
            label: '${_minArea.toStringAsFixed(0)} m²',
            onChanged: (v) => setState(() => _minArea = v),
          ),
          const SizedBox(height: 8),
          Text(
            '${_minArea.toStringAsFixed(0)} m²',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop({'clear': true});
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
                      'minArea': _minArea > 0 ? _minArea : null,
                      'maxArea': null,
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

