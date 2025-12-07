# Hướng dẫn Test Notifications - Nhà Trọ 360

## 📋 Tổng quan

Hướng dẫn này sẽ giúp bạn test các Cloud Functions để gửi push notifications trong ứng dụng Nhà Trọ 360.

---

## ⚠️ QUAN TRỌNG: Deploy Functions trước khi test

**Nếu bạn thấy màn hình Functions trống ("Waiting for your first deploy")**, bạn cần:

1. **Upgrade Firebase Plan lên Blaze** (nếu chưa):
   - Vào: https://console.firebase.google.com/project/app-timtrosinhvien/usage/details
   - Click **Upgrade** → Chọn **Blaze plan**
   - Thêm payment method
   - Đợi upgrade hoàn tất (2-5 phút)

2. **Deploy Functions**:
   ```bash
   DEPLOY_FUNCTIONS.bat
   ```
   Hoặc xem hướng dẫn chi tiết trong: `HUONG_DAN_DEPLOY_CHI_TIET.md`

3. **Kiểm tra Functions đã deploy**:
   - Vào Firebase Console → **Functions**
   - Bạn sẽ thấy 4 functions: `onRoomStatusChanged`, `onRoomPriceChanged`, `onNewMessage`, `testNotification`

**Sau khi deploy xong, mới có thể test!**

---

## ✅ Kiểm tra Functions đã deploy

### 1. Kiểm tra trong Firebase Console

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project `app-timtrosinhvien`
3. Vào **Functions** (trong menu bên trái)
4. Kiểm tra xem các functions sau đã có:
   - `onRoomStatusChanged`
   - `onRoomPriceChanged`
   - `onNewMessage`
   - `testNotification`

### 2. Kiểm tra bằng CLI

```bash
firebase functions:list
```

---

## 🧪 Test Functions

### Test 1: Room Status Changed (Approve/Reject)

**Mục đích**: Test notification khi room được approve hoặc reject.

#### Cách test:

**Bước 1: Tạo một room mới (status = pending)**

1. Mở app và đăng nhập
2. Vào **Đăng tin** → Điền thông tin → **Hoàn thành**
3. Room sẽ được tạo với `status: 'pending'`

**Bước 2: Approve room từ Firebase Console**

1. Vào Firebase Console → **Firestore Database**
2. Tìm collection `rooms`
3. Tìm room vừa tạo (có `status: 'pending'`)
4. Click vào room đó
5. Sửa field `status` từ `pending` thành `active`
6. Click **Update**

**Kết quả mong đợi:**
- ✅ Function `onRoomStatusChanged` được trigger
- ✅ Notification document được tạo trong `notifications` collection
- ✅ Push notification được gửi đến owner của room
- ✅ Trong app, user sẽ thấy notification trong tab **Thông báo**
- ✅ Badge số trên tab **Thông báo** tăng lên

**Bước 3: Test Reject**

1. Sửa `status` từ `active` thành `rejected`
2. (Optional) Thêm field `rejectionReason: "Lý do từ chối"`
3. Click **Update**

**Kết quả mong đợi:**
- ✅ Notification với type `room_rejected` được gửi
- ✅ Nếu có `rejectionReason`, nó sẽ hiển thị trong notification body

---

### Test 2: Room Price Changed

**Mục đích**: Test notification khi giá phòng thay đổi.

#### Cách test:

**Bước 1: Lưu một room vào favorites**

1. Mở app và đăng nhập
2. Tìm một room có `status: 'active'`
3. Click vào room → Click icon **Yêu thích** (trái tim)
4. Room được lưu vào favorites

**Bước 2: Thay đổi giá phòng**

1. Vào Firebase Console → **Firestore Database**
2. Tìm collection `rooms`
3. Tìm room đã lưu vào favorites
4. Sửa field `priceMillion` (ví dụ: từ `3.5` thành `3.0`)
5. Click **Update**

**Kết quả mong đợi:**
- ✅ Function `onRoomPriceChanged` được trigger
- ✅ Notification được gửi đến tất cả users đã lưu room vào favorites
- ✅ Notification body hiển thị giá cũ và giá mới
- ✅ Field `savedPrice` trong `favorites` collection được cập nhật

**Lưu ý:**
- Chỉ gửi notification nếu room có `status: 'active'`
- Nếu giá tăng, notification sẽ có title "Giá phòng yêu thích thay đổi"
- Nếu giá giảm, notification sẽ có title "Giá phòng yêu thích giảm! 🎉"

---

### Test 3: New Message

**Mục đích**: Test notification khi có tin nhắn mới.

#### Cách test:

**Bước 1: Tạo conversation (nếu chưa có)**

1. Mở app và đăng nhập với user A
2. Vào một room detail
3. Click **Chat với chủ trọ** (hoặc tương tự)
4. Gửi một tin nhắn

**Bước 2: Gửi tin nhắn từ user khác**

**Cách 1: Từ app khác**
1. Đăng nhập với user B (user khác, không phải owner của room)
2. Vào cùng conversation
3. Gửi tin nhắn

**Cách 2: Từ Firebase Console (test nhanh)**
1. Vào Firebase Console → **Firestore Database**
2. Tìm collection `conversations`
3. Tìm conversation có `participantIds` chứa user A và user B
4. Vào subcollection `messages`
5. Click **Add document**
6. Thêm fields:
   ```json
   {
     "senderId": "userB_id",
     "content": "Xin chào, phòng còn trống không?",
     "type": "text",
     "createdAt": [Server Timestamp],
     "isRead": false
   }
   ```

