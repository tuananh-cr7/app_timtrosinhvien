# DANH SÁCH INDEXES CẦN THÊM/BỎ

## ❌ CẦN BỎ (Indexes cũ không dùng nữa):

### 1. Index với `price` thay vì `priceMillion` (dòng 3-12):
- Collection: `rooms`
- Fields: `city` (ASC), `district` (ASC), `price` (ASC), `createdAt` (DESC)
- **Lý do:** Code đã đổi sang dùng `priceMillion`, không còn dùng `price`

### 2. Index với `price` thay vì `priceMillion` (dòng 13-21):
- Collection: `rooms`
- Fields: `city` (ASC), `price` (ASC), `area` (ASC)
- **Lý do:** Code đã đổi sang dùng `priceMillion`, không còn dùng `price`

---

## ✅ CẦN THÊM (Indexes mới):

### 1. Index cơ bản cho filter giá (QUAN TRỌNG - đang thiếu):
- **Collection:** `rooms`
- **Fields:**
  - `status` (Ascending)
  - `priceMillion` (Ascending)
- **Query scope:** Collection
- **Lý do:** Error message yêu cầu index này cho query filter giá và orderBy priceMillion

### 2. Index cho filter giá + diện tích:
- **Collection:** `rooms`
- **Fields:**
  - `status` (Ascending)
  - `priceMillion` (Ascending)
  - `area` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection
- **Lý do:** Cho query filter cả giá và diện tích

### 3. Index cho filter giá + thành phố:
- **Collection:** `rooms`
- **Fields:**
  - `status` (Ascending)
  - `city` (Ascending)
  - `priceMillion` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection
- **Lý do:** Cho query filter thành phố + giá

### 4. Index cho filter giá + quận:
- **Collection:** `rooms`
- **Fields:**
  - `status` (Ascending)
  - `district` (Ascending)
  - `priceMillion` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection
- **Lý do:** Cho query filter quận + giá

### 5. Index cho filter giá + loại tin (ở ghép):
- **Collection:** `rooms`
- **Fields:**
  - `status` (Ascending)
  - `isShared` (Ascending)
  - `priceMillion` (Ascending)
  - `createdAt` (Descending)
- **Query scope:** Collection
- **Lý do:** Cho query filter loại tin + giá

---

## ✅ ĐÃ CÓ (Giữ lại):

1. ✅ `status` (ASC), `createdAt` (DESC) - Cho query không có range filter
2. ✅ `status` (ASC), `isShared` (ASC), `createdAt` (DESC) - Cho query filter loại tin
3. ✅ `status` (ASC), `priceMillion` (ASC), `createdAt` (DESC) - Cho query filter giá + sort createdAt
4. ✅ `status` (ASC), `city` (ASC), `priceMillion` (ASC), `createdAt` (DESC) - Cho query filter city + giá
5. ✅ `status` (ASC), `district` (ASC), `priceMillion` (ASC), `createdAt` (DESC) - Cho query filter district + giá
6. ✅ `status` (ASC), `isShared` (ASC), `priceMillion` (ASC), `createdAt` (DESC) - Cho query filter isShared + giá
7. ✅ `status` (ASC), `priceMillion` (ASC), `area` (ASC), `createdAt` (DESC) - Cho query filter giá + diện tích
8. ✅ `ownerId` (ASC), `createdAt` (DESC) - Cho query lấy phòng của owner
9. ✅ `userId` (ASC), `createdAt` (DESC) - Cho favorites, notifications
10. ✅ `userId` (ASC), `viewedAt` (DESC) - Cho viewHistory
11. ✅ `conversationId` (ASC), `createdAt` (ASC) - Cho messages

---

## 📝 HƯỚNG DẪN THÊM THỦ CÔNG:

### Bước 1: Bỏ indexes cũ
1. Vào Firebase Console → Firestore → Indexes
2. Tìm các index có field `price` (không phải `priceMillion`)
3. Click vào 3 chấm (⋮) → Delete

### Bước 2: Thêm index QUAN TRỌNG nhất (index #1):
1. Click "Add index"
2. Collection ID: `rooms`
3. Fields:
   - Field 1: `status` - Ascending
   - Field 2: `priceMillion` - Ascending
4. Query scope: Collection
5. Click "Create"

### Bước 3: Thêm các index còn lại (nếu cần):
Làm tương tự với các index #2, #3, #4, #5 ở trên.

---

## ⚠️ LƯU Ý:
- Index #1 là **QUAN TRỌNG NHẤT** - cần thêm ngay để fix lỗi hiện tại
- Các index khác có thể thêm sau nếu cần
- Indexes sẽ mất 1-2 phút để build xong

