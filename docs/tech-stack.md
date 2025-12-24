# Tech Stack (app_timtrosinhvien)

## 1. Nền tảng & Ngôn ngữ
- Flutter (Dart) – mobile app (iOS/Android), Material 3
- Web Admin: Flutter Web (file `lib/main_admin.dart`)

## 2. Backend & Dịch vụ
- Firebase:
  - Firebase Auth (Email/Password, Google Sign-In)
  - Cloud Firestore (realtime DB, collectionGroup, security rules)
  - Firebase Cloud Messaging (FCM) cho thông báo in-app
  - Firebase App Check (hiện chưa cấu hình provider, log cảnh báo)
  - Firebase Hosting/Deploy rules (`firebase deploy --only firestore:rules`)
- Supabase: khởi tạo sẵn (hiện không thấy dùng chính trong flow)

## 3. State & Điều hướng
- StatefulWidget + setState
- Navigator / MaterialPageRoute
- Service Locator (core/services/service_locator.dart) cho connectivity/offline queue

## 4. UI/UX Components
- PageView.builder, StreamBuilder, AlertDialog, BottomSheet
- TextFormField, DropdownButtonFormField, Wrap, Chip
- CachedNetworkImage, InteractiveViewer (zoom ảnh), CircularProgressIndicator, RefreshIndicator
- Scaffold, AppBar, BottomNavigationBar, NavigationRail (admin)
- Card, ListTile, ElevatedButton, TextButton, IconButton, Row/Column/Expanded
- CustomScrollView, SliverToBoxAdapter

## 5. Tìm kiếm & Xử lý chuỗi
- Chuẩn hóa tiếng Việt bỏ dấu (`normalizeVietnamese`) để search/filter

## 6. Hình ảnh & Upload
- CachedNetworkImage hiển thị
- ImagePicker / upload chat images (đã có hook)

## 7. Thông báo & Sự kiện
- In-app notifications (collection `notifications`): room_hidden, review_new, review_removed
- Điều hướng từ notification tới `RoomDetailScreen`

## 8. Chat & Trạng thái
- Chat với Firestore: conversations, messages
- Mute/unmute, block/unblock (isBlocked, blockedBy), banner ẩn thanh nhập khi bị chặn

## 9. Đánh giá & Báo cáo
- Reviews: collectionGroup `reviews`, rating/comment, slideshow ảnh phòng
- Reports: viewer ảnh (slideshow), hợp nhất ảnh phòng khi thiếu

## 10. Bảo mật & Rules
- Firestore security rules:
  - `users/{uid}/blockedUsers` chỉ owner đọc/ghi/xóa
  - `rooms/{roomId}/reviews`: ai cũng đọc, CRUD bởi owner, rating 1–5
  - messages create bị chặn nếu conversation.isBlocked == true
  - notifications cho phép type room_hidden/review_new/review_removed

## 11. Ngoại tuyến & Kết nối
- ConnectivityService + OfflineQueueService (sync khi online)

## 12. Biểu đồ & Thống kê (Admin)
- Dashboard thống kê: reviews, reports, fallback tránh thiếu index


