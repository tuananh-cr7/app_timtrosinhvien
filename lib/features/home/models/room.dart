import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  Room({
    required this.id,
    required this.title,
    required this.address,
    required this.district,
    required this.city,
    required this.priceMillion,
    required this.area,
    required this.thumbnailUrl,
    this.isShared = false,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.images,
    this.amenities,
    this.availableItems,
    this.status = 'pending', // pending, active, rejected, hidden, rented
    this.latitude, // GPS latitude
    this.longitude, // GPS longitude
  });

  final String id;
  final String title;
  final String address;
  final String district;
  final String city;
  final double priceMillion; // giá theo triệu /tháng
  final double area; // m²
  final String thumbnailUrl;
  final bool isShared;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final List<String>? images;
  final List<String>? amenities; // Tiện ích
  final List<String>? availableItems; // Đồ dùng có sẵn
  final String status; // pending, active, rejected, hidden, rented
  final double? latitude; // GPS latitude
  final double? longitude; // GPS longitude

  /// Tạo Room từ Firestore document.
  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      district: data['district'] ?? '',
      city: data['city'] ?? '',
      priceMillion: (data['priceMillion'] ?? 0).toDouble(),
      area: (data['area'] ?? 0).toDouble(),
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      isShared: data['isShared'] ?? false,
      description: data['description'],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      ownerId: data['ownerId'],
      ownerName: data['ownerName'],
      ownerPhone: data['ownerPhone'],
      images: data['images'] != null
          ? List<String>.from(data['images'])
          : null,
      amenities: data['amenities'] != null
          ? List<String>.from(data['amenities'])
          : null,
          availableItems: data['availableItems'] != null
              ? List<String>.from(data['availableItems'])
              : null,
          status: data['status'] ?? 'pending', // Mặc định pending nếu không có
          latitude: data['latitude']?.toDouble(),
          longitude: data['longitude']?.toDouble(),
        );
      }

  /// Chuyển Room thành JSON để lưu cache.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'district': district,
      'city': city,
      'priceMillion': priceMillion,
      'area': area,
      'thumbnailUrl': thumbnailUrl,
      'isShared': isShared,
      'description': description,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'images': images,
      'amenities': amenities,
      'availableItems': availableItems,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Tạo Room từ JSON (từ cache).
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      priceMillion: (json['priceMillion'] ?? 0).toDouble(),
      area: (json['area'] ?? 0).toDouble(),
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      isShared: json['isShared'] ?? false,
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      ownerPhone: json['ownerPhone'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : null,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
          availableItems: json['availableItems'] != null
              ? List<String>.from(json['availableItems'])
              : null,
          status: json['status'] ?? 'pending',
          latitude: json['latitude']?.toDouble(),
          longitude: json['longitude']?.toDouble(),
        );
      }
    }


