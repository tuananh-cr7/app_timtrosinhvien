# Trạng thái Deploy Functions

## ❌ Chưa deploy được

### Lý do:
Firebase project cần **upgrade lên Blaze plan** để sử dụng Cloud Functions.

### Error message:
```
Error: Your project app-timtrosinhvien must be on the Blaze (pay-as-you-go) plan to complete this command. 
Required API artifactregistry.googleapis.com can't be enabled until the upgrade is complete.
```

---

## ✅ Đã hoàn thành

1. ✅ **Code Functions**: Đã implement đầy đủ 4 functions
2. ✅ **Build TypeScript**: Build thành công, không lỗi
3. ✅ **Client-side**: FCM service, notification navigation đã tích hợp
4. ✅ **Firestore Rules**: Đã cập nhật để hỗ trợ FCM tokens

---

## 🚀 Cần làm

### Bước 1: Upgrade Firebase Plan
1. Vào: https://console.firebase.google.com/project/app-timtrosinhvien/usage/details
2. Click **Upgrade** → Chọn **Blaze plan**
3. Thêm payment method
4. Đợi upgrade hoàn tất (vài phút)

### Bước 2: Deploy Functions
Sau khi upgrade xong:
```bash
DEPLOY_FUNCTIONS.bat
```

### Bước 3: Test
Theo hướng dẫn trong `HUONG_DAN_TEST_NOTIFICATIONS.md`

---

## 💡 Lưu ý

- Blaze plan có **free tier** rộng rãi (2M function invocations/tháng)
- Với app nhỏ, thường vẫn **FREE** hoặc rất ít phí
- Chỉ trả phí khi vượt quá free tier

---

## 📚 Xem thêm

- `HUONG_DAN_UPGRADE_FIREBASE.md` - Hướng dẫn upgrade chi tiết
- `HUONG_DAN_TEST_NOTIFICATIONS.md` - Hướng dẫn test sau khi deploy

