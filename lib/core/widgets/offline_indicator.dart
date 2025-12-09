import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Widget hiển thị indicator khi offline.
class OfflineIndicator extends StatelessWidget {
  final ConnectivityService connectivityService;

  const OfflineIndicator({
    super.key,
    required this.connectivityService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: connectivityService,
      builder: (context, _) {
        if (connectivityService.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.orange.shade700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Không có kết nối internet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

