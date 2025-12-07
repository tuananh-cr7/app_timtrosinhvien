# Giải thích chi tiết: Thông báo & Real-time (Plan 3 - Phase 1)

## 📋 Tổng quan

Phần này mô tả việc triển khai **Firebase Cloud Messaging (FCM)** và **Real-time updates** cho ứng dụng "Nhà Trọ 360". Đây là tính năng nâng cao giúp người dùng nhận thông báo kịp thời và cập nhật dữ liệu real-time.

---

## 🔍 Phân tích từng phần

### 1. Firebase Cloud Messaging (FCM)

#### 1.1. Đăng ký token, gửi lên server

**Mục đích:**
- Mỗi thiết bị cần có một **FCM token** duy nhất để nhận push notification
- Token này phải được lưu trên server (Firestore) để server có thể gửi thông báo đến đúng thiết bị

**Cách hoạt động:**
```
1. App khởi động → Firebase Messaging tự động tạo token
2. App lấy token và gửi lên Firestore collection `users/{userId}/fcmTokens/{tokenId}`
3. Server/Admin có thể query tokens của user để gửi notification
```

**Cần implement:**
- Service để lấy FCM token: `FirebaseMessaging.instance.getToken()`
- Lưu token vào Firestore khi:
  - User đăng nhập
  - Token được refresh (Firebase tự động refresh token định kỳ)
- Xóa token khi user đăng xuất
- Xử lý token refresh: `FirebaseMessaging.instance.onTokenRefresh`

**Ví dụ cấu trúc Firestore:**
```json
users/{userId}/fcmTokens/{tokenId}
{
  "token": "fcm_token_string",
  "deviceId": "device_unique_id",
  "platform": "android" | "ios",
  "createdAt": timestamp,
  "lastUsed": timestamp
}
```

---

#### 1.2. Nhận thông báo foreground/background, mở đúng màn hình

**Mục đích:**
- App phải xử lý notification ở 3 trạng thái:
  - **Foreground**: App đang mở và active
  - **Background**: App đang chạy nhưng không active (minimized)
  - **Terminated**: App đã đóng hoàn toàn

**Cách hoạt động:**

**a) Foreground:**
- Notification không tự động hiển thị
- Cần tự implement UI để hiển thị (SnackBar, Dialog, hoặc custom notification banner)
- Xử lý trong `FirebaseMessaging.onMessage` listener

**b) Background:**
- Notification tự động hiển thị trong system tray
- Xử lý trong `FirebaseMessaging.onBackgroundMessage` (top-level function)
- Khi user tap notification → app mở và xử lý `getInitialMessage()` hoặc `onMessageOpenedApp`

**c) Terminated:**
- Notification hiển thị trong system tray
- Khi user tap → app mở và xử lý `getInitialMessage()`

**Deep Linking:**
- Mỗi notification cần có `data` payload chứa thông tin để navigate:
```json
{
  "notification": {
    "title": "Tin đăng được duyệt",
    "body": "Phòng trọ của bạn đã được duyệt"
  },
  "data": {
    "type": "room_approved",
    "roomId": "room123",
    "screen": "room_detail" // hoặc "posted_rooms"
  }
}
```

**Cần implement:**
- `FirebaseMessaging.onMessage` → Hiển thị in-app notification
- `FirebaseMessaging.onBackgroundMessage` → Top-level function để xử lý background
- `FirebaseMessaging.onMessageOpenedApp` → Xử lý khi tap notification (app đang background)
- `FirebaseMessaging.instance.getInitialMessage()` → Xử lý khi tap notification (app terminated)
- Navigation service để route đến đúng màn hình dựa trên `data.type` và `data.roomId`

---

### 2. Thông báo theo use case

#### 2.1. Chat mới (`newMessage`)

**Khi nào gửi:**
- Khi có tin nhắn mới trong conversation mà user chưa đọc
- Chỉ gửi nếu:
  - User không đang ở màn hình chat đó
  - Conversation chưa bị mute

**Payload:**
```json
{
  "type": "new_message",
  "conversationId": "conv123",
  "senderId": "user456",
  "senderName": "Nguyễn Văn A",
  "preview": "Xin chào, phòng còn trống không?",
  "roomId": "room789",
  "roomTitle": "Phòng trọ tại Cầu Giấy"
}
```

**Hành động khi tap:**
- Mở `ConversationDetailScreen` với `conversationId`
- Hoặc mở `RoomDetailScreen` nếu có `roomId`

---

#### 2.2. Tin được duyệt (`roomApproved` / `roomRejected`)

