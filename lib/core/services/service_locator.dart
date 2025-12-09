import 'connectivity_service.dart';
import 'offline_queue_service.dart';

/// Simple service locator để các repository có thể truy cập services.
class ServiceLocator {
  static ConnectivityService? _connectivityService;
  static OfflineQueueService? _offlineQueueService;

  static void register({
    required ConnectivityService connectivityService,
    required OfflineQueueService offlineQueueService,
  }) {
    _connectivityService = connectivityService;
    _offlineQueueService = offlineQueueService;
  }

  static ConnectivityService? get connectivityService => _connectivityService;
  static OfflineQueueService? get offlineQueueService => _offlineQueueService;
}

