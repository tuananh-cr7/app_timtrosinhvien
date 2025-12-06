import 'package:flutter/material.dart';

import '../models/api_result.dart';

/// Widget hiển thị loading/error state với retry mechanism.
class LoadingErrorWidget<T> extends StatelessWidget {
  const LoadingErrorWidget({
    super.key,
    required this.result,
    required this.onRetry,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
  });

  final ApiResult<T> result;
  final VoidCallback onRetry;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (result.isLoading) {
      return loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (result.isError) {
      return errorWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã xảy ra lỗi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.errorMessage ?? 'Vui lòng thử lại',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
    }

    return child;
  }
}

