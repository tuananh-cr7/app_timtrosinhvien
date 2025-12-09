import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service để detect network connectivity và quản lý trạng thái online/offline.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Kiểm tra trạng thái ban đầu
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Lắng nghe thay đổi connectivity
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (error) {
        print('⚠️ ConnectivityService error: $error');
        _isOnline = false;
        notifyListeners();
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Có kết nối nếu có ít nhất một kết nối không phải none
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (wasOnline != _isOnline) {
      print('🌐 ConnectivityService: ${_isOnline ? "Online" : "Offline"}');
      notifyListeners();
    }
  }

  /// Kiểm tra có kết nối internet không (không chỉ có WiFi/mobile mà còn phải có internet thực sự).
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      print('⚠️ Lỗi kiểm tra connectivity: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

