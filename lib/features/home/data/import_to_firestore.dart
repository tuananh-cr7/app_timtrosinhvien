import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'mock_rooms.dart';
import '../models/room.dart';

/// Script để import mock data vào Firestore.
/// 
/// Cách sử dụng:
/// 1. Chạy app
/// 2. Gọi hàm importRoomsToFirestore() từ một nơi nào đó (ví dụ: button trong dev menu)
/// 3. Hoặc chạy từ main() khi development
Future<void> importRoomsToFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final collection = firestore.collection('rooms');

  // Kiểm tra đã đăng nhập chưa
  final user = auth.currentUser;
  if (user == null) {
    throw Exception('Vui lòng đăng nhập trước khi import data');
  }

  print('🚀 Bắt đầu import data vào Firestore...');
  print('👤 User: ${user.email} (${user.uid})');

  try {
    // Import tất cả rooms từ mock data
    final allRooms = [
      ...mockLatestRooms,
      ...mockSharedRooms,
      // Thêm các phòng còn lại từ mockAllRooms (tránh duplicate)
      ...mockAllRooms.where((r) => 
        !mockLatestRooms.any((lr) => lr.id == r.id) &&
        !mockSharedRooms.any((sr) => sr.id == r.id)
      ),
    ];

    int successCount = 0;
    int errorCount = 0;

    for (final room in allRooms) {
      try {
        // Kiểm tra xem đã có chưa (theo document ID)
        final existingDoc = await collection.doc(room.id).get();
        if (existingDoc.exists) {
          print('⏭️  Đã có (theo ID): ${room.title} (${room.id})');
          continue;
        }

        // Thêm mới - dùng document ID là room.id để giữ nguyên ID từ mock data
        // Điều này đảm bảo room.id từ mock data khớp với Firestore document ID
        await collection.doc(room.id).set({
          'title': room.title,
          'address': room.address,
          'district': room.district,
          'city': room.city,
          'priceMillion': room.priceMillion,
          'area': room.area,
          'thumbnailUrl': room.thumbnailUrl,
          'isShared': room.isShared,
          'description': room.description ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'ownerId': user.uid, // Dùng uid của user hiện tại
          'ownerName': user.displayName ?? 'Chủ trọ ${room.id}',
          'ownerPhone': user.phoneNumber ?? '0900000000',
        }, SetOptions(merge: true)); // merge: true để không ghi đè nếu đã có

        successCount++;
        print('✅ Đã thêm: ${room.title}');
      } catch (e) {
        errorCount++;
        print('❌ Lỗi khi thêm ${room.title}: $e');
      }
    }

    print('\n📊 Kết quả:');
    print('   ✅ Thành công: $successCount phòng');
    print('   ❌ Lỗi: $errorCount phòng');
    print('   📝 Tổng: ${allRooms.length} phòng');
    print('\n🎉 Hoàn tất import data!');
  } catch (e) {
    print('❌ Lỗi khi import: $e');
    rethrow;
  }
}

/// Xóa tất cả data trong collection rooms (CẨN THẬN!)
Future<void> clearAllRooms() async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('rooms');

  print('⚠️  Đang xóa tất cả rooms...');

  try {
    final snapshot = await collection.get();
    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print('✅ Đã xóa ${snapshot.docs.length} phòng');
  } catch (e) {
    print('❌ Lỗi khi xóa: $e');
    rethrow;
  }
}

