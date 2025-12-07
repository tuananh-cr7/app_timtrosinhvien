# Hướng dẫn Deploy Functions - Chi tiết từng bước

## ⚠️ Vấn đề: Màn hình Functions trống

Nếu bạn thấy màn hình Functions với message **"Waiting for your first deploy"**, nghĩa là:
- Functions chưa được deploy lên Firebase
- Hoặc project chưa upgrade lên Blaze plan

---

## 🔍 Kiểm tra Project Plan

### Bước 1: Kiểm tra plan hiện tại

1. Vào Firebase Console: https://console.firebase.google.com/project/app-timtrosinhvien
2. Click vào **⚙️ Settings** (góc trên bên trái) → **Usage and billing**
3. Xem **Current plan**:
   - **Spark (Free)**: ❌ Không thể deploy Functions
   - **Blaze (Pay-as-you-go)**: ✅ Có thể deploy Functions

---

## 🚀 Nếu đang ở Spark Plan: Upgrade lên Blaze

### Bước 1: Vào trang Upgrade

**Cách 1: Từ Firebase Console**
1. Vào: https://console.firebase.google.com/project/app-timtrosinhvien/usage/details
2. Click nút **Upgrade** (màu xanh)

**Cách 2: Từ menu**
1. Firebase Console → ⚙️ Settings → **Usage and billing**
2. Click **Modify plan** hoặc **Upgrade**

### Bước 2: Chọn Blaze Plan

1. Chọn **Blaze (Pay-as-you-go)**
2. Click **Continue**

### Bước 3: Thêm Payment Method

1. Thêm thẻ tín dụng (Visa, Mastercard, etc.)
2. Xác nhận thông tin
3. Click **Complete upgrade**

### Bước 4: Đợi upgrade hoàn tất

- Thường mất **2-5 phút**
- Bạn sẽ thấy thông báo "Upgrade successful"
- Hoặc refresh trang và kiểm tra plan đã đổi thành "Blaze"

---

## 📦 Sau khi Upgrade: Deploy Functions

### Bước 1: Mở Terminal/Command Prompt

### Bước 2: Chạy script deploy

**Cách 1: Dùng script (dễ nhất)**
```bash
DEPLOY_FUNCTIONS.bat
```

**Cách 2: Chạy thủ công**
```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

### Bước 3: Đợi deploy hoàn tất

Quá trình deploy sẽ:
1. Build TypeScript → JavaScript
2. Upload code lên Firebase
3. Deploy từng function
4. Hiển thị URLs của functions

**Thời gian**: Thường mất **3-10 phút** tùy số lượng functions

### Bước 4: Kiểm tra kết quả

1. Vào Firebase Console → **Functions**
2. Bạn sẽ thấy 4 functions:
   - ✅ `onRoomStatusChanged`
   - ✅ `onRoomPriceChanged`
   - ✅ `onNewMessage`
   - ✅ `testNotification`

---

## ✅ Sau khi Deploy thành công

### Kiểm tra Functions đã deploy:

**Cách 1: Firebase Console**
1. Vào: https://console.firebase.google.com/project/app-timtrosinhvien/functions
2. Xem danh sách functions

**Cách 2: CLI**
```bash
firebase functions:list
```

### Test Functions:

Xem hướng dẫn chi tiết trong: `HUONG_DAN_TEST_NOTIFICATIONS.md`

---

## 🐛 Troubleshooting

### Lỗi: "must be on the Blaze plan"

**Nguyên nhân**: Project chưa upgrade lên Blaze plan

**Giải pháp**: 
1. Upgrade lên Blaze plan (xem hướng dẫn trên)
2. Đợi upgrade hoàn tất
3. Deploy lại

### Lỗi: "API not enabled"

**Nguyên nhân**: Các API cần thiết chưa được bật

**Giải pháp**:
- Firebase sẽ tự động enable khi deploy
- Nếu lỗi, vào Google Cloud Console → APIs & Services → Enable:
  - Cloud Functions API
  - Cloud Build API
  - Artifact Registry API

### Lỗi: "Build failed"

**Nguyên nhân**: TypeScript có lỗi

**Giải pháp**:
```bash
cd functions
npm run build
```
Xem lỗi và sửa code

### Functions không hiển thị sau khi deploy

**Giải pháp**:
1. Refresh trang Firebase Console
2. Kiểm tra tab **Dashboard** (không phải **Usage**)
3. Đợi vài phút (có thể delay)

---

## 📊 Checklist Deploy

- [ ] Project đã upgrade lên Blaze plan
- [ ] Payment method đã thêm
- [ ] Upgrade hoàn tất (kiểm tra trong Console)
- [ ] Chạy `DEPLOY_FUNCTIONS.bat`
- [ ] Deploy thành công (không có lỗi)
- [ ] Functions hiển thị trong Firebase Console
- [ ] Test functions hoạt động

---

## 💡 Lưu ý quan trọng

1. **Blaze plan có free tier rộng rãi**:
   - 2 triệu function invocations/tháng = FREE
   - Với app nhỏ, thường vẫn FREE

2. **Chỉ trả phí khi vượt quá free tier**:
   - Functions: $0.40 per 1M invocations (sau free tier)
   - Firestore: Trả phí theo usage (sau free tier)

3. **Có thể downgrade về Spark sau**:
   - Nhưng sẽ mất tất cả Functions
   - Cần xóa functions trước khi downgrade

---

## 📚 Tài liệu liên quan

- `HUONG_DAN_UPGRADE_FIREBASE.md` - Hướng dẫn upgrade
- `HUONG_DAN_TEST_NOTIFICATIONS.md` - Hướng dẫn test
- `DEPLOY_FUNCTIONS.bat` - Script deploy