**Khi nào gửi:**
- Admin duyệt/từ chối tin đăng của user
- Gửi đến `ownerId` của room

**Payload:**
```json
{
  "type": "room_approved", // hoặc "room_rejected"
  "roomId": "room123",
  "roomTitle": "Phòng trọ tại Cầu Giấy",
  "reason": "Tin đăng hợp lệ" // chỉ có khi rejected
}
```

**Hành động khi tap:**
- Mở `PostedRoomsManagementScreen` với tab tương ứng:
  - `roomApproved` → Tab "Đang hiển thị"
  - `roomRejected` → Tab "Đang chờ duyệt" (để user xem lý do từ chối)

---

#### 2.3. Giá phòng yêu thích thay đổi (`roomPriceChanged`)

**Khi nào gửi:**
- Khi giá của phòng trong danh sách yêu thích thay đổi
- Cần theo dõi giá cũ và giá mới

**Payload:**
```json
{
  "type": "room_price_changed",
  "roomId": "room123",
  "roomTitle": "Phòng trọ tại Cầu Giấy",
  "oldPrice": 3.5,
  "newPrice": 3.0,
  "changePercent": -14.3
}
```

**Hành động khi tap:**
- Mở `RoomDetailScreen` với `roomId`
- Highlight phần giá để user dễ thấy thay đổi

**Cách implement tracking:**
- Lưu giá hiện tại trong `favorites` collection:
```json
favorites/{favoriteId}
{
  "userId": "user123",
  "roomId": "room456",
  "savedPrice": 3.5, // Giá khi user lưu
  "createdAt": timestamp
}
```
- Khi room được update, so sánh `room.priceMillion` với `favorite.savedPrice`
- Nếu khác → Tạo notification và cập nhật `savedPrice`

---

#### 2.4. Tin mới phù hợp (`roomMatched`)

**Khi nào gửi:**
- Khi có phòng mới phù hợp với bộ lọc tìm kiếm đã lưu của user
- Cần có hệ thống "Saved Searches" (tìm kiếm đã lưu)

**Payload:**
```json
{
  "type": "room_matched",
  "roomId": "room123",
  "roomTitle": "Phòng trọ tại Cầu Giấy",
  "searchId": "search456", // ID của saved search
  "matchReason": "Phù hợp với tìm kiếm: Phòng < 3 triệu, Cầu Giấy"
}
```

**Hành động khi tap:**
- Mở `RoomDetailScreen` với `roomId`

**Lưu ý:**
- Tính năng này cần có "Saved Searches" trước
- Có thể tạm thời bỏ qua nếu chưa implement Saved Searches

---

### 3. Real-time updates cơ bản (WebSocket connection manager)

**Mục đích:**
- Cập nhật dữ liệu real-time mà không cần refresh
- Ví dụ: Số lượng tin nhắn chưa đọc, trạng thái online/offline, giá phòng thay đổi

**Cách hoạt động với Firestore:**
- Firestore đã hỗ trợ real-time listeners (`StreamBuilder`, `snapshots()`)
- Không cần WebSocket riêng nếu chỉ dùng Firestore

**Các trường hợp cần real-time:**

**a) Chat messages:**
- Đã có: `ConversationsRepository.getMessagesStream()`
- ✅ Đã implement

**b) Unread notification count:**
- Đã có: `NotificationsRepository.getUnreadCountStream()`
- ✅ Đã implement

**c) Room status changes:**
- Theo dõi khi room status thay đổi (pending → active, active → rented)
- Có thể dùng `StreamBuilder` với `rooms/{roomId}` document

**d) Online/Offline status:**
- Cần implement presence system:
```dart
// Khi user online
Firestore.instance.collection('users').doc(userId).update({
  'isOnline': true,
  'lastSeen': FieldValue.serverTimestamp()
});

// Khi user offline (app lifecycle)
Firestore.instance.collection('users').doc(userId).update({
  'isOnline': false,
  'lastSeen': FieldValue.serverTimestamp()
});
```

**Connection Manager:**
- Quản lý kết nối Firestore listeners
- Tự động reconnect khi mất kết nối
- Cleanup listeners khi không cần thiết

---

## ✅ Đề xuất cải thiện cho dự án

### 1. **Thêm các loại notification còn thiếu:**

Hiện tại đã có:
- ✅ `roomApproved`
- ✅ `roomRejected`
- ✅ `roomPriceChanged`
- ✅ `newMessage`
- ✅ `roomMatched`
- ✅ `system`

