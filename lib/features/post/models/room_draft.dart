import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Model lưu nháp đăng tin phòng trọ.
class RoomDraft {
  RoomDraft({
    this.postType = PostType.forRent,
    this.roomType = RoomType.room,
    this.price = 0,
    this.area = 0,
    this.amenities = const [],
    this.city = '',
    this.district = '',
    this.ward = '',
    this.streetName = '',
    this.houseNumber = '',
    this.directions = '',
    this.latitude,
    this.longitude,
    this.images = const [],
    this.title = '',
    this.description = '',
    this.contactName = '',
    this.contactPhone = '',
    this.availableItems = const [],
  });

  // Bước 1: Thông tin cơ bản
  PostType postType; // Cho thuê / Tìm ở ghép
  RoomType roomType; // Phòng / Căn hộ / Căn hộ mini / Nguyên căn
  double price; // Giá (VND)
  double area; // Diện tích (m²)
  List<String> amenities; // Tiện ích: wifi, wc_rieng, giu_xe, tu_do_gio_gac, bep_rieng, dieu_hoa, tu_lanh, may_giat

  // Bước 2: Địa chỉ
  String city; // Thành phố
  String district; // Quận/Huyện
  String ward; // Phường/Xã
  String streetName; // Tên đường
  String houseNumber; // Số nhà
  String directions; // Mô tả đường đi
  double? latitude;
  double? longitude;

  // Bước 3: Hình ảnh
  List<String> images; // URLs hoặc file paths

  // Bước 4: Xác nhận
  String title; // Tiêu đề bài đăng
  String description; // Mô tả chi tiết
  String contactName; // Tên liên hệ
  String contactPhone; // Số điện thoại liên hệ
  List<String> availableItems; // Đồ dùng có sẵn: giuong, tu_quan_ao, ban_ghe, bep, may_lanh, may_giat, tu_lanh, nem

  /// Chuyển thành JSON để lưu SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      'postType': postType.name,
      'roomType': roomType.name,
      'price': price,
      'area': area,
      'amenities': amenities,
      'city': city,
      'district': district,
      'ward': ward,
      'streetName': streetName,
      'houseNumber': houseNumber,
      'directions': directions,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'title': title,
      'description': description,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'availableItems': availableItems,
    };
  }

  /// Tạo từ JSON.
  factory RoomDraft.fromJson(Map<String, dynamic> json) {
    return RoomDraft(
      postType: PostType.values.firstWhere(
        (e) => e.name == json['postType'],
        orElse: () => PostType.forRent,
      ),
      roomType: RoomType.values.firstWhere(
        (e) => e.name == json['roomType'],
        orElse: () => RoomType.room,
      ),
      price: (json['price'] ?? 0).toDouble(),
      area: (json['area'] ?? 0).toDouble(),
      amenities: List<String>.from(json['amenities'] ?? []),
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      ward: json['ward'] ?? '',
      streetName: json['streetName'] ?? '',
      houseNumber: json['houseNumber'] ?? '',
      directions: json['directions'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      images: List<String>.from(json['images'] ?? []),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      contactName: json['contactName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      availableItems: List<String>.from(json['availableItems'] ?? []),
    );
  }

  /// Lưu nháp vào SharedPreferences.
  static Future<void> saveDraft(RoomDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_draft', jsonEncode(draft.toJson()));
  }

  /// Lấy nháp từ SharedPreferences.
  static Future<RoomDraft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('room_draft');
    if (jsonStr == null) return null;
    try {
      return RoomDraft.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  /// Xóa nháp.
  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('room_draft');
  }

  /// Kiểm tra bước 1 đã hoàn thành chưa.
  bool get isStep1Complete => price > 0 && area > 0;

  /// Kiểm tra bước 2 đã hoàn thành chưa.
  bool get isStep2Complete => city.isNotEmpty && district.isNotEmpty;

  /// Kiểm tra bước 3 đã hoàn thành chưa.
  bool get isStep3Complete => images.isNotEmpty;

  /// Kiểm tra bước 4 đã hoàn thành chưa.
  bool get isStep4Complete =>
      title.isNotEmpty &&
      description.isNotEmpty &&
      contactName.isNotEmpty &&
      contactPhone.isNotEmpty;
}

enum PostType {
  forRent, // Cho thuê
  findRoommate, // Tìm ở ghép
}

enum RoomType {
  room, // Phòng
  apartment, // Căn hộ
  miniApartment, // Căn hộ mini
  entirePlace, // Nguyên căn
}

extension PostTypeExtension on PostType {
  String get displayName {
    switch (this) {
      case PostType.forRent:
        return 'Cho thuê';
      case PostType.findRoommate:
        return 'Tìm ở ghép';
    }
  }
}

extension RoomTypeExtension on RoomType {
  String get displayName {
    switch (this) {
      case RoomType.room:
        return 'Phòng';
      case RoomType.apartment:
        return 'Căn hộ';
      case RoomType.miniApartment:
        return 'Căn hộ mini';
      case RoomType.entirePlace:
        return 'Nguyên căn';
    }
  }
}

