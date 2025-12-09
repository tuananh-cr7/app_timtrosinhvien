import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/home/data/repositories/favorites_repository.dart';
import '../../features/home/data/repositories/view_history_repository.dart';
import '../cache/hive_service.dart';
import 'connectivity_service.dart';

/// Service quản lý queue các thao tác cần sync khi online (favorite, view history).
class OfflineQueueService {
  final FavoritesRepository _favoritesRepository = FavoritesRepository();
  final ViewHistoryRepository _viewHistoryRepository = ViewHistoryRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService;
  
  static const String _queueBoxName = 'offline_queue';
  static const String _queueKey = 'pending_operations';
  
  Box? _queueBox;

  OfflineQueueService(this._connectivityService) {
    _init();
  }

  Future<void> _init() async {
    _queueBox = await Hive.openBox(_queueBoxName);
  }

  /// Thêm operation vào queue.
  Future<void> queueOperation(QueuedOperation operation) async {
    if (_queueBox == null) await _init();
    
    final operations = _getQueuedOperations();
    operations.add(operation);
    await _saveQueuedOperations(operations);
    
    print('📝 Đã thêm operation vào queue: ${operation.type} - ${operation.data}');
    
    // Thử sync ngay nếu online
    if (_connectivityService.isOnline) {
      await syncQueue();
    }
  }

  /// Sync tất cả operations trong queue khi online.
  Future<void> syncQueue() async {
    if (_queueBox == null) await _init();
    
    if (!_connectivityService.isOnline) {
      print('⚠️ Không thể sync: đang offline');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ Không thể sync: chưa đăng nhập');
      return;
    }

    final operations = _getQueuedOperations();
    if (operations.isEmpty) {
      print('✅ Queue rỗng, không cần sync');
      return;
    }

    print('🔄 Bắt đầu sync ${operations.length} operations...');
    
    final failedOperations = <QueuedOperation>[];
    
    for (final operation in operations) {
      try {
        await _executeOperation(operation);
        print('✅ Đã sync operation: ${operation.type}');
      } catch (e) {
        print('❌ Lỗi sync operation ${operation.type}: $e');
        failedOperations.add(operation);
      }
    }

    // Lưu lại các operations thất bại
    await _saveQueuedOperations(failedOperations);
    
    if (failedOperations.isEmpty) {
      print('✅ Đã sync thành công tất cả operations');
    } else {
      print('⚠️ Còn ${failedOperations.length} operations chưa sync được');
    }
  }

  Future<void> _executeOperation(QueuedOperation operation) async {
    switch (operation.type) {
      case QueuedOperationType.addFavorite:
        final roomId = operation.data['roomId'] as String;
        await _favoritesRepository.addFavorite(roomId);
        break;
      case QueuedOperationType.removeFavorite:
        final roomId = operation.data['roomId'] as String;
        await _favoritesRepository.removeFavorite(roomId);
        break;
      case QueuedOperationType.logView:
        final roomId = operation.data['roomId'] as String;
        await _viewHistoryRepository.logView(roomId);
        break;
    }
  }

  List<QueuedOperation> _getQueuedOperations() {
    if (_queueBox == null) return [];
    
    final json = _queueBox!.get(_queueKey) as String?;
    if (json == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((e) => QueuedOperation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('⚠️ Lỗi decode queue: $e');
      return [];
    }
  }

  Future<void> _saveQueuedOperations(List<QueuedOperation> operations) async {
    if (_queueBox == null) await _init();
    
    final json = jsonEncode(operations.map((e) => e.toJson()).toList());
    await _queueBox!.put(_queueKey, json);
  }

  /// Xóa tất cả operations đã sync thành công.
  Future<void> clearQueue() async {
    if (_queueBox == null) await _init();
    await _queueBox!.delete(_queueKey);
    print('🗑️ Đã xóa queue');
  }

  /// Lấy số lượng operations đang chờ sync.
  int getPendingOperationsCount() {
    return _getQueuedOperations().length;
  }
}

/// Operation được queue để sync sau.
class QueuedOperation {
  final QueuedOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  QueuedOperation({
    required this.type,
    required this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      type: QueuedOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QueuedOperationType.logView,
      ),
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum QueuedOperationType {
  addFavorite,
  removeFavorite,
  logView,
}

