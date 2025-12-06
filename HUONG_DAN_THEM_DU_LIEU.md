# Hướng dẫn thêm dữ liệu vào Firestore

## Cách 1: Thêm dữ liệu trực tiếp trên Firebase Console (Dễ nhất)

### Bước 1: Mở Firebase Console
1. Vào https://console.firebase.google.com/
2. Chọn project **app-timtrosinhvien**
3. Vào **Firestore Database** (menu bên trái)

### Bước 2: Tạo collection "rooms"
1. Click **Start collection** (nếu chưa có collection nào)
2. Collection ID: `rooms`
3. Click **Next**

### Bước 3: Thêm document đầu tiên
1. Document ID: Để **Auto-ID** (tự động tạo)
2. Thêm các fields:

| Field | Type | Value |
|-------|------|-------|
| `title` | string | "Phòng trọ full nội thất gần ĐH Công Nghệ" |
| `address` | string | "Nhân Hòa, Nhân Chính, Thanh Xuân" |
| `district` | string | "Thanh Xuân" |
| `city` | string | "Hà Nội" |
| `priceMillion` | number | 4.6 |
| `area` | number | 30 |
| `thumbnailUrl` | string | "https://images.pexels.com/photos/271639/pexels-photo-271639.jpeg" |
| `isShared` | boolean | false |
| `description` | string | "Phòng trọ đẹp, đầy đủ tiện nghi..." |
| `createdAt` | timestamp | Click "Set" và chọn thời gian hiện tại |
| `updatedAt` | timestamp | Click "Set" và chọn thời gian hiện tại |
| `ownerId` | string | "user123" (hoặc để trống) |
| `ownerName` | string | "Nguyễn Văn A" |
| `ownerPhone` | string | "0901234567" |

3. Click **Save**

### Bước 4: Thêm thêm các phòng khác
- Lặp lại Bước 3 để thêm nhiều phòng
- Hoặc copy document và chỉnh sửa

---

## Cách 2: Sử dụng Mock Data (Tạm thời)

Hiện tại app đã có **fallback về mock data** nếu Firestore chưa có data hoặc lỗi. Bạn có thể:

1. **Để app dùng mock data** (không cần thêm vào Firestore)
2. **Hoặc thêm data vào Firestore** để test với real data

---

## Cách 3: Tạo Index tự động (Quan trọng!)

Firebase đã cung cấp link để tạo index tự động:

1. **Click vào link trong error message** (trong app hoặc console)
2. Hoặc vào Firebase Console > Firestore Database > Indexes
3. Click **Create Index**
4. Firebase sẽ tự động tạo index cần thiết

**Hoặc chạy lệnh:**
```bash
firebase deploy --only firestore:indexes
```

---

## Lưu ý quan trọng

### 1. Index đã được thêm vào `firestore.indexes.json`
File đã được cập nhật với index cho `isShared + createdAt`. Cần deploy:

```bash
firebase deploy --only firestore:indexes
```

### 2. Cấu trúc dữ liệu Room
Đảm bảo các fields trong Firestore khớp với model `Room`:
- `title` (string)
- `address` (string)
- `district` (string)
- `city` (string)
- `priceMillion` (number)
- `area` (number)
- `thumbnailUrl` (string)
- `isShared` (boolean)
- `description` (string, optional)
- `createdAt` (timestamp)
- `updatedAt` (timestamp, optional)
- `ownerId` (string, optional)
- `ownerName` (string, optional)
- `ownerPhone` (string, optional)
- `images` (array of strings, optional)

### 3. Test với Mock Data
Nếu chưa muốn thêm data vào Firestore, app sẽ tự động dùng mock data từ `mock_rooms.dart`.

---

## Quick Start

**Để test ngay:**
1. Deploy indexes: `firebase deploy --only firestore:indexes`
2. Đợi 2-3 phút để index được tạo
3. App sẽ tự động fallback về mock data nếu Firestore chưa có data

**Để dùng real data:**
1. Thêm ít nhất 1-2 phòng vào Firestore (theo Cách 1)
2. App sẽ tự động load từ Firestore
3. Nếu lỗi, sẽ fallback về mock data

