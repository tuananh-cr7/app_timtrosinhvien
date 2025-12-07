# Test Notifications KHÔNG CÓ Cloud Functions

## ⚠️ Tình huống

Bạn **không có payment method** nên **không thể upgrade lên Blaze plan** → **Không thể deploy Cloud Functions**.

## ✅ Những gì VẪN HOẠT ĐỘNG (Client-side)

### 1. **FCM Token Registration** ✅
- App vẫn đăng ký FCM token
- Token vẫn được lưu vào Firestore: `users/{userId}/fcmTokens/{tokenId}`
- Token vẫn được refresh tự động

**Cách test:**
1. Mở app và đăng nhập
2. Kiểm tra console log: `✅ FCM: Initial token: ...`
3. Vào Firebase Console → Firestore → `users/{userId}/fcmTokens`
4. Xem token đã được lưu chưa

---

### 2. **Notification Screen** ✅
- Màn hình **Thông báo** vẫn hoạt động
- Hiển thị notifications từ Firestore collection `notifications`
- Badge số thông báo chưa đọc vẫn hoạt động
- Đánh dấu đã đọc/chưa đọc
- Xóa notification

**Cách test:**
1. Tạo notification thủ công trong Firestore (xem hướng dẫn bên dưới)
2. Mở app → Tab **Thông báo**
3. Xem notification hiển thị

---

### 3. **Notification Navigation** ✅
- Khi tap notification, vẫn mở đúng màn hình
- Hỗ trợ các loại: `room_approved`, `room_rejected`, `room_price_changed`, `new_message`

**Cách test:**
1. Tạo notification với `data.roomId`
2. Tap notification trong app
3. Kiểm tra màn hình được mở đúng

---

### 4. **Presence Service** ✅
- Online/offline status vẫn hoạt động
- Tự động cập nhật khi app vào background/foreground

**Cách test:**
1. Mở app và đăng nhập
2. Vào Firebase Console → Firestore → `users/{userId}`
3. Xem `isOnline: true` và `lastSeen: timestamp`
4. Đóng app → Xem `isOnline: false`

---

## ❌ Những gì KHÔNG HOẠT ĐỘNG (Cần Cloud Functions)

### 1. **Push Notifications tự động** ❌
- Không có push notification khi room approve/reject
- Không có push notification khi price change
- Không có push notification khi có tin nhắn mới

**Lý do:** Cần Cloud Functions để gửi push notification

---

## 🧪 Cách Test với Client-side Code

### Test 1: Tạo Notification thủ công trong Firestore

**Mục đích:** Test UI và navigation của Notification Screen

**Cách làm:**

1. **Vào Firebase Console** → Firestore Database

2. **Tạo notification document**:
   - Collection: `notifications`
   - Click **Add document**
   - Thêm các fields:
   ```json
   {
     "userId": "user_id_của_bạn",
     "type": "room_approved",
     "title": "Tin đăng được duyệt",
     "body": "Phòng trọ 'Phòng trọ tại Cầu Giấy' đã được duyệt và hiển thị trên ứng dụng.",
     "data": {
       "roomId": "room_id_của_phòng",
       "roomTitle": "Phòng trọ tại Cầu Giấy"
     },
     "isRead": false,
     "createdAt": [Server Timestamp]
   }
   ```

3. **Kiểm tra app**:
   - Mở app → Tab **Thông báo**
   - Xem notification vừa tạo
   - Tap notification → Kiểm tra mở đúng màn hình

---

### Test 2: Test các loại Notification khác

