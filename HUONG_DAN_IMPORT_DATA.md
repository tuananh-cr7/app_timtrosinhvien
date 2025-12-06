# Hướng dẫn Import Data vào Firestore

## 🎯 Mục tiêu
Import mock data từ code vào Firestore để app có real data để demo.

---

## 📋 Cách 1: Import bằng Code (Tự động - Khuyến nghị)

### Bước 1: Thêm button import vào app (tạm thời cho dev)

Mở file `lib/features/account/account_screen.dart` và thêm button import (chỉ khi development):

```dart
// Thêm import
import '../home/data/import_to_firestore.dart';

// Trong AccountScreen, thêm một menu item tạm thời:
_MenuTile(
  icon: Icons.cloud_upload,
  label: 'Import Data (Dev)',
  onTap: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('Bạn có chắc muốn import mock data vào Firestore?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang import...')),
      );
      
      try {
        await importRoomsToFirestore();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  },
),
```

### Bước 2: Chạy app và import
1. Chạy app: `flutter run`
2. Vào tab **Tài khoản**
3. Tìm menu **"Import Data (Dev)"**
4. Click và xác nhận
5. Đợi import xong (sẽ hiện thông báo)

### Bước 3: Xóa button sau khi import xong
Sau khi import xong, xóa button này đi để không ai thấy.

---

## 📋 Cách 2: Import thủ công trên Firebase Console

### Bước 1: Mở Firebase Console
1. Vào https://console.firebase.google.com/
2. Chọn project **app-timtrosinhvien**
3. Vào **Firestore Database**

### Bước 2: Tạo collection "rooms"
1. Click **Start collection** (nếu chưa có)
2. Collection ID: `rooms`
3. Click **Next**

### Bước 3: Thêm từng phòng

**Phòng 1:**
- Document ID: **Auto-ID**
- Fields:
  - `title` (string): "Phòng trọ full nội thất gần ĐH Công Nghệ"
  - `address` (string): "Nhân Hòa, Nhân Chính, Thanh Xuân"
  - `district` (string): "Thanh Xuân"
  - `city` (string): "Hà Nội"
  - `priceMillion` (number): 4.6
  - `area` (number): 30
  - `thumbnailUrl` (string): "https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg"
  - `isShared` (boolean): false
  - `description` (string): "Phòng trọ đẹp, đầy đủ tiện nghi, gần trường đại học"
  - `createdAt` (timestamp): Click "Set" → Chọn thời gian hiện tại
  - `updatedAt` (timestamp): Click "Set" → Chọn thời gian hiện tại
  - `ownerName` (string): "Nguyễn Văn A"
  - `ownerPhone` (string): "0901234567"

**Phòng 2:**
- Document ID: **Auto-ID**
- Fields:
  - `title` (string): "Căn hộ mini mới xây, vào ở ngay"
  - `address` (string): "Ngõ 7, Phú Diễn, Bắc Từ Liêm"
  - `district` (string): "Bắc Từ Liêm"
  - `city` (string): "Hà Nội"
  - `priceMillion` (number): 3.5
  - `area` (number): 25
  - `thumbnailUrl` (string): "https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg"
  - `isShared` (boolean): false
  - `description` (string): "Căn hộ mới xây, sạch sẽ, an ninh tốt"
  - `createdAt` (timestamp): Thời gian hiện tại
  - `updatedAt` (timestamp): Thời gian hiện tại
  - `ownerName` (string): "Trần Thị B"
  - `ownerPhone` (string): "0902345678"

**Phòng 3 (Phòng ở ghép):**
- Document ID: **Auto-ID**
- Fields:
  - `title` (string): "Tìm người ở ghép gần ĐH Xây Dựng"
  - `address` (string): "8, 288 Phú Diễn, Bắc Từ Liêm"
  - `district` (string): "Bắc Từ Liêm"
  - `city` (string): "Hà Nội"
  - `priceMillion` (number): 2.0
  - `area` (number): 20
  - `thumbnailUrl` (string): "https://images.pexels.com/photos/1643383/pexels-photo-1643383.jpeg"
  - `isShared` (boolean): **true** ⚠️ (Quan trọng!)
  - `description` (string): "Tìm bạn ở ghép, phòng rộng, giá rẻ"
  - `createdAt` (timestamp): Thời gian hiện tại
  - `updatedAt` (timestamp): Thời gian hiện tại
  - `ownerName` (string): "Lê Văn C"
  - `ownerPhone` (string): "0903456789"

**Lặp lại** cho các phòng còn lại trong `mock_rooms.dart`

---

## ✅ Checklist sau khi import

- [ ] Đã thêm ít nhất 3-5 phòng vào Firestore
- [ ] Có ít nhất 1 phòng với `isShared = true`
- [ ] Tất cả phòng có `createdAt` timestamp
- [ ] Index đã được tạo xong (status: Enabled)
- [ ] Test app - data hiển thị từ Firestore
- [ ] Test offline - app fallback về mock data

---

## 🧪 Test

1. **Test với internet:**
   - Mở app
   - Data sẽ load từ Firestore
   - Kiểm tra "Phòng mới đăng", "Phòng ở ghép" có hiển thị không

2. **Test offline:**
   - Tắt internet/WiFi
   - Mở app
   - App sẽ fallback về mock data
   - Không có lỗi

---

## 🗑️ Xóa data (nếu cần)

Nếu muốn xóa tất cả data để import lại:

```dart
// Trong AccountScreen, thêm button xóa (dev only)
await clearAllRooms();
```

**Hoặc trên Firebase Console:**
1. Vào Firestore Database
2. Click vào collection `rooms`
3. Chọn tất cả documents
4. Click **Delete**

---

## 📝 Lưu ý

- **Không cần thêm tất cả phòng** - chỉ cần 5-10 phòng là đủ demo
- **Đảm bảo có ít nhất 1 phòng `isShared = true`** để test section "Phòng ở ghép"
- **Sau khi import, xóa button dev** để app sạch sẽ
- **Index phải được tạo xong** trước khi test

---

## 🎉 Xong!

Sau khi import xong, app sẽ:
- ✅ Load data từ Firestore
- ✅ Hiển thị real data
- ✅ Fallback về mock data nếu lỗi
- ✅ Sẵn sàng để demo đồ án!

