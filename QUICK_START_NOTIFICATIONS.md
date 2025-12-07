# Quick Start: Notifications - Nhà Trọ 360

## 🚨 Bước 1: Deploy Functions (BẮT BUỘC)

### Nếu màn hình Functions trống:

1. **Kiểm tra Plan**:
   - Vào: https://console.firebase.google.com/project/app-timtrosinhvien/usage/details
   - Nếu đang ở **Spark (Free)** → Cần upgrade lên **Blaze**

2. **Upgrade lên Blaze** (nếu cần):
   - Click **Upgrade** → Chọn **Blaze plan**
   - Thêm payment method
   - Đợi 2-5 phút

3. **Deploy Functions**:
   ```bash
   DEPLOY_FUNCTIONS.bat
   ```

4. **Kiểm tra**:
   - Vào Firebase Console → **Functions**
   - Phải thấy 4 functions, không còn message "Waiting for your first deploy"

---

## 🧪 Bước 2: Test Functions

### Test 1: Room Approve (Nhanh nhất)

1. **Mở app** → Đăng nhập → **Đăng tin** → Hoàn thành
2. **Firebase Console** → Firestore → Tìm room vừa tạo (`status: 'pending'`)
3. **Sửa status**: `pending` → `active`
4. **Kiểm tra app**: Tab **Thông báo** → Xem notification

✅ **Kết quả**: Notification "Tin đăng được duyệt" xuất hiện

---

### Test 2: Price Change

1. **Mở app** → Tìm room → Click **Yêu thích** (trái tim)
2. **Firebase Console** → Firestore → Tìm room đã lưu
3. **Sửa priceMillion**: `3.5` → `3.0`
4. **Kiểm tra app**: Tab **Thông báo** → Xem notification

✅ **Kết quả**: Notification "Giá phòng yêu thích giảm! 🎉" xuất hiện

---

### Test 3: HTTP Test (Dễ nhất)

1. **Lấy User ID**: Firebase Console → Authentication → Copy User UID
2. **Chạy script**:
   ```bash
   TEST_NOTIFICATIONS.bat
   ```
   Chọn option **4**, nhập User ID
3. **Kiểm tra app**: Tab **Thông báo** → Xem notification

✅ **Kết quả**: Notification "Test Notification" xuất hiện

---

## 🔍 Kiểm tra Logs

Nếu notification không đến, xem logs:

```bash
firebase functions:log
```

Hoặc trong Firebase Console → Functions → Click function → Tab **Logs**

---

## ❓ FAQ

### Q: Functions không hiển thị trong Console?
**A**: Cần deploy trước. Chạy `DEPLOY_FUNCTIONS.bat`

### Q: Lỗi "must be on Blaze plan"?
**A**: Cần upgrade Firebase plan. Xem `HUONG_DAN_UPGRADE_FIREBASE.md`

### Q: Notification không đến?
**A**: 
- Kiểm tra FCM token có trong Firestore không
- Kiểm tra app có quyền nhận notification không
- Xem logs để tìm lỗi

---

## 📚 Xem thêm

- `HUONG_DAN_DEPLOY_CHI_TIET.md` - Hướng dẫn deploy chi tiết
- `HUONG_DAN_TEST_NOTIFICATIONS.md` - Hướng dẫn test đầy đủ
- `KIEM_TRA_CHUC_NANG_NOTIFICATIONS.md` - Kiểm tra trạng thái