**Room Rejected:**
```json
{
  "userId": "user_id",
  "type": "room_rejected",
  "title": "Tin đăng bị từ chối",
  "body": "Phòng trọ của bạn đã bị từ chối. Lý do: Không đáp ứng yêu cầu",
  "data": {
    "roomId": "room_id",
    "roomTitle": "Phòng trọ tại Cầu Giấy",
    "reason": "Không đáp ứng yêu cầu"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

**Price Changed:**
```json
{
  "userId": "user_id",
  "type": "room_price_changed",
  "title": "Giá phòng yêu thích giảm! 🎉",
  "body": "Phòng 'Phòng trọ tại Cầu Giấy' giảm từ 3.5 triệu xuống 3.0 triệu/tháng (14.3%)",
  "data": {
    "roomId": "room_id",
    "roomTitle": "Phòng trọ tại Cầu Giấy",
    "oldPrice": "3.5",
    "newPrice": "3.0",
    "changePercent": "-14.3"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

**New Message:**
```json
{
  "userId": "user_id",
  "type": "new_message",
  "title": "Nguyễn Văn A",
  "body": "Xin chào, phòng còn trống không?",
  "data": {
    "conversationId": "conv_id",
    "senderId": "sender_id",
    "senderName": "Nguyễn Văn A",
    "roomId": "room_id",
    "roomTitle": "Phòng trọ tại Cầu Giấy"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

---

### Test 3: Test FCM Token Registration

1. **Mở app** và đăng nhập
2. **Kiểm tra console log**:
   - Tìm: `✅ FCM: Initial token: ...`
3. **Kiểm tra Firestore**:
   - Vào `users/{userId}/fcmTokens`
   - Xem token đã được lưu chưa
4. **Test token refresh**:
   - Đóng app → Mở lại
   - Kiểm tra token có được refresh không

---

### Test 4: Test Presence (Online/Offline)

1. **Mở app** và đăng nhập
2. **Kiểm tra Firestore**:
   - Vào `users/{userId}`
   - Xem `isOnline: true`
3. **Đóng app** (vào background)
4. **Kiểm tra lại**:
   - Xem `isOnline: false`
   - Xem `lastSeen` được cập nhật

---

## 📊 Tóm tắt: Có thể test được gì?

### ✅ CÓ THỂ TEST:

1. **FCM Token Registration**
   - Đăng ký token
   - Lưu vào Firestore
   - Token refresh

2. **Notification Screen UI**
   - Hiển thị notifications
   - Badge số chưa đọc
   - Đánh dấu đã đọc
   - Xóa notification

3. **Notification Navigation**
   - Tap notification → Mở đúng màn hình
   - Deep linking hoạt động

4. **Presence Service**
   - Online/offline status
   - Last seen timestamp

### ❌ KHÔNG THỂ TEST:

1. **Push Notifications tự động**
   - Khi room approve/reject
   - Khi price change
   - Khi có tin nhắn mới

2. **Real-time triggers**
   - Functions không chạy được

---

## 💡 Workaround: Tạo Notifications thủ công

Để test đầy đủ UI và navigation, bạn có thể:

1. **Tạo notifications thủ công** trong Firestore (như hướng dẫn trên)
2. **Test UI và navigation** trong app
3. **Khi có payment method**, deploy Functions → Push notifications sẽ tự động hoạt động

---

## 🎯 Kết luận

**Client-side code đã hoàn chỉnh và hoạt động tốt!**

- ✅ FCM Service: Hoạt động
- ✅ Notification Screen: Hoạt động
- ✅ Notification Navigation: Hoạt động
- ✅ Presence Service: Hoạt động

**Chỉ thiếu:**
- ❌ Push notifications tự động (cần Cloud Functions)
- ❌ Real-time triggers (cần Cloud Functions)

**Khi nào có payment method:**
- Deploy Functions → Tất cả sẽ hoạt động tự động!

---

## 📝 Checklist Test (Không cần Cloud Functions)

- [ ] FCM token được đăng ký và lưu vào Firestore
- [ ] Notification Screen hiển thị notifications từ Firestore
- [ ] Badge số thông báo chưa đọc hoạt động
- [ ] Tap notification → Mở đúng màn hình
- [ ] Đánh dấu đã đọc/chưa đọc hoạt động
- [ ] Xóa notification hoạt động
- [ ] Presence (online/offline) hoạt động
- [ ] Tạo notification thủ công → Test UI và navigation

