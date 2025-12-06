import 'data/repositories/view_history_repository.dart';
import 'models/room.dart';
import '../../core/models/api_result.dart';

/// Manager để ghi lịch sử xem (wrapper cho repository).
/// Giữ lại để tương thích với code cũ.
class HistoryManager {
  HistoryManager._();
  
  static final _repository = ViewHistoryRepository();

  /// Ghi lại lịch sử xem phòng vào Firestore.
  static Future<void> logView(Room room) async {
    final result = await _repository.logView(room.id);
    // Log lỗi nhưng không throw để không ảnh hưởng UX
    switch (result) {
      case ApiError<void>(message: final msg):
        print('⚠️  Lỗi khi ghi lịch sử xem: $msg');
        break;
      case ApiSuccess<void>():
        // Thành công, không cần log
        break;
      case ApiLoading<void>():
        // Không nên xảy ra
        break;
    }
  }

  /// Lấy lịch sử xem từ Firestore.
  static Future<List<ViewHistoryEntry>> getHistory() async {
    final result = await _repository.getHistory();
    return switch (result) {
      ApiSuccess<List<ViewHistoryEntry>>(data: final data) => data,
      _ => <ViewHistoryEntry>[],
    };
  }
}


