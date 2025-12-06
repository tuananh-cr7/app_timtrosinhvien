import '../models/room_draft.dart';

/// Service quản lý lưu nháp đăng tin.
class DraftService {
  static final DraftService _instance = DraftService._();
  factory DraftService() => _instance;
  DraftService._();

  RoomDraft? _currentDraft;

  /// Lấy draft hiện tại (từ memory hoặc SharedPreferences).
  Future<RoomDraft> getCurrentDraft() async {
    if (_currentDraft != null) return _currentDraft!;
    _currentDraft = await RoomDraft.loadDraft() ?? RoomDraft();
    return _currentDraft!;
  }

  /// Cập nhật draft.
  Future<void> updateDraft(RoomDraft draft) async {
    _currentDraft = draft;
    await RoomDraft.saveDraft(draft);
  }

  /// Xóa draft.
  Future<void> clearDraft() async {
    _currentDraft = null;
    await RoomDraft.clearDraft();
  }
}