**Nên thêm:**
- `roomHidden`: Khi admin ẩn tin đăng (user vi phạm)
- `roomRented`: Khi phòng yêu thích được đánh dấu "Đã cho thuê"
- `newFavoriteRoom`: Khi có người khác yêu thích phòng của bạn (cho chủ trọ)
- `bookingRequest`: Khi có người đặt lịch xem phòng (nếu có tính năng đặt lịch)

---

### 2. **Notification Settings (Cài đặt thông báo):**

Cho phép user bật/tắt từng loại notification:
```dart
class NotificationSettings {
  bool enableNewMessage = true;
  bool enableRoomApproved = true;
  bool enableRoomRejected = true;
  bool enablePriceChanged = true;
  bool enableRoomMatched = false; // Mặc định tắt
  bool enableSystem = true;
}
```

Lưu trong Firestore: `users/{userId}/settings/notifications`

---

### 3. **Notification Grouping:**

- Nhóm các notification cùng loại (ví dụ: 5 tin nhắn mới từ cùng 1 conversation)
- Hiển thị: "Bạn có 5 tin nhắn mới từ Nguyễn Văn A"

---

### 4. **Rich Notifications:**

- Hiển thị ảnh thumbnail của phòng trong notification
- Action buttons: "Xem ngay", "Đánh dấu đã đọc"
- Expandable notification với thông tin chi tiết

---

### 5. **Notification Badge:**

- Badge số trên icon "Thông báo" trong bottom nav (✅ đã có)
- Badge trên app icon (Android: notification badge, iOS: app badge)

---

### 6. **Notification History:**

- Lưu lịch sử notification đã gửi (để debug, analytics)
- Collection: `notificationHistory/{notificationId}`

---

### 7. **Scheduled Notifications:**

- Gửi notification vào thời điểm cụ thể (ví dụ: Nhắc nhở xem phòng vào 8h sáng)
- Cần dùng local notifications (`flutter_local_notifications`) hoặc server-side scheduling

---

### 8. **Notification Analytics:**

- Track: Số lượng notification gửi, tỷ lệ mở (open rate), tỷ lệ click
- Giúp tối ưu nội dung và thời gian gửi

---

## 📝 Checklist triển khai

### Phase 1: FCM Setup (Ưu tiên cao)
- [ ] Tích hợp `firebase_messaging` package (✅ đã có trong pubspec.yaml)
- [ ] Tạo `FCMService` để quản lý token
- [ ] Lưu token vào Firestore khi đăng nhập
- [ ] Xử lý token refresh
- [ ] Xóa token khi đăng xuất

### Phase 2: Notification Handlers (Ưu tiên cao)
- [ ] Implement `onMessage` (foreground)
- [ ] Implement `onBackgroundMessage` (background)
- [ ] Implement `onMessageOpenedApp` (background tap)
- [ ] Implement `getInitialMessage` (terminated tap)
- [ ] Tạo navigation service để route đến đúng màn hình

### Phase 3: Notification Types (Ưu tiên trung bình)
- [ ] Server-side: Tạo Cloud Function để gửi notification khi:
  - Room được approve/reject
  - Room price thay đổi
  - Có tin nhắn mới
- [ ] Client-side: Xử lý từng loại notification

### Phase 4: Notification Settings (Ưu tiên thấp)
- [ ] UI cho phép bật/tắt từng loại
- [ ] Lưu settings vào Firestore
- [ ] Kiểm tra settings trước khi hiển thị notification

### Phase 5: Real-time Updates (Ưu tiên trung bình)
- [ ] Presence system (online/offline)
- [ ] Connection manager
- [ ] Auto-reconnect logic

---

## 🎯 Kết luận

Phần "Thông báo & real-time" trong Plan 3 là **hợp lý và cần thiết** cho dự án. Tuy nhiên, nên:

1. **Ưu tiên Phase 1-2** (FCM setup và handlers) vì đây là nền tảng
2. **Tạm hoãn `roomMatched`** nếu chưa có Saved Searches
3. **Thêm Notification Settings** để user có quyền kiểm soát
4. **Sử dụng Firestore real-time** thay vì WebSocket riêng (đơn giản hơn, đã có sẵn)

Dự án hiện tại đã có:
- ✅ Notification model và repository
- ✅ Notification screen UI
- ✅ Unread count badge
- ✅ Firebase Messaging package

Cần bổ sung:
- ⚠️ FCM token management
- ⚠️ Notification handlers (foreground/background/terminated)
- ⚠️ Server-side notification sending (Cloud Functions)
- ⚠️ Deep linking navigation

