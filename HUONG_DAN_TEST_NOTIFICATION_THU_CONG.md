# Hướng dẫn Test Notification thủ công - Từng bước

## 🎯 Mục đích

Tạo notification thủ công trong Firestore để test UI và navigation của Notification Screen khi chưa có Cloud Functions.

---

## 📋 Bước 1: Lấy User ID

### Cách 1: Từ Firebase Console (Dễ nhất)

1. Vào Firebase Console: https://console.firebase.google.com/project/app-timtrosinhvien
2. Click **Authentication** (trong menu bên trái)
3. Tab **Users**
4. Copy **User UID** (dòng đầu tiên, ví dụ: `PNBnDATOYkdzbvJGHqAuqRmmx3p2`)

### Cách 2: Từ Firestore

1. Vào Firestore → Collection `rooms`
2. Click vào một room bạn đã đăng
3. Xem field `ownerId` → Đó chính là User ID của bạn

---

## 📝 Bước 2: Tạo Notification trong Firestore

### Bước 2.1: Vào Collection Notifications

1. Vào Firebase Console → **Firestore Database**
2. Trong menu bên trái, tìm collection **`notifications`**
   - Nếu chưa có, click **+ Start collection** → Nhập tên: `notifications`

### Bước 2.2: Tạo Document mới

1. Click **+ Add document** (nút xanh)
2. Document ID: Để **tự động** (hoặc nhập ID tùy ý, ví dụ: `test1`)
3. Click **Save** (để tạo document trống trước)

### Bước 2.3: Thêm các Fields

Click **+ Add field** và thêm từng field sau:

#### Field 1: `userId`
- **Field**: `userId`
- **Type**: Chọn **string**
- **Value**: Nhập User ID của bạn (ví dụ: `PNBnDATOYkdzbvJGHqAuqRmmx3p2`)

#### Field 2: `type`
- **Field**: `type`
- **Type**: Chọn **string**
- **Value**: Nhập `room_approved` (hoặc `room_rejected`, `room_price_changed`, `new_message`)

#### Field 3: `title`
- **Field**: `title`
- **Type**: Chọn **string**
- **Value**: Nhập `Tin đăng được duyệt`

#### Field 4: `body`
- **Field**: `body`
- **Type**: Chọn **string**
- **Value**: Nhập `Phòng trọ "Phòng trọ tại Cầu Giấy" đã được duyệt và hiển thị trên ứng dụng.`

#### Field 5: `data` (Map)
- **Field**: `data`
- **Type**: Chọn **map**
- Click **Add field** bên trong map:
  - **Field**: `roomId`
  - **Type**: **string**
  - **Value**: Nhập ID của một room (ví dụ: `6iOOWBacwlMZOT7j5soi`)
- Click **Add field** thêm:
  - **Field**: `roomTitle`
  - **Type**: **string**
  - **Value**: Nhập `Phòng trọ tại Cầu Giấy`

#### Field 6: `isRead`
- **Field**: `isRead`
- **Type**: Chọn **boolean**
- **Value**: Chọn `false`

#### Field 7: `createdAt`
- **Field**: `createdAt`
- **Type**: Chọn **timestamp**
- **Value**: Click icon **🕐 clock** → Chọn **Server Timestamp**

### Bước 2.4: Save

Click **Save** để lưu notification

---

## 🧪 Bước 3: Test trong App

1. **Mở app** trên điện thoại/emulator
2. **Đăng nhập** với user ID bạn vừa dùng
3. Vào tab **Thông báo** (icon chuông ở bottom nav)
4. **Xem notification** vừa tạo:
   - ✅ Notification hiển thị với title và body
   - ✅ Badge số thông báo chưa đọc tăng lên
   - ✅ Icon và màu sắc đúng với loại notification

5. **Tap vào notification**:
   - ✅ Mở màn hình **Tin đã đăng** (nếu type là `room_approved` hoặc `room_rejected`)
   - ✅ Hoặc mở **Room Detail** (nếu type là `room_price_changed`)

---

## 📋 Các loại Notification mẫu

### 1. Room Approved

