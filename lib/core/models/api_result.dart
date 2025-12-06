/// Kết quả từ API call với loading/error state.
sealed class ApiResult<T> {
  const ApiResult();
}

/// Đang loading.
class ApiLoading<T> extends ApiResult<T> {
  const ApiLoading();
}

/// Thành công với data.
class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

/// Lỗi với message.
class ApiError<T> extends ApiResult<T> {
  final String message;
  final Object? error;
  const ApiError(this.message, [this.error]);
}

/// Extension để dễ dàng xử lý ApiResult.
extension ApiResultExtension<T> on ApiResult<T> {
  /// Kiểm tra đang loading.
  bool get isLoading => this is ApiLoading<T>;

  /// Kiểm tra thành công.
  bool get isSuccess => this is ApiSuccess<T>;

  /// Kiểm tra có lỗi.
  bool get isError => this is ApiError<T>;

  /// Lấy data nếu thành công, null nếu không.
  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(data: final data) => data,
        _ => null,
      };

  /// Lấy error message nếu có lỗi, null nếu không.
  String? get errorMessage => switch (this) {
        ApiError<T>(message: final msg) => msg,
        _ => null,
      };
}

