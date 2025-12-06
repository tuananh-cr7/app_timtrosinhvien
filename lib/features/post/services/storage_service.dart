import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

/// Service quản lý upload ảnh lên Supabase Storage.
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Tên bucket trong Supabase Storage (bạn đã tạo "room-images")
  static const String _bucketName = 'room-images';

  /// Upload một file ảnh lên Supabase Storage.
  /// Trả về URL công khai của ảnh sau khi upload thành công.
  Future<String> uploadImage(File imageFile, {String? customPath}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Chưa đăng nhập');
      }

      // Tạo đường dẫn trong Storage
      // Format: userId/timestamp_filename.ext
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      // Đường dẫn trong bucket: userId/timestamp_filename.ext
      final storagePath = customPath ?? '${user.uid}/$uniqueFileName';

      // Upload file lên Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .upload(
            storagePath,
            imageFile,
            fileOptions: FileOptions(
              upsert: true, // Ghi đè nếu file đã tồn tại
            ),
          );

      // Lấy URL công khai của file
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Không thể upload ảnh: ${e.toString()}');
    }
  }

  /// Upload nhiều ảnh cùng lúc.
  /// Trả về danh sách URLs theo thứ tự upload.
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final urls = <String>[];
    
    for (final file in imageFiles) {
      try {
        final url = await uploadImage(file);
        urls.add(url);
      } catch (e) {
        // Nếu một ảnh lỗi, bỏ qua và tiếp tục với ảnh khác
        print('⚠️  Lỗi upload ảnh ${file.path}: $e');
      }
    }
    
    return urls;
  }

  /// Xóa ảnh khỏi Storage.
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path từ URL Supabase
      // URL format: https://[project].supabase.co/storage/v1/object/public/room-images/path/to/file
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Tìm index của bucket name trong path
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Không thể parse URL: $imageUrl');
      }
      
      // Lấy path sau bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      // Xóa file
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Không thể xóa ảnh: ${e.toString()}');
    }
  }

  /// Xóa nhiều ảnh cùng lúc.
  Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await deleteImage(url);
      } catch (e) {
        print('⚠️  Lỗi xóa ảnh $url: $e');
      }
    }
  }
}
