# Hướng dẫn Upgrade Firebase Plan để sử dụng Cloud Functions

## ⚠️ Vấn đề

Firebase Cloud Functions chỉ hoạt động trên **Blaze plan** (pay-as-you-go), không phải Spark plan (free).

## 🚀 Cách Upgrade

### Bước 1: Vào Firebase Console

1. Truy cập: https://console.firebase.google.com/project/app-timtrosinhvien/usage/details
2. Hoặc vào Firebase Console → Project Settings → Usage and billing

### Bước 2: Upgrade lên Blaze Plan

1. Click **Upgrade** hoặc **Modify plan**
2. Chọn **Blaze plan** (pay-as-you-go)
3. Thêm payment method (thẻ tín dụng)
4. Xác nhận upgrade

### Bước 3: Đợi upgrade hoàn tất

- Quá trình upgrade thường mất vài phút
- Bạn sẽ nhận được email xác nhận

### Bước 4: Deploy Functions

Sau khi upgrade xong, chạy lại:

```bash
DEPLOY_FUNCTIONS.bat
```

Hoặc:

```bash
firebase deploy --only functions
```

---

## 💰 Chi phí Blaze Plan

### Free Tier (Spark Plan):
- ❌ Không có Cloud Functions
- ✅ Firestore: 1GB storage, 50K reads/day
- ✅ Authentication: Unlimited
- ✅ Storage: 5GB

### Blaze Plan (Pay-as-you-go):
- ✅ Cloud Functions: **2 triệu invocations/tháng FREE**
- ✅ Firestore: **1GB storage, 50K reads/day FREE** (sau đó trả phí)
- ✅ Authentication: Unlimited FREE
- ✅ Storage: **5GB FREE** (sau đó trả phí)

### Lưu ý về chi phí:

1. **Cloud Functions**: 
   - 2 triệu invocations/tháng = **FREE**
   - Sau đó: $0.40 per 1M invocations
   - Với app nhỏ, thường không vượt quá free tier

2. **Firestore**:
   - 1GB storage, 50K reads/day = **FREE**
   - Sau đó trả phí theo usage

3. **Tổng kết**:
   - Với app nhỏ/trung bình, thường vẫn **FREE** hoặc rất ít phí
   - Chỉ trả phí khi vượt quá free tier

---

## 🔄 Alternative: Sử dụng HTTP Functions thay vì Firestore Triggers

Nếu không muốn upgrade, có thể:

1. **Sử dụng HTTP Functions** thay vì Firestore Triggers
2. **Gọi HTTP Functions từ client** khi cần gửi notification
3. **Hoặc tạo backend service** riêng (Node.js, Python, etc.)

Tuy nhiên, cách này phức tạp hơn và không tự động như Firestore Triggers.

---

## ✅ Sau khi Upgrade

1. Deploy functions: `DEPLOY_FUNCTIONS.bat`
2. Test functions theo hướng dẫn trong `HUONG_DAN_TEST_NOTIFICATIONS.md`
3. Monitor usage trong Firebase Console

---

## 📚 Tham khảo

- [Firebase Pricing](https://firebase.google.com/pricing)
- [Cloud Functions Pricing](https://firebase.google.com/pricing#cloud-functions)
- [Upgrade to Blaze](https://console.firebase.google.com/project/app-timtrosinhvien/usage/details)

