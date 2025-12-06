# Hướng dẫn nhanh: Lấy SHA-1 và cấu hình Google Sign-In

## 🚀 Cách nhanh nhất: Dùng Android Studio

1. **Mở Android Studio**
2. **Mở project** `app_timtrosinhvien`
3. **Mở Gradle panel** (View > Tool Windows > Gradle, hoặc icon Gradle bên phải)
4. **Mở rộng:** `app_timtrosinhvien` > `android` > `Tasks` > `android`
5. **Double-click:** `signingReport`
6. **Xem output** ở dưới, tìm dòng:
   ```
   Variant: debug
   SHA1: A1:B2:C3:D4:E5:F6:...
   ```
7. **Copy** giá trị SHA-1 (phần sau `SHA1:`)

---

## 📋 Bước tiếp theo: Thêm vào Firebase

### 1. Mở Firebase Console
👉 https://console.firebase.google.com/

### 2. Chọn project
👉 **app-timtrosinhvien**

### 3. Vào Project Settings
👉 Click **⚙️ Settings** (góc trên bên trái) > **Project settings**

### 4. Thêm SHA-1
👉 Cuộn xuống **Your apps** > Tìm app Android > Click **Add fingerprint** > Dán SHA-1 > **Save**

### 5. Kiểm tra Google Sign-In
👉 **Authentication** > **Sign-in method** > Đảm bảo **Google** đã **Enabled**

---

## ✅ Xong!

Sau khi thêm SHA-1, đợi 5-10 phút rồi test lại Google Sign-In trong app.

---

## ❓ Nếu không có Android Studio?

Chạy lệnh này trong PowerShell (từ thư mục gốc project):

```powershell
cd android
.\gradlew.bat signingReport
```

Tìm dòng `SHA1:` trong output và copy giá trị.

