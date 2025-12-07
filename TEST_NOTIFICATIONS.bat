@echo off
echo ========================================
echo Test Notifications - Nhà Trọ 360
echo ========================================
echo.
echo Chọn test case:
echo.
echo 1. Test Room Status Changed (Approve/Reject)
echo 2. Test Room Price Changed
echo 3. Test New Message
echo 4. Test HTTP Function (testNotification)
echo 5. Xem Functions Logs
echo 6. Kiểm tra Functions đã deploy
echo.
set /p choice="Nhập số (1-6): "

if "%choice%"=="1" (
    echo.
    echo ========================================
    echo Test Room Status Changed
    echo ========================================
    echo.
    echo Hướng dẫn:
    echo 1. Mở app và đăng tin mới
    echo 2. Vào Firebase Console - Firestore
    echo 3. Tìm room vừa tạo (status = pending)
    echo 4. Sửa status thành "active" hoặc "rejected"
    echo 5. Kiểm tra notification trong app
    echo.
    pause
    goto :end
)

if "%choice%"=="2" (
    echo.
    echo ========================================
    echo Test Room Price Changed
    echo ========================================
    echo.
    echo Hướng dẫn:
    echo 1. Mở app và lưu một room vào favorites
    echo 2. Vào Firebase Console - Firestore
    echo 3. Tìm room đã lưu
    echo 4. Sửa priceMillion (ví dụ: 3.5 thành 3.0)
    echo 5. Kiểm tra notification trong app
    echo.
    pause
    goto :end
)

if "%choice%"=="3" (
    echo.
    echo ========================================
    echo Test New Message
    echo ========================================
    echo.
    echo Hướng dẫn:
    echo 1. Tạo conversation trong app
    echo 2. Vào Firebase Console - Firestore
    echo 3. Tìm conversations/{convId}/messages
    echo 4. Thêm message mới với senderId khác
    echo 5. Kiểm tra notification trong app
    echo.
    pause
    goto :end
)

if "%choice%"=="4" (
    echo.
    echo ========================================
    echo Test HTTP Function
    echo ========================================
    echo.
    set /p userId="Nhập User ID: "
    if "%userId%"=="" (
        echo User ID không được để trống!
        pause
        goto :end
    )
    echo.
    echo Gửi test notification...
    echo.
    powershell -Command "$body = @{userId='%userId%'; title='Test Notification'; body='Đây là notification test'; type='test'} | ConvertTo-Json; Invoke-RestMethod -Uri 'https://us-central1-app-timtrosinhvien.cloudfunctions.net/testNotification' -Method Post -ContentType 'application/json' -Body $body"
    echo.
    echo Kiểm tra notification trong app!
    pause
    goto :end
)

if "%choice%"=="5" (
    echo.
    echo ========================================
    echo Xem Functions Logs
    echo ========================================
    echo.
    firebase functions:log
    pause
    goto :end
)

if "%choice%"=="6" (
    echo.
    echo ========================================
    echo Kiểm tra Functions đã deploy
    echo ========================================
    echo.
    firebase functions:list
    pause
    goto :end
)

echo Lựa chọn không hợp lệ!
pause

:end

