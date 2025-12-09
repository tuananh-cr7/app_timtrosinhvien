import 'package:flutter/material.dart';

/// Bottom sheet chọn số người tối đa (1-6).
class PeopleFilterSheet extends StatefulWidget {
  const PeopleFilterSheet({super.key, this.initialMax});

  final int? initialMax;

  @override
  State<PeopleFilterSheet> createState() => _PeopleFilterSheetState();
}

class _PeopleFilterSheetState extends State<PeopleFilterSheet> {
  double _value = 1;
  final double _min = 1;
  final double _max = 6;

  @override
  void initState() {
    super.initState();
    _value = (widget.initialMax ?? 6).toDouble().clamp(_min, _max);
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
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Số người tối đa',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _value,
            min: _min,
            max: _max,
            divisions: (_max - _min).toInt(),
            label: '${_value.toInt()} người',
            onChanged: (v) => setState(() => _value = v),
          ),
          const SizedBox(height: 8),
          Text(
            '${_value.toInt()} người',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
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
                    Navigator.of(context).pop({'max': _value.toInt()});
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


