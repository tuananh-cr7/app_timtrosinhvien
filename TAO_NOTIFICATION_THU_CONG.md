# Hướng dẫn Tạo Notification thủ công trong Firestore

## 🎯 Mục đích

Tạo notification thủ công để test UI và navigation của Notification Screen khi chưa có Cloud Functions.

---

## 📝 Cách tạo Notification

### Bước 1: Vào Firebase Console

1. Truy cập: https://console.firebase.google.com/project/app-timtrosinhvien/firestore
2. Chọn collection **`notifications`**

### Bước 2: Tạo Document mới

1. Click **Add document**
2. Document ID: Để tự động (hoặc nhập ID tùy ý)
3. Thêm các fields sau:

---

## 📋 Các loại Notification mẫu

### 1. Room Approved (Tin đăng được duyệt)

**Fields:**
```
userId: [String] - User ID của bạn (lấy từ Authentication)
type: [String] - "room_approved"
title: [String] - "Tin đăng được duyệt"
body: [String] - "Phòng trọ 'Phòng trọ tại Cầu Giấy' đã được duyệt và hiển thị trên ứng dụng."
data: [Map] - {
  roomId: [String] - ID của phòng (ví dụ: "room123")
  roomTitle: [String] - "Phòng trọ tại Cầu Giấy"
}
isRead: [Boolean] - false
createdAt: [Timestamp] - Server Timestamp (click icon clock)
```

**Cách tạo:**
1. Click **Add document**
2. Thêm từng field:
   - `userId`: Type **string**, nhập User ID
   - `type`: Type **string**, nhập `room_approved`
   - `title`: Type **string**, nhập `Tin đăng được duyệt`
   - `body`: Type **string**, nhập nội dung
   - `data`: Type **map**, click **Add field**:
     - `roomId`: Type **string**
     - `roomTitle`: Type **string**
   - `isRead`: Type **boolean**, chọn `false`
   - `createdAt`: Type **timestamp**, click icon **clock** → Chọn **Server Timestamp**
3. Click **Save**

---

### 2. Room Rejected (Tin đăng bị từ chối)

**Fields:**
```
userId: [String]
type: [String] - "room_rejected"
title: [String] - "Tin đăng bị từ chối"
body: [String] - "Phòng trọ của bạn đã bị từ chối. Lý do: Không đáp ứng yêu cầu"
data: [Map] - {
  roomId: [String]
  roomTitle: [String]
  reason: [String] - "Không đáp ứng yêu cầu"
}
isRead: [Boolean] - false
createdAt: [Timestamp] - Server Timestamp
```

---

### 3. Room Price Changed (Giá phòng thay đổi)

**Fields:**
```
userId: [String]
type: [String] - "room_price_changed"
title: [String] - "Giá phòng yêu thích giảm! 🎉"
body: [String] - "Phòng 'Phòng trọ tại Cầu Giấy' giảm từ 3.5 triệu xuống 3.0 triệu/tháng (14.3%)"
data: [Map] - {
  roomId: [String]
  roomTitle: [String]
  oldPrice: [String] - "3.5"
  newPrice: [String] - "3.0"
  changePercent: [String] - "-14.3"
}
isRead: [Boolean] - false
createdAt: [Timestamp] - Server Timestamp
```

---

### 4. New Message (Tin nhắn mới)

**Fields:**
```
userId: [String]
type: [String] - "new_message"
title: [String] - "Nguyễn Văn A"
body: [String] - "Xin chào, phòng còn trống không?"
data: [Map] - {
  conversationId: [String]
  senderId: [String]
  senderName: [String] - "Nguyễn Văn A"
  roomId: [String]
  roomTitle: [String]
}
isRead: [Boolean] - false
createdAt: [Timestamp] - Server Timestamp
```

---

## 🔍 Lấy User ID

**Cách 1: Từ Firebase Console**
1. Vào **Authentication**
2. Copy **User UID**

**Cách 2: Từ app**
1. Mở app và đăng nhập
2. Xem console log khi đăng nhập
3. Hoặc vào Firebase Console → Firestore → `users` → Tìm user của bạn

---

## 🧪 Test sau khi tạo

1. **Mở app** → Tab **Thông báo**
2. **Xem notification** vừa tạo
3. **Tap notification** → Kiểm tra mở đúng màn hình:
   - `room_approved` / `room_rejected` → Mở **Tin đã đăng**
   - `room_price_changed` → Mở **Room Detail**
   - `new_message` → Mở **Conversation** (hoặc Room Detail nếu chưa có conversation screen)

---

## 💡 Tips

1. **Tạo nhiều notifications** để test:
   - Badge số thông báo chưa đọc
   - Scroll trong danh sách
   - Đánh dấu đã đọc/chưa đọc

2. **Test với các loại khác nhau**:
   - Đảm bảo UI hiển thị đúng icon và màu sắc

3. **Test navigation**:
   - Đảm bảo tap notification mở đúng màn hình
   - Kiểm tra `roomId` có hợp lệ không

---

## 📚 Xem thêm

- `TEST_KHONG_CO_CLOUD_FUNCTIONS.md` - Tổng quan về test không có Cloud Functions
- `HUONG_DAN_TEST_NOTIFICATIONS.md` - Hướng dẫn test đầy đủ (khi có Cloud Functions)

