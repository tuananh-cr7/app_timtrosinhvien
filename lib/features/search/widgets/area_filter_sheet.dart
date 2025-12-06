import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet filter diện tích.
class AreaFilterSheet extends StatefulWidget {
  const AreaFilterSheet({
    super.key,
    this.initialMinArea,
    this.initialMaxArea,
  });

  final double? initialMinArea;
  final double? initialMaxArea;

  @override
  State<AreaFilterSheet> createState() => _AreaFilterSheetState();
}

class _AreaFilterSheetState extends State<AreaFilterSheet> {
  final _minAreaController = TextEditingController();
  final _maxAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _minAreaController.text = widget.initialMinArea?.toStringAsFixed(0) ?? '';
    _maxAreaController.text = widget.initialMaxArea?.toStringAsFixed(0) ?? '';
  }

  @override
  void dispose() {
    _minAreaController.dispose();
    _maxAreaController.dispose();
    super.dispose();
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
            'Diện tích (m²)',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Input fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAreaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
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
                    FilteringTextInputFormatter.digitsOnly,
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
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _minAreaController.clear();
                    _maxAreaController.clear();
                    setState(() {});
                  },
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    final minArea = double.tryParse(_minAreaController.text);
                    final maxArea = double.tryParse(_maxAreaController.text);
                    Navigator.of(context).pop({
                      'minArea': minArea,
                      'maxArea': maxArea,
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

