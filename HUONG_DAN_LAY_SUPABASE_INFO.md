# Hướng dẫn lấy Supabase URL và Key từ project hiện tại

## Bước 1: Lấy Supabase URL và Anon Key

1. Đăng nhập vào [Supabase Dashboard](https://supabase.com/dashboard)
2. Chọn project **"Phongtro Org"** (hoặc project bạn đã tạo trước đó)
3. Vào **Settings** (biểu tượng bánh răng ở sidebar bên trái)
4. Chọn tab **API**
5. Tìm 2 thông tin sau:

### Project URL
- Tìm mục **"Project URL"**
- Copy URL (ví dụ: `https://ggzbqntuahhnxwpemztt.supabase.co`)

### Anon/Public Key
- Tìm mục **"Project API keys"**
- Copy key **"anon public"** (key công khai, bắt đầu bằng `eyJ...`)
- ⚠️ **KHÔNG** copy "service_role" key (key này có quyền cao, nguy hiểm nếu lộ)

## Bước 2: Cập nhật code

Mở file `lib/main.dart` và thay thế:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL', // ← Thay bằng Project URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // ← Thay bằng anon public key
);
```

**Ví dụ:**
```dart
await Supabase.initialize(
  url: 'https://ggzbqntuahhnxwpemztt.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6YnFudHVhaG5veHdwZW16dHQiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY5ODc2ODAwMCwiZXhwIjoyMDE0MzQ0MDAwfQ.xxxxx',
);
```

## Bước 3: Kiểm tra bucket "room-images"

Từ ảnh bạn gửi, tôi thấy bạn đã có:
- ✅ Bucket `room-images` (PUBLIC)
- ✅ Policy `allow-auth-upload` (cho phép INSERT)
- ✅ Policy `public-read` (cho phép SELECT)

**Vậy là đã đủ!** Không cần tạo mới gì cả.

## Lưu ý

- **Có thể dùng chung project**: Supabase cho phép nhiều bucket trong 1 project, nên bạn có thể dùng chung project cho nhiều dự án
- **Tách riêng nếu muốn**: Nếu muốn tách biệt hoàn toàn, có thể tạo project mới, nhưng không bắt buộc
- **Bucket name**: Code đã cấu hình sẵn dùng bucket `room-images`, nếu bucket của bạn tên khác, cần sửa trong `lib/features/post/services/storage_service.dart`

## Sau khi cập nhật

1. Chạy `flutter pub get` (nếu chưa chạy)
2. Chạy `flutter run` để test
3. Thử upload ảnh trong flow đăng tin

