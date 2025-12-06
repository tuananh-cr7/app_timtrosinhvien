/// Model bộ lọc tìm kiếm phòng trọ.
class SearchFilter {
  SearchFilter({
    this.query = '',
    this.city,
    this.district,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.isShared,
    this.amenities = const [],
    this.availableItems = const [],
    this.roomType,
  });

  final String query; // Từ khóa tìm kiếm
  final String? city;
  final String? district;
  final double? minPrice; // Giá tối thiểu (triệu VND)
  final double? maxPrice; // Giá tối đa (triệu VND)
  final double? minArea; // Diện tích tối thiểu (m²)
  final double? maxArea; // Diện tích tối đa (m²)
  final bool? isShared; // null = tất cả, true = ở ghép, false = cho thuê riêng
  final List<String> amenities; // Tiện ích: wifi, wc_rieng, giu_xe, etc.
  final List<String> availableItems; // Đồ dùng: giuong, tu_quan_ao, etc.
  final RoomTypeFilter? roomType; // Loại phòng

  /// Tạo filter mặc định (rỗng).
  factory SearchFilter.empty() {
    return SearchFilter();
  }

  /// Kiểm tra có filter nào được áp dụng không.
  bool get hasFilters {
    return query.isNotEmpty ||
        city != null ||
        district != null ||
        minPrice != null ||
        maxPrice != null ||
        minArea != null ||
        maxArea != null ||
        isShared != null ||
        amenities.isNotEmpty ||
        availableItems.isNotEmpty ||
        roomType != null;
  }

  /// Reset tất cả filters.
  SearchFilter copyWith({
    String? query,
    String? city,
    String? district,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    bool? isShared,
    List<String>? amenities,
    List<String>? availableItems,
    RoomTypeFilter? roomType,
    bool clearCity = false,
    bool clearDistrict = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinArea = false,
    bool clearMaxArea = false,
    bool clearIsShared = false,
    bool clearRoomType = false,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      city: clearCity ? null : (city ?? this.city),
      district: clearDistrict ? null : (district ?? this.district),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minArea: clearMinArea ? null : (minArea ?? this.minArea),
      maxArea: clearMaxArea ? null : (maxArea ?? this.maxArea),
      isShared: clearIsShared ? null : (isShared ?? this.isShared),
      amenities: amenities ?? this.amenities,
      availableItems: availableItems ?? this.availableItems,
      roomType: clearRoomType ? null : (roomType ?? this.roomType),
    );
  }

  /// Reset tất cả filters.
  SearchFilter clear() {
    return SearchFilter.empty();
  }
}

/// Loại phòng filter.
enum RoomTypeFilter {
  room, // Phòng
  apartment, // Căn hộ
  miniApartment, // Căn hộ mini
  entirePlace, // Nguyên căn
}

extension RoomTypeFilterExtension on RoomTypeFilter {
  String get displayName {
    switch (this) {
      case RoomTypeFilter.room:
        return 'Phòng';
      case RoomTypeFilter.apartment:
        return 'Căn hộ';
      case RoomTypeFilter.miniApartment:
        return 'Căn hộ mini';
      case RoomTypeFilter.entirePlace:
        return 'Nguyên căn';
    }
  }
}

