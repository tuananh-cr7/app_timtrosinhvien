# Hướng dẫn cấu hình Google Sign-In cho Firebase

## Bước 1: Lấy SHA-1 Fingerprint

### ⭐ Cách 1: Sử dụng Android Studio (Dễ nhất)

1. Mở project trong **Android Studio**
2. Mở panel **Gradle** (bên phải màn hình, hoặc View > Tool Windows > Gradle)
3. Mở rộng: `app_timtrosinhvien` > `android` > `Tasks` > `android`
4. Double-click vào **signingReport**
5. Xem kết quả trong **Run** panel ở dưới
6. Tìm dòng có chứa `Variant: debug` và `SHA1:`
7. Copy giá trị SHA-1 (ví dụ: `A1:B2:C3:D4:E5:F6:...`)

### Cách 2: Sử dụng Command Line

**Trong PowerShell:**
```powershell
cd android
.\gradlew.bat signingReport
```

Sau đó tìm dòng `SHA1:` trong output.

---

## Bước 2: Thêm SHA-1 vào Firebase Console

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **app-timtrosinhvien**
3. Click vào biểu tượng **⚙️ Settings** (bánh răng) > **Project settings**
4. Cuộn xuống phần **Your apps**
5. Tìm app Android của bạn (package name: `com.example.app_timtrosinhvien`)
6. Click vào **Add fingerprint** (hoặc icon dấu +)
7. Dán SHA-1 fingerprint đã copy ở Bước 1
8. Click **Save**

**Lưu ý:** 
- Nếu chưa có app Android, click **Add app** > **Android** và nhập package name
- Sau khi thêm SHA-1, có thể mất 5-10 phút để Firebase cập nhật

---

## Bước 3: Kiểm tra Google Sign-In đã được bật

1. Trong Firebase Console, vào **Authentication** (menu bên trái)
2. Click tab **Sign-in method**
3. Tìm **Google** trong danh sách providers
4. Đảm bảo trạng thái là **Enabled** (có dấu ✓ xanh)
5. Nếu chưa Enabled:
   - Click vào **Google**
   - Bật **Enable**
   - Nhập **Support email** (email của bạn)
   - Click **Save**

---

## Bước 4: Test Google Sign-In

1. Chạy app: `flutter run`
2. Vào màn hình **Đăng nhập**
3. Click nút **Đăng nhập với Google**
4. Chọn tài khoản Google và cho phép quyền truy cập
5. App sẽ tự động đăng nhập và chuyển vào màn hình chính

---

## Troubleshooting

### Lỗi: "PlatformException(channel-error, Unable to establish connection..."

**Nguyên nhân:** SHA-1 chưa được thêm vào Firebase hoặc chưa được cập nhật.

**Giải pháp:**
1. Kiểm tra lại SHA-1 đã được thêm vào Firebase Console chưa
2. Đợi 5-10 phút sau khi thêm SHA-1
3. Restart app (hot restart không đủ, cần stop và run lại)
4. Kiểm tra package name trong `android/app/build.gradle.kts` khớp với Firebase Console

### Lỗi: "Google Sign-In đã bị hủy"

**Nguyên nhân:** User đã hủy quá trình đăng nhập.

**Giải pháp:** Đây là hành vi bình thường, không phải lỗi. User có thể thử lại.

---

## Lưu ý quan trọng

- **Debug build**: Sử dụng SHA-1 từ debug keystore (mặc định)
- **Release build**: Khi build release, bạn cần thêm SHA-1 từ release keystore vào Firebase Console
- **Multiple SHA-1**: Firebase hỗ trợ nhiều SHA-1, bạn có thể thêm cả debug và release SHA-1

---

## Tài liệu tham khảo

- [Firebase Authentication - Google Sign-In](https://firebase.google.com/docs/auth/android/google-signin)
- [FlutterFire - Google Sign-In](https://firebase.flutter.dev/docs/auth/social/google)

