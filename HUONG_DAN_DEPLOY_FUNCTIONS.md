# Hướng dẫn Deploy Firebase Cloud Functions

## 📋 Yêu cầu

1. **Node.js**: Phiên bản 18 trở lên
2. **Firebase CLI**: Đã cài đặt và đăng nhập
3. **Firebase Project**: Đã tạo project trên Firebase Console

---

## 🚀 Các bước triển khai

### Bước 1: Cài đặt Firebase CLI (nếu chưa có)

```bash
npm install -g firebase-tools
```

### Bước 2: Đăng nhập Firebase

```bash
firebase login
```

### Bước 3: Khởi tạo Firebase Functions (nếu chưa có)

```bash
firebase init functions
```

Khi được hỏi:
- **Language**: Chọn `TypeScript`
- **Use ESLint**: Chọn `Yes`
- **Install dependencies**: Chọn `Yes`

### Bước 4: Cài đặt dependencies

```bash
cd functions
npm install
```

### Bước 5: Build TypeScript

```bash
npm run build
```

### Bước 6: Deploy Functions

```bash
# Deploy tất cả functions
firebase deploy --only functions

# Hoặc deploy từ thư mục functions
cd functions
npm run deploy
```

---

## 📝 Cấu trúc Functions

### 1. **onRoomStatusChanged**
- **Trigger**: Khi room document được update
- **Khi nào**: Room status thay đổi (pending → active, pending → rejected)
- **Gửi đến**: Owner của room
- **Notification type**: `room_approved` hoặc `room_rejected`

### 2. **onRoomPriceChanged**
- **Trigger**: Khi room document được update
- **Khi nào**: Room price thay đổi và room đang active
- **Gửi đến**: Tất cả users đã lưu room vào favorites
- **Notification type**: `room_price_changed`

### 3. **onNewMessage**
- **Trigger**: Khi message mới được tạo
- **Khi nào**: Có tin nhắn mới trong conversation
- **Gửi đến**: User nhận tin nhắn (không phải sender)
- **Notification type**: `new_message`

### 4. **testNotification** (Optional)
- **Trigger**: HTTP request
- **Mục đích**: Test gửi notification
- **URL**: `https://us-central1-<project-id>.cloudfunctions.net/testNotification`

---

## 🧪 Test Functions

### Test bằng Firebase Emulator (Local)

```bash
cd functions
npm run serve
```

Sau đó có thể test bằng cách:
1. Tạo/update document trong Firestore
2. Xem logs trong terminal
3. Kiểm tra notification được gửi

### Test bằng HTTP Function

```bash
curl -X POST https://us-central1-<project-id>.cloudfunctions.net/testNotification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "title": "Test Notification",
    "body": "This is a test",
    "type": "test"
  }'
```

---

## 🔧 Cấu hình Firestore Security Rules

Đảm bảo Firestore rules cho phép Functions đọc/ghi:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Functions có quyền đọc/ghi tất cả
    // (Functions chạy với admin privileges)
    
    // Users có thể đọc/ghi FCM tokens của chính mình
    match /users/{userId}/fcmTokens/{tokenId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ... các rules khác
  }
}
```

---

## 📊 Monitoring & Logs

### Xem logs

```bash
firebase functions:log
```

### Xem logs real-time

```bash
firebase functions:log --only onRoomStatusChanged
```

### Xem trong Firebase Console

1. Vào Firebase Console
2. Chọn **Functions**
3. Xem **Logs** tab

---

## ⚠️ Lưu ý quan trọng

### 1. **FCM Token Management**
- Functions tự động xóa invalid tokens khi gửi notification
- Token sẽ bị xóa nếu:
  - `messaging/invalid-registration-token`
  - `messaging/registration-token-not-registered`

### 2. **Cost Optimization**
- Functions chỉ trigger khi có thay đổi thực sự
- Batch operations để giảm số lần gọi API
- Sử dụng `sendEachForMulticast` thay vì gửi từng token

### 3. **Error Handling**
- Tất cả errors được log để debug
- Functions không throw error để tránh retry không cần thiết
- Invalid tokens được tự động cleanup

### 4. **Testing**
- Luôn test trên emulator trước khi deploy
- Test với real devices để đảm bảo notification hoạt động
- Kiểm tra notification payload format

---

## 🔐 Security

### 1. **HTTP Function Security**
Nếu muốn bảo vệ `testNotification` function, thêm authentication:

```typescript
export const testNotification = functions.https.onCall(async (data, context) => {
  // Chỉ admin mới được gọi
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can call this function');
  }
  
  // ... rest of code
});
```

### 2. **Environment Variables**
Lưu sensitive data trong environment variables:

```bash
firebase functions:config:set some.key="value"
```

Truy cập trong code:
```typescript
const config = functions.config();
const value = config.some.key;
```

---

## 📈 Performance Tips

1. **Batch Operations**: Sử dụng `Promise.all()` để gửi notification song song
2. **Caching**: Cache user info nếu cần
3. **Rate Limiting**: Thêm rate limiting nếu cần thiết
4. **Monitoring**: Theo dõi function execution time và cost

---

## 🐛 Troubleshooting

### Functions không trigger
- Kiểm tra Firestore rules
- Kiểm tra function đã được deploy chưa
- Xem logs trong Firebase Console

### Notification không đến
- Kiểm tra FCM token có hợp lệ không
- Kiểm tra device có internet không
- Xem logs của function để debug

### TypeScript build errors
- Chạy `npm install` lại
- Xóa `node_modules` và `lib` folder, cài lại
- Kiểm tra TypeScript version

---

## 📚 Tài liệu tham khảo

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Admin SDK](https://firebase.google.com/docs/cloud-messaging/admin)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)

