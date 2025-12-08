import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/cache/hive_service.dart';
import '../../../../core/models/api_result.dart';
import '../../models/room.dart';
import '../mock_rooms.dart';

/// Repository quản lý dữ liệu phòng trọ từ Firestore và local cache.
class RoomsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'rooms';
  static const String _cacheKey = 'rooms_list';
  static const String _lastFetchKey = 'rooms_last_fetch';
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Lấy danh sách phòng từ Firestore hoặc cache.
  /// 
  /// [useCache]: Nếu true, sẽ trả về cache nếu còn hợp lệ, nếu false sẽ force fetch từ server.
  /// [limit]: Giới hạn số lượng phòng trả về.
  /// [lastDocument]: Document snapshot cuối cùng để pagination (cho infinite scroll).
  Future<ApiResult<List<Room>>> getRooms({
    bool useCache = true,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Kiểm tra cache nếu được yêu cầu
      if (useCache) {
        final cached = _getCachedRooms();
        if (cached != null && cached.isNotEmpty) {
          print('📊 getRooms: Sử dụng cache với ${cached.length} phòng');
          // Nếu có limit, chỉ lấy số lượng cần thiết
          if (limit != null && cached.length > limit) {
            return ApiSuccess(cached.take(limit).toList());
          }
          return ApiSuccess(cached);
        } else if (cached != null && cached.isEmpty) {
          print('⚠️  getRooms: Cache rỗng, bỏ qua cache và fetch từ Firestore');
        }
      }

      // Fetch từ Firestore
      // Chỉ lấy rooms có status = 'active' (đã được duyệt)
      Query query = _firestore.collection(_collectionName)
          .where('status', isEqualTo: 'active');
      
      // Thử orderBy, nếu lỗi thì bỏ qua (có thể chưa có index)
      // Lưu ý: orderBy có thể fail khi query, nên sẽ catch ở ngoài
      try {
        query = query.orderBy('createdAt', descending: true);
        
        // Pagination: startAfter lastDocument nếu có
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }
        
        if (limit != null) {
          query = query.limit(limit);
        }
        final snapshot = await query.get();
        return _processRoomsSnapshot(snapshot, limit);
      } catch (e) {
        // Nếu orderBy fail (có thể do thiếu index), thử query không orderBy
        print('⚠️  Lỗi khi query với orderBy: $e');
        print('📊 Thử query không orderBy...');
        Query simpleQuery = _firestore.collection(_collectionName)
            .where('status', isEqualTo: 'active'); // Chỉ lấy active
        if (limit != null) {
          simpleQuery = simpleQuery.limit(limit);
        }
        final snapshot = await simpleQuery.get();
        return _processRoomsSnapshot(snapshot, limit);
      }
    } catch (e) {
      // Nếu lỗi và có cache, trả về cache
      final cached = _getCachedRooms();
      if (cached != null && cached.isNotEmpty) {
        print('📊 getRooms: Lỗi khi query, sử dụng cache với ${cached.length} phòng');
        if (limit != null && cached.length > limit) {
          return ApiSuccess(cached.take(limit).toList());
        }
        return ApiSuccess(cached);
      }

      // Nếu không có cache hoặc cache rỗng, fallback về mock data
      print('⚠️  getRooms: Lỗi và không có cache, fallback về mock data');
      final fallback = _getFallbackRooms();
      if (limit != null && fallback.length > limit) {
        return ApiSuccess(fallback.take(limit).toList());
      }
      return ApiSuccess(fallback);
    }
  }

  ApiResult<List<Room>> _processRoomsSnapshot(QuerySnapshot snapshot, int? limit) {
    final rooms = snapshot.docs
        .map((doc) => Room.fromFirestore(doc))
        .toList();

    print('📊 _processRoomsSnapshot: Lấy được ${rooms.length} phòng từ Firestore (limit=${limit ?? "null"})');

    // Nếu Firestore trả về rỗng, fallback về mock data
    if (rooms.isEmpty) {
      print('⚠️  Firestore rỗng, fallback về mock data');
      final fallback = _getFallbackRooms();
      print('📊 Fallback: ${fallback.length} phòng từ mock data');
      // Nếu có limit, chỉ lấy số lượng cần thiết
      if (limit != null && fallback.length > limit) {
        return ApiSuccess(fallback.take(limit).toList());
      }
      return ApiSuccess(fallback);
    }

    // Lưu vào cache (chỉ lưu nếu không có limit hoặc limit lớn)
    if (limit == null || limit >= rooms.length) {
      _saveToCache(rooms);
    }

    return ApiSuccess(rooms);
  }

  /// Lấy phòng theo ID.
  Future<ApiResult<Room?>> getRoomById(String roomId) async {
    try {
      print('🔍 getRoomById: Đang tìm roomId=$roomId');
      final doc = await _firestore
          .collection(_collectionName)
          .doc(roomId)
          .get();

      if (!doc.exists) {
        print('⚠️  getRoomById: Không tìm thấy document với id=$roomId');
        // Thử tìm theo title/address nếu là mock ID
        return ApiSuccess(null);
      }

      final room = Room.fromFirestore(doc);
      print('✅ getRoomById: Tìm thấy room "${room.title}" với id=${room.id}');
      return ApiSuccess(room);
    } catch (e) {
      print('❌ getRoomById: Lỗi khi tìm roomId=$roomId - $e');
      return ApiError('Không thể tải thông tin phòng: ${e.toString()}', e);
    }
  }

  /// Tìm kiếm phòng với filters.
  Future<ApiResult<List<Room>>> searchRooms({
    String? city,
    String? district,
    double? minPrice,
    double? maxPrice,
    int? minArea,
    int? maxArea,
    bool? isShared,
    int? limit,
  }) async {
    try {
      print('🔍 searchRooms: minPrice=$minPrice, maxPrice=$maxPrice, minArea=$minArea, maxArea=$maxArea');
      
      // Chỉ tìm kiếm trong các tin đã được duyệt (status = 'active')
      Query query = _firestore.collection(_collectionName)
          .where('status', isEqualTo: 'active');

      // Thêm các equality filters trước
      if (city != null) {
        query = query.where('city', isEqualTo: city);
      }
      if (district != null) {
        query = query.where('district', isEqualTo: district);
      }
      if (isShared != null) {
        query = query.where('isShared', isEqualTo: isShared);
      }

      // Thêm range filters (chỉ có thể có 1 range filter trên 1 field)
      // Nếu có cả minPrice và maxPrice, chỉ dùng 1 trong 2 để tránh lỗi index
      if (minPrice != null && maxPrice != null) {
        // Dùng range filter với isGreaterThanOrEqualTo và isLessThanOrEqualTo
        query = query.where('priceMillion', isGreaterThanOrEqualTo: minPrice)
            .where('priceMillion', isLessThanOrEqualTo: maxPrice);
      } else if (minPrice != null) {
        query = query.where('priceMillion', isGreaterThanOrEqualTo: minPrice);
      } else if (maxPrice != null) {
        query = query.where('priceMillion', isLessThanOrEqualTo: maxPrice);
      }

      // Area filters
      if (minArea != null && maxArea != null) {
        query = query.where('area', isGreaterThanOrEqualTo: minArea)
            .where('area', isLessThanOrEqualTo: maxArea);
      } else if (minArea != null) {
        query = query.where('area', isGreaterThanOrEqualTo: minArea);
      } else if (maxArea != null) {
        query = query.where('area', isLessThanOrEqualTo: maxArea);
      }

      // OrderBy - Khi có range filter trên priceMillion, Firestore yêu cầu orderBy priceMillion
      // Index cần: status (ASC), priceMillion (ASC)
      bool hasPriceRange = (minPrice != null || maxPrice != null);
      bool hasAreaRange = (minArea != null || maxArea != null);
      
      if (hasPriceRange) {
        // Khi có range filter trên priceMillion, phải orderBy priceMillion (ASC)
        // Index: status (ASC), priceMillion (ASC)
        try {
          query = query.orderBy('priceMillion', descending: false); // ASC để match với index
          print('✅ searchRooms: Đã thêm orderBy priceMillion (ASC)');
        } catch (e) {
          print('⚠️  searchRooms: Không thể orderBy priceMillion: $e');
        }
      } else if (!hasAreaRange) {
        // Chỉ orderBy createdAt khi KHÔNG có range filter
        try {
          query = query.orderBy('createdAt', descending: true);
          print('✅ searchRooms: Đã thêm orderBy createdAt');
        } catch (e) {
          print('⚠️  searchRooms: Không thể orderBy createdAt: $e');
        }
      } else {
        print('⚠️  searchRooms: Có range filter trên area, bỏ qua orderBy');
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      print('🔍 searchRooms: Đang thực hiện query...');
      print('🔍 searchRooms: Query filters - status=active, minPrice=$minPrice, maxPrice=$maxPrice, minArea=$minArea, maxArea=$maxArea, city=$city, district=$district, isShared=$isShared');
      final snapshot = await query.get();
      print('✅ searchRooms: Query thành công, lấy được ${snapshot.docs.length} documents');

      final rooms = snapshot.docs
          .map((doc) {
            final room = Room.fromFirestore(doc);
            print('📊 Room: ${room.id} - title="${room.title}", priceMillion=${room.priceMillion}, status=${room.status}');
            return room;
          })
          .toList();

      // Sort lại ở client nếu cần (vì có thể không orderBy được)
      rooms.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(1970);
        final bTime = b.createdAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      // Nếu kết quả rỗng, fallback về mock data (filter theo giá nếu có)
      if (rooms.isEmpty) {
        print('⚠️  Firestore rỗng, fallback về mock data');
        print('🔍 Fallback filters: minPrice=$minPrice, maxPrice=$maxPrice, minArea=$minArea, maxArea=$maxArea, city=$city, district=$district, isShared=$isShared');
        
        var fallbackRooms = <Room>[];
        
        // Lấy tất cả mock rooms
        if (isShared == true) {
          fallbackRooms = List.from(mockSharedRooms);
        } else if (isShared == false) {
          fallbackRooms = List.from(mockLatestRooms);
        } else {
          fallbackRooms = [...mockLatestRooms, ...mockSharedRooms, ...mockAllRooms];
          // Remove duplicates
          final seen = <String>{};
          fallbackRooms = fallbackRooms.where((r) => seen.add(r.id)).toList();
        }
        
        print('📊 Fallback: Trước khi filter có ${fallbackRooms.length} phòng');
        
        // Filter theo giá nếu có (QUAN TRỌNG: phải filter đúng)
        if (minPrice != null || maxPrice != null) {
          final beforeCount = fallbackRooms.length;
          fallbackRooms = fallbackRooms.where((room) {
            final price = room.priceMillion;
            if (minPrice != null && price < minPrice) {
              print('  ❌ Room ${room.id}: priceMillion=$price < minPrice=$minPrice');
              return false;
            }
            if (maxPrice != null && price > maxPrice) {
              print('  ❌ Room ${room.id}: priceMillion=$price > maxPrice=$maxPrice');
              return false;
            }
            print('  ✅ Room ${room.id}: priceMillion=$price (minPrice=$minPrice, maxPrice=$maxPrice)');
            return true;
          }).toList();
          print('📊 Fallback: Sau filter giá: ${beforeCount} → ${fallbackRooms.length} phòng');
        }
        
        // Filter theo diện tích nếu có
        if (minArea != null || maxArea != null) {
          final beforeCount = fallbackRooms.length;
          fallbackRooms = fallbackRooms.where((room) {
            if (minArea != null && room.area < minArea) return false;
            if (maxArea != null && room.area > maxArea) return false;
            return true;
          }).toList();
          print('📊 Fallback: Sau filter diện tích: ${beforeCount} → ${fallbackRooms.length} phòng');
        }
        
        // Filter theo city/district nếu có
        if (city != null) {
          final beforeCount = fallbackRooms.length;
          fallbackRooms = fallbackRooms.where((room) => room.city == city).toList();
          print('📊 Fallback: Sau filter city: ${beforeCount} → ${fallbackRooms.length} phòng');
        }
        if (district != null) {
          final beforeCount = fallbackRooms.length;
          fallbackRooms = fallbackRooms.where((room) => room.district == district).toList();
          print('📊 Fallback: Sau filter district: ${beforeCount} → ${fallbackRooms.length} phòng');
        }
        
        print('📊 Fallback: Kết quả cuối cùng: ${fallbackRooms.length} phòng');
        if (fallbackRooms.isNotEmpty) {
          print('📊 Fallback rooms:');
          for (final room in fallbackRooms) {
            print('  - ${room.id}: ${room.title}, priceMillion=${room.priceMillion}, area=${room.area}');
          }
        }
        return ApiSuccess(fallbackRooms);
      }

      return ApiSuccess(rooms);
    } catch (e) {
      print('❌ searchRooms error: $e');
      // Nếu lỗi và đang tìm phòng ở ghép, fallback về mock data
      if (isShared == true) {
        print('⚠️  Lỗi khi tìm phòng ở ghép, fallback về mock data');
        return ApiSuccess(mockSharedRooms);
      }
      return ApiError('Không thể tìm kiếm phòng: ${e.toString()}', e);
    }
  }

  /// Lấy phòng mới nhất.
  Future<ApiResult<List<Room>>> getLatestRooms({int limit = 10}) async {
    print('📊 getLatestRooms: Bắt đầu (limit=$limit)');
    final result = await getRooms(limit: limit, useCache: false); // Không dùng cache để đảm bảo fresh data
    // Nếu Firestore rỗng, fallback về mock data
    if (result.isSuccess && (result.dataOrNull?.isEmpty ?? true)) {
      print('⚠️  Firestore rỗng cho phòng mới nhất, fallback về mock data');
      return ApiSuccess(mockLatestRooms.take(limit).toList());
    }
    print('📊 getLatestRooms: Trả về ${result.dataOrNull?.length ?? 0} phòng');
    return result;
  }

  /// Lấy phòng ở ghép.
  Future<ApiResult<List<Room>>> getSharedRooms({int limit = 10}) async {
    print('📊 getSharedRooms: Bắt đầu (limit=$limit)');
    final result = await searchRooms(isShared: true, limit: limit);
    // Nếu Firestore rỗng, fallback về mock data
    if (result.isSuccess && (result.dataOrNull?.isEmpty ?? true)) {
      print('⚠️  Firestore rỗng cho phòng ở ghép, fallback về mock data');
      return ApiSuccess(mockSharedRooms.take(limit).toList());
    }
    print('📊 getSharedRooms: Trả về ${result.dataOrNull?.length ?? 0} phòng');
    return result;
  }

  /// Lưu danh sách phòng vào cache.
  void _saveToCache(List<Room> rooms) {
    final box = HiveService.roomsBox;
    final roomsJson = rooms.map((r) => r.toJson()).toList();
    box.put(_cacheKey, roomsJson);
    box.put(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Lấy danh sách phòng từ cache nếu còn hợp lệ.
  List<Room>? _getCachedRooms() {
    final box = HiveService.roomsBox;
    final lastFetch = box.get(_lastFetchKey) as int?;

    if (lastFetch == null) return null;

    final lastFetchTime = DateTime.fromMillisecondsSinceEpoch(lastFetch);
    if (DateTime.now().difference(lastFetchTime) > _cacheExpiry) {
      return null; // Cache đã hết hạn
    }

    final roomsJson = box.get(_cacheKey) as List?;
    if (roomsJson == null) return null;

    try {
      return roomsJson
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null; // Cache bị lỗi
    }
  }

  /// Xóa cache.
  Future<void> clearCache() async {
    final box = HiveService.roomsBox;
    await box.delete(_cacheKey);
    await box.delete(_lastFetchKey);
  }

  /// Lấy phòng theo ownerId (phòng đã đăng).
  Future<ApiResult<List<Room>>> getRoomsByOwner(String ownerId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('ownerId', isEqualTo: ownerId);

      // Thử orderBy, nếu lỗi thì bỏ qua
      try {
        query = query.orderBy('createdAt', descending: true);
      } catch (e) {
        print('⚠️  Không thể orderBy createdAt cho getRoomsByOwner: $e');
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final rooms = snapshot.docs
          .map((doc) => Room.fromFirestore(doc))
          .toList();

      print('📊 getRoomsByOwner: Lấy được ${rooms.length} phòng của owner $ownerId');

      return ApiSuccess(rooms);
    } catch (e) {
      return ApiError('Không thể tải phòng đã đăng: ${e.toString()}', e);
    }
  }

  /// Lấy mock data làm fallback.
  List<Room> _getFallbackRooms() {
    return [
      ...mockLatestRooms,
      ...mockSharedRooms,
      ...mockAllRooms.where((r) => 
        !mockLatestRooms.any((lr) => lr.id == r.id) &&
        !mockSharedRooms.any((sr) => sr.id == r.id)
      ),
    ];
  }

  /// Tạo phòng mới từ RoomDraft.
  Future<ApiResult<Room>> createRoom({
    required Map<String, dynamic> roomData,
  }) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      
      final data = {
        ...roomData,
        'id': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      // Fetch lại để lấy document với timestamp đã được server set
      final doc = await docRef.get();
      final room = Room.fromFirestore(doc);

      // Clear cache để refresh
      _clearCache();

      return ApiSuccess(room);
    } catch (e) {
      return ApiError('Không thể tạo phòng: ${e.toString()}', e);
    }
  }

  /// Cập nhật phòng.
  Future<ApiResult<void>> updateRoom({
    required String roomId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(roomId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache để refresh
      _clearCache();

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể cập nhật phòng: ${e.toString()}', e);
    }
  }

  /// Xóa phòng.
  Future<ApiResult<void>> deleteRoom(String roomId) async {
    try {
      await _firestore.collection(_collectionName).doc(roomId).delete();

      // Clear cache để refresh
      _clearCache();

      return ApiSuccess(null);
    } catch (e) {
      return ApiError('Không thể xóa phòng: ${e.toString()}', e);
    }
  }

  void _clearCache() {
    try {
      final box = HiveService.roomsBox;
      box.delete(_cacheKey);
      box.delete(_lastFetchKey);
    } catch (e) {
      print('⚠️  Lỗi khi xóa cache: $e');
    }
  }
}