```json
{
  "userId": "PNBnDATOYkdzbvJGHqAuqRmmx3p2",
  "type": "room_approved",
  "title": "Tin đăng được duyệt",
  "body": "Phòng trọ 'Phòng trọ tại Cầu Giấy' đã được duyệt và hiển thị trên ứng dụng.",
  "data": {
    "roomId": "6iOOWBacwlMZOT7j5soi",
    "roomTitle": "Phòng trọ tại Cầu Giấy"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

### 2. Room Rejected

```json
{
  "userId": "PNBnDATOYkdzbvJGHqAuqRmmx3p2",
  "type": "room_rejected",
  "title": "Tin đăng bị từ chối",
  "body": "Phòng trọ của bạn đã bị từ chối. Lý do: Không đáp ứng yêu cầu",
  "data": {
    "roomId": "6iOOWBacwlMZOT7j5soi",
    "roomTitle": "Phòng trọ tại Cầu Giấy",
    "reason": "Không đáp ứng yêu cầu"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

### 3. Room Price Changed

```json
{
  "userId": "PNBnDATOYkdzbvJGHqAuqRmmx3p2",
  "type": "room_price_changed",
  "title": "Giá phòng yêu thích giảm! 🎉",
  "body": "Phòng 'Phòng trọ tại Cầu Giấy' giảm từ 3.5 triệu xuống 3.0 triệu/tháng (14.3%)",
  "data": {
    "roomId": "6iOOWBacwlMZOT7j5soi",
    "roomTitle": "Phòng trọ tại Cầu Giấy",
    "oldPrice": "3.5",
    "newPrice": "3.0",
    "changePercent": "-14.3"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

### 4. New Message

```json
{
  "userId": "PNBnDATOYkdzbvJGHqAuqRmmx3p2",
  "type": "new_message",
  "title": "Nguyễn Văn A",
  "body": "Xin chào, phòng còn trống không?",
  "data": {
    "conversationId": "conv123",
    "senderId": "user456",
    "senderName": "Nguyễn Văn A",
    "roomId": "6iOOWBacwlMZOT7j5soi",
    "roomTitle": "Phòng trọ tại Cầu Giấy"
  },
  "isRead": false,
  "createdAt": [Server Timestamp]
}
```

---

## ✅ Checklist Test

- [ ] Lấy được User ID
- [ ] Tạo được notification trong Firestore
- [ ] Notification hiển thị trong app (tab Thông báo)
- [ ] Badge số thông báo chưa đọc tăng
- [ ] Tap notification → Mở đúng màn hình
- [ ] Đánh dấu đã đọc hoạt động
- [ ] Xóa notification hoạt động
- [ ] Test với nhiều loại notification khác nhau

---

## 🎯 Test nhanh nhất

**Tạo notification "Room Approved":**

1. Firestore → `notifications` → **+ Add document**
2. Thêm fields:
   - `userId`: User ID của bạn
   - `type`: `room_approved`
   - `title`: `Tin đăng được duyệt`
   - `body`: `Phòng trọ của bạn đã được duyệt`
   - `data` (map):
     - `roomId`: ID của một room
     - `roomTitle`: Tên phòng
   - `isRead`: `false`
   - `createdAt`: Server Timestamp
3. **Save**
4. Mở app → Tab **Thông báo** → Xem notification

---

## 💡 Tips

1. **Tạo nhiều notifications** để test:
   - Badge số thông báo
   - Scroll trong danh sách
   - Đánh dấu đã đọc/chưa đọc

2. **Test với các loại khác nhau**:
   - Đảm bảo UI hiển thị đúng icon và màu sắc

3. **Kiểm tra navigation**:
   - Đảm bảo `roomId` có hợp lệ (room phải tồn tại trong Firestore)

---

## 🐛 Troubleshooting

### Notification không hiển thị?

1. **Kiểm tra `userId`**:
   - Phải đúng User ID của bạn
   - Kiểm tra trong Authentication

2. **Kiểm tra `createdAt`**:
   - Phải là Server Timestamp, không phải manual timestamp

3. **Kiểm tra app**:
   - Đảm bảo đăng nhập với đúng user
   - Pull to refresh trong Notification Screen

### Tap notification không mở màn hình?

1. **Kiểm tra `data.roomId`**:
   - Room phải tồn tại trong Firestore
   - Room ID phải đúng

2. **Kiểm tra notification type**:
   - Phải là một trong: `room_approved`, `room_rejected`, `room_price_changed`, `new_message`

---

## 📚 Xem thêm

- `TEST_KHONG_CO_CLOUD_FUNCTIONS.md` - Tổng quan về test không có Cloud Functions
- `TAO_NOTIFICATION_THU_CONG.md` - Hướng dẫn tạo notification thủ công

