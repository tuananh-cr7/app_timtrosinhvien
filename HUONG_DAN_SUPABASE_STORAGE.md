# Hướng dẫn cấu hình Supabase Storage

## Bước 1: Lấy Supabase URL và Anon Key

1. Đăng nhập vào [Supabase Dashboard](https://supabase.com/dashboard)
2. Chọn project của bạn (hoặc tạo project mới)
3. Vào **Settings** → **API**
4. Copy 2 thông tin sau:
   - **Project URL** (ví dụ: `https://xxxxx.supabase.co`)
   - **anon public** key (key công khai, bắt đầu bằng `eyJ...`)

## Bước 2: Cập nhật code

Mở file `lib/main.dart` và thay thế:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL', // Thay bằng Project URL của bạn
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Thay bằng anon key của bạn
);
```

**Ví dụ:**
```dart
await Supabase.initialize(
  url: 'https://ggzbqntuahhnxwpemztt.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

## Bước 3: Kiểm tra bucket "room-images"

1. Vào **Storage** trong Supabase Dashboard
2. Kiểm tra xem đã có bucket tên `room-images` chưa
3. Nếu chưa có, tạo bucket mới:
   - Click **"New bucket"**
   - Tên: `room-images`
   - **Public bucket**: Bật ON (để có thể truy cập ảnh công khai)
   - Click **"Create bucket"**

## Bước 4: Cấu hình Storage Policies (Quyền truy cập)

1. Vào **Storage** → **Policies** tab
2. Chọn bucket `room-images`
3. Tạo policy cho phép upload:
   - **Policy name**: `Allow authenticated uploads`
   - **Allowed operation**: `INSERT`
   - **Policy definition**: 
     ```sql
     (bucket_id = 'room-images'::text) AND (auth.role() = 'authenticated')
     ```
4. Tạo policy cho phép đọc công khai:
   - **Policy name**: `Allow public reads`
   - **Allowed operation**: `SELECT`
   - **Policy definition**:
     ```sql
     (bucket_id = 'room-images'::text)
     ```
5. Tạo policy cho phép xóa (chỉ owner):
   - **Policy name**: `Allow owner delete`
   - **Allowed operation**: `DELETE`
   - **Policy definition**:
     ```sql
     (bucket_id = 'room-images'::text) AND (auth.uid()::text = (storage.foldername(name))[1])
     ```

## Bước 5: Cài đặt dependencies

Chạy lệnh:
```bash
flutter pub get
```

## Bước 6: Test upload ảnh

1. Chạy app: `flutter run`
2. Đăng nhập vào app
3. Vào **Đăng tin** → **Bước 3: Hình ảnh**
4. Chọn ảnh từ thư viện hoặc chụp ảnh
5. Ảnh sẽ tự động upload lên Supabase Storage
6. Kiểm tra trong Supabase Dashboard → **Storage** → **room-images** để xem ảnh đã upload

## Lưu ý

- **Public bucket**: Nếu bucket là public, mọi người có thể xem ảnh qua URL công khai
- **Private bucket**: Nếu muốn bảo mật hơn, có thể dùng private bucket và tạo signed URLs
- **File size limit**: Mặc định Supabase cho phép file tối đa 50MB (có thể tăng trong Settings)
- **Storage quota**: Kiểm tra quota trong Settings → Usage để tránh vượt quá giới hạn

## Troubleshooting

### Lỗi: "new row violates row-level security policy"
→ Kiểm tra lại Storage Policies, đảm bảo đã tạo policy cho INSERT

### Lỗi: "Bucket not found"
→ Kiểm tra tên bucket trong code (`lib/features/post/services/storage_service.dart`) phải khớp với tên bucket trong Supabase

### Lỗi: "Invalid API key"
→ Kiểm tra lại Supabase URL và anon key trong `main.dart`