**Kết quả mong đợi:**
- ✅ Function `onNewMessage` được trigger
- ✅ Notification được gửi đến user A (người nhận)
- ✅ Notification title là tên của user B (sender)
- ✅ Notification body là preview của tin nhắn
- ✅ Field `unreadCount` trong conversation được tăng lên
- ✅ Field `lastMessage` và `lastMessageAt` được cập nhật

---

### Test 4: Test Notification (HTTP Function)

**Mục đích**: Test gửi notification trực tiếp qua HTTP.

#### Cách test:

**Bước 1: Lấy userId**

1. Vào Firebase Console → **Authentication**
2. Copy `User UID` của một user

**Bước 2: Gửi HTTP request**

**Cách 1: Dùng Postman**

1. Mở Postman
2. Tạo request mới: **POST**
3. URL: `https://us-central1-app-timtrosinhvien.cloudfunctions.net/testNotification`
4. Headers:
   ```
   Content-Type: application/json
   ```
5. Body (raw JSON):
   ```json
   {
     "userId": "user_id_here",
     "title": "Test Notification",
     "body": "Đây là notification test",
     "type": "test",
     "data": {
       "roomId": "room123",
       "roomTitle": "Phòng test"
     }
   }
   ```
6. Click **Send**

**Cách 2: Dùng curl**

```bash
curl -X POST https://us-central1-app-timtrosinhvien.cloudfunctions.net/testNotification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_id_here",
    "title": "Test Notification",
    "body": "Đây là notification test",
    "type": "test"
  }'
```

**Cách 3: Dùng PowerShell**

```powershell
$body = @{
    userId = "user_id_here"
    title = "Test Notification"
    body = "Đây là notification test"
    type = "test"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://us-central1-app-timtrosinhvien.cloudfunctions.net/testNotification" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

**Kết quả mong đợi:**
- ✅ Response: `{"success": true, "message": "Notification sent"}`
- ✅ Notification được gửi đến user
- ✅ User nhận được notification trong app

---

## 🔍 Kiểm tra Logs

### Xem logs trong Firebase Console

1. Vào Firebase Console → **Functions**
2. Click vào function cần xem (ví dụ: `onRoomStatusChanged`)
3. Vào tab **Logs**
4. Xem các log messages

### Xem logs bằng CLI

```bash
# Xem tất cả logs
firebase functions:log

# Xem logs của function cụ thể
firebase functions:log --only onRoomStatusChanged

# Xem logs real-time
firebase functions:log --follow
```

### Các log messages quan trọng

- ✅ `Room {roomId} approved, notification sent to {userId}` - Room được approve
- ✅ `Price change notification sent to {count} users for room {roomId}` - Giá thay đổi
- ✅ `New message notification sent to {userId} for conversation {conversationId}` - Tin nhắn mới
- ✅ `Successfully sent notification to {count} devices` - Gửi thành công
- ⚠️ `No FCM tokens found for user {userId}` - User chưa có FCM token
- ❌ `Error sending notification` - Lỗi khi gửi

---

## 🐛 Troubleshooting

### 1. Notification không đến

**Kiểm tra:**
- ✅ User đã đăng nhập và có FCM token trong `users/{userId}/fcmTokens`
- ✅ App có quyền nhận notification (đã grant permission)
- ✅ Device có internet connection
- ✅ Xem logs để tìm lỗi

**Giải pháp:**
- Mở app và đăng nhập lại để refresh FCM token
- Kiểm tra notification settings trong app
- Xem logs trong Firebase Console

### 2. Function không trigger

**Kiểm tra:**
- ✅ Function đã được deploy chưa
- ✅ Firestore rules cho phép Functions đọc/ghi
- ✅ Document thực sự thay đổi (không phải update cùng giá trị)

**Giải pháp:**
- Deploy lại functions: `firebase deploy --only functions`
- Kiểm tra Firestore rules
- Xem logs để tìm lỗi

### 3. Invalid token errors

**Nguyên nhân:**
- Token đã hết hạn hoặc không hợp lệ
- User đã gỡ app

**Giải pháp:**
- Functions tự động xóa invalid tokens
- User cần mở app lại để lấy token mới

---

## 📊 Test Checklist

### Test Room Status Changed
- [ ] Tạo room mới với status pending
- [ ] Approve room → Kiểm tra notification
- [ ] Reject room → Kiểm tra notification
- [ ] Kiểm tra notification document trong Firestore
- [ ] Kiểm tra notification hiển thị trong app

### Test Room Price Changed
- [ ] Lưu room vào favorites
- [ ] Thay đổi giá phòng
- [ ] Kiểm tra notification được gửi
- [ ] Kiểm tra savedPrice được cập nhật
- [ ] Test với giá tăng và giá giảm

### Test New Message
- [ ] Tạo conversation
- [ ] Gửi tin nhắn mới
- [ ] Kiểm tra notification được gửi đến recipient
- [ ] Kiểm tra unreadCount được cập nhật
- [ ] Kiểm tra lastMessage được cập nhật

### Test HTTP Function
- [ ] Gửi test notification qua HTTP
- [ ] Kiểm tra notification đến user
- [ ] Kiểm tra response success

---

## 🎯 Best Practices

1. **Test trên real device**: Notification hoạt động tốt hơn trên real device
2. **Test với nhiều users**: Đảm bảo notification đến đúng user
3. **Kiểm tra logs**: Luôn xem logs để debug
4. **Test offline/online**: Đảm bảo notification sync khi online lại
5. **Test với nhiều devices**: Một user có thể có nhiều devices

---

## 📝 Notes

- Functions chỉ trigger khi có thay đổi thực sự (không phải update cùng giá trị)
- Notification sẽ được tạo trong Firestore collection `notifications`
- Push notification và in-app notification là 2 thứ khác nhau
- FCM tokens được tự động cleanup khi invalid

