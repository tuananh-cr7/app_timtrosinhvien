# Tóm tắt: Cách Test Notifications

## 🚀 Quick Start

### Bước 1: Deploy Functions (nếu chưa deploy)
```bash
DEPLOY_FUNCTIONS.bat
```

### Bước 2: Test từng function

---

## 📱 Test 1: Room Status Changed

**Cách test nhanh:**

1. **Mở app** → Đăng nhập → **Đăng tin** → Hoàn thành
2. **Vào Firebase Console** → Firestore → Tìm room vừa tạo
3. **Sửa status**: `pending` → `active` (hoặc `rejected`)
4. **Kiểm tra app**: Vào tab **Thông báo** → Xem notification mới

**Kết quả mong đợi:**
- ✅ Notification hiển thị trong app
- ✅ Badge số trên tab **Thông báo** tăng
- ✅ Tap notification → Mở màn hình **Tin đã đăng**

---

## 💰 Test 2: Room Price Changed

**Cách test nhanh:**

1. **Mở app** → Tìm một room → Click **Yêu thích** (trái tim)
2. **Vào Firebase Console** → Firestore → Tìm room đã lưu
3. **Sửa priceMillion**: Ví dụ `3.5` → `3.0`
4. **Kiểm tra app**: Vào tab **Thông báo** → Xem notification

**Kết quả mong đợi:**
- ✅ Notification: "Giá phòng yêu thích giảm! 🎉"
- ✅ Hiển thị giá cũ và giá mới
- ✅ Tap notification → Mở **Room Detail**

---

## 💬 Test 3: New Message

**Cách test nhanh:**

1. **Tạo conversation** trong app (hoặc từ Firebase Console)
2. **Vào Firebase Console** → Firestore → `conversations/{convId}/messages`
3. **Thêm message mới**:
   ```json
   {
     "senderId": "user_id_khac",
     "content": "Xin chào, phòng còn trống không?",
     "type": "text",
     "createdAt": [Server Timestamp],
     "isRead": false
   }
   ```
4. **Kiểm tra app**: User nhận tin nhắn sẽ có notification

**Kết quả mong đợi:**
- ✅ Notification với tên sender và preview tin nhắn
- ✅ Tap notification → Mở conversation (hoặc room detail nếu chưa có conversation screen)

---

## 🧪 Test 4: HTTP Test Function

**Cách test nhanh:**

1. **Lấy User ID**: Firebase Console → Authentication → Copy User UID
2. **Chạy script test**:
   ```bash
   TEST_NOTIFICATIONS.bat
   ```
   Chọn option 4, nhập User ID
3. **Hoặc dùng PowerShell**:
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
- ✅ Notification hiển thị trong app

---

## 🔍 Kiểm tra Logs

### Xem logs trong Firebase Console
1. Firebase Console → **Functions**
2. Click function cần xem → Tab **Logs**

### Xem logs bằng CLI
```bash
firebase functions:log
```

### Xem logs real-time
```bash
firebase functions:log --follow
```

---

## ✅ Checklist Test

- [ ] **FCM Token**: Mở app → Đăng nhập → Kiểm tra token trong Firestore
- [ ] **Room Approve**: Tạo room → Approve → Kiểm tra notification
- [ ] **Room Reject**: Reject room → Kiểm tra notification
- [ ] **Price Change**: Lưu room → Đổi giá → Kiểm tra notification
- [ ] **New Message**: Gửi tin nhắn → Kiểm tra notification
- [ ] **HTTP Test**: Gửi test notification → Kiểm tra notification

---

## 🐛 Troubleshooting

### Notification không đến?
1. Kiểm tra FCM token có trong Firestore không
2. Kiểm tra app có quyền nhận notification không
3. Xem logs: `firebase functions:log`
4. Kiểm tra device có internet không

### Function không trigger?
1. Kiểm tra function đã deploy chưa: `firebase functions:list`
2. Kiểm tra document thực sự thay đổi (không phải update cùng giá trị)
3. Xem logs để tìm lỗi

---

## 📚 Xem thêm

- `HUONG_DAN_TEST_NOTIFICATIONS.md` - Hướng dẫn chi tiết
- `KIEM_TRA_CHUC_NANG_NOTIFICATIONS.md` - Kiểm tra trạng thái
- `TEST_NOTIFICATIONS.bat` - Script test nhanh

