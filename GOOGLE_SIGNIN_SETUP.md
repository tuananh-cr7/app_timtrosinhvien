# Hướng dẫn cấu hình Google Sign-In

## Bước 1: Lấy SHA-1 fingerprint

Để Google Sign-In hoạt động trên Android, bạn cần thêm SHA-1 fingerprint vào Firebase Console.

### Cách 1: Sử dụng Android Studio (Dễ nhất - Khuyến nghị)

1. Mở project trong **Android Studio**
2. Mở panel **Gradle** (bên phải màn hình)
3. Mở rộng: `app` > `Tasks` > `android`
4. Double-click vào **signingReport**
5. Xem kết quả trong **Run** panel ở dưới
6. Tìm dòng có chứa `SHA1:` và copy giá trị SHA-1 (ví dụ: `A1:B2:C3:...`)

### Cách 2: Sử dụng Gradle Command Line

Chạy lệnh sau trong thư mục gốc của project:

**Windows:**
```powershell
cd android
.\gradlew.bat signingReport
```

**Mac/Linux:**
```bash
cd android
./gradlew signingReport
```

Tìm dòng có chứa `SHA1:` và copy giá trị SHA-1.

### Cách 3: Sử dụng PowerShell Script

Chạy script helper:

```powershell
.\get_sha1.ps1
```

Script sẽ tự động tìm keytool và lấy SHA-1 fingerprint.

### Cách 4: Sử dụng keytool trực tiếp

Nếu bạn đã cài Java JDK và có keytool trong PATH:

**Windows:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Mac/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Bước 2: Thêm SHA-1 vào Firebase Console

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **app-timtrosinhvien**
3. Vào **Project Settings** (biểu tượng bánh răng)
4. Cuộn xuống phần **Your apps**
5. Chọn app Android của bạn
6. Nhấp vào **Add fingerprint**
7. Dán SHA-1 fingerprint đã copy ở bước 1
8. Tải lại file `google-services.json` nếu cần và thay thế file cũ trong `android/app/`

## Bước 3: Kiểm tra Google Sign-In đã được bật

1. Trong Firebase Console, vào **Authentication** > **Sign-in method**
2. Đảm bảo **Google** đã được **Enabled**
3. Nhập **Support email** và **Project support email** nếu chưa có

## Lưu ý

- **Debug build**: Sử dụng SHA-1 từ debug keystore
- **Release build**: Sử dụng SHA-1 từ release keystore (sẽ tạo khi build release)
- Sau khi thêm SHA-1, có thể mất vài phút để Firebase cập nhật

## Test Google Sign-In

Sau khi hoàn tất cấu hình:

1. Chạy app: `flutter run`
2. Vào màn hình **Đăng nhập**
3. Nhấp **Đăng nhập với Google**
4. Chọn tài khoản Google và cho phép quyền truy cập
5. App sẽ tự động đăng nhập và chuyển vào màn hình chính

