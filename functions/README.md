# Firebase Cloud Functions - Nhà Trọ 360

Cloud Functions để gửi push notifications cho ứng dụng Nhà Trọ 360.

## 🚀 Quick Start

### 1. Cài đặt dependencies

```bash
cd functions
npm install
```

### 2. Build TypeScript

```bash
npm run build
```

### 3. Deploy

```bash
# Từ thư mục functions
npm run deploy

# Hoặc từ thư mục root
firebase deploy --only functions
```

## 📋 Functions

### `onRoomStatusChanged`
Trigger khi room status thay đổi (approve/reject).

### `onRoomPriceChanged`
Trigger khi room price thay đổi, gửi notification cho users đã lưu vào favorites.

### `onNewMessage`
Trigger khi có tin nhắn mới trong conversation.

### `testNotification`
HTTP function để test gửi notification (optional).

## 📚 Xem thêm

Xem file `../HUONG_DAN_DEPLOY_FUNCTIONS.md` để biết chi tiết hướng dẫn deploy.

