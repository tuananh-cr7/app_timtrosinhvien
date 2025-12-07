# Kiểm tra chức năng Notifications - Nhà Trọ 360

## ✅ Trạng thái hiện tại

### 1. **Client-side (Flutter App)** ✅ HOÀN THÀNH

#### FCM Service (`lib/core/services/fcm_service.dart`)
- ✅ Đăng ký FCM token
- ✅ Lưu token vào Firestore: `users/{userId}/fcmTokens/{tokenId}`
- ✅ Xử lý token refresh tự động
- ✅ Xử lý notification foreground
- ✅ Xử lý notification background
- ✅ Xử lý notification terminated
- ✅ Background message handler
- ✅ Xóa token khi đăng xuất

#### Notification Navigation Service (`lib/core/services/notification_navigation_service.dart`)
- ✅ Xử lý navigation khi tap notification
- ✅ Hỗ trợ các loại: `new_message`, `room_approved`, `room_rejected`, `room_price_changed`, `room_matched`
- ✅ Xử lý pending notification
- ✅ Mở đúng màn hình dựa trên notification type

#### Presence Service (`lib/core/services/presence_service.dart`)
- ✅ Quản lý online/offline status
- ✅ Tự động cập nhật khi app lifecycle thay đổi
- ✅ Lưu `isOnline` và `lastSeen` vào Firestore

#### Tích hợp vào Main App
- ✅ Khởi tạo FCM service khi app start
- ✅ Đăng ký background message handler
- ✅ Quản lý app lifecycle
- ✅ Xử lý pending notification

#### Tích hợp vào Auth Service
- ✅ Xóa FCM token khi đăng xuất
- ✅ Cleanup presence service khi đăng xuất

---

### 2. **Server-side (Cloud Functions)** ✅ HOÀN THÀNH

#### Functions đã implement:

**a) `onRoomStatusChanged`**
- ✅ Trigger: `rooms/{roomId}` - onUpdate
- ✅ Xử lý khi status thay đổi: `pending → active` (approve)
- ✅ Xử lý khi status thay đổi: `pending → rejected` (reject)
- ✅ Gửi notification đến owner
- ✅ Tạo notification document trong Firestore
- ✅ Null safety checks

**b) `onRoomPriceChanged`**
- ✅ Trigger: `rooms/{roomId}` - onUpdate
- ✅ Xử lý khi `priceMillion` thay đổi
- ✅ Chỉ gửi cho users đã lưu vào favorites
- ✅ Cập nhật `savedPrice` trong favorites
- ✅ Hiển thị giá cũ và giá mới trong notification
- ✅ Phân biệt giá tăng/giảm

**c) `onNewMessage`**
- ✅ Trigger: `conversations/{convId}/messages/{msgId}` - onCreate
- ✅ Gửi notification đến recipient (không phải sender)
- ✅ Cập nhật `unreadCount` trong conversation
- ✅ Cập nhật `lastMessage` và `lastMessageAt`
- ✅ Preview tin nhắn (giới hạn 100 ký tự)

**d) `testNotification`**
- ✅ HTTP function để test
- ✅ Nhận userId, title, body, type, data
- ✅ Gửi notification trực tiếp

#### Helper Functions:
- ✅ `getUserFCMTokens()` - Lấy FCM tokens của user
- ✅ `sendNotificationToUser()` - Gửi notification
- ✅ `removeInvalidToken()` - Xóa invalid tokens tự động
- ✅ `createNotificationDocument()` - Tạo notification document

#### Build Status:
- ✅ TypeScript compiled successfully
- ✅ File `lib/index.js` đã được tạo
- ✅ Không có lỗi build

---

### 3. **Cấu trúc Firestore** ✅ ĐÃ CẤU HÌNH

#### FCM Tokens:
```
users/{userId}/fcmTokens/{tokenId}
{
  "token": "fcm_token_string",
  "platform": "android" | "ios",
  "createdAt": timestamp,
  "lastUsed": timestamp
}
```

#### User Presence:
```
users/{userId}
{
  "isOnline": true/false,
  "lastSeen": timestamp
}
```

#### Notifications:
```
notifications/{notificationId}
{
  "userId": "user_id",
  "type": "room_approved" | "room_rejected" | "room_price_changed" | "new_message",
  "title": "Title",
  "body": "Body",
  "data": {...},
  "isRead": false,
  "createdAt": timestamp
}
```

---

## ⚠️ Cần kiểm tra

### 1. **Functions đã deploy chưa?**
```bash
firebase functions:list
```

Nếu chưa deploy, chạy:
```bash
DEPLOY_FUNCTIONS.bat
```

### 2. **FCM Token có được lưu không?**
1. Mở app và đăng nhập
2. Vào Firebase Console → Firestore
3. Kiểm tra: `users/{userId}/fcmTokens` có token không

### 3. **Firestore Rules có cho phép không?**
Kiểm tra `firestore.rules`:
- Functions có quyền đọc/ghi (admin privileges)
- Users có quyền đọc/ghi FCM tokens của chính mình

---

## 🧪 Test Checklist

### Test 1: FCM Token Registration
- [ ] Mở app và đăng nhập
- [ ] Kiểm tra console log: `✅ FCM: Initial token: ...`
- [ ] Kiểm tra Firestore: `users/{userId}/fcmTokens` có token
- [ ] Kiểm tra token được refresh khi cần

### Test 2: Room Status Changed
- [ ] Tạo room mới (status = pending)
- [ ] Approve room từ Firebase Console
- [ ] Kiểm tra notification trong app
- [ ] Kiểm tra notification document trong Firestore
- [ ] Test reject room

### Test 3: Room Price Changed
- [ ] Lưu room vào favorites
- [ ] Thay đổi giá phòng từ Firebase Console
- [ ] Kiểm tra notification được gửi
- [ ] Kiểm tra savedPrice được cập nhật

### Test 4: New Message
- [ ] Tạo conversation
- [ ] Gửi tin nhắn mới
- [ ] Kiểm tra notification đến recipient
- [ ] Kiểm tra unreadCount được cập nhật

### Test 5: HTTP Test Function
- [ ] Gửi test notification qua HTTP
- [ ] Kiểm tra notification đến user
- [ ] Kiểm tra response success

---

## 📊 Kết luận

### ✅ Đã hoàn thành:
1. **Client-side**: FCM service, notification navigation, presence service
2. **Server-side**: 4 Cloud Functions đã implement và build thành công
3. **Documentation**: Hướng dẫn test chi tiết
4. **Scripts**: Scripts để build và deploy

### ⚠️ Cần làm:
1. **Deploy Functions**: Chạy `DEPLOY_FUNCTIONS.bat` để deploy lên Firebase
2. **Test thực tế**: Test từng function theo hướng dẫn trong `HUONG_DAN_TEST_NOTIFICATIONS.md`
3. **Monitor logs**: Xem logs để đảm bảo functions hoạt động đúng

### 🎯 Next Steps:
1. Deploy functions: `DEPLOY_FUNCTIONS.bat`
2. Test từng function theo checklist
3. Monitor logs: `firebase functions:log`
4. Fix bugs nếu có

---

## 📚 Tài liệu tham khảo

- `HUONG_DAN_TEST_NOTIFICATIONS.md` - Hướng dẫn test chi tiết
- `HUONG_DAN_DEPLOY_FUNCTIONS.md` - Hướng dẫn deploy
- `TEST_NOTIFICATIONS.bat` - Script test nhanh
- `DEPLOY_FUNCTIONS.bat` - Script deploy

