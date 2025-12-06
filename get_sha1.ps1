# Script để lấy SHA-1 fingerprint cho Firebase Google Sign-In
# Chạy script này trong PowerShell: .\get_sha1.ps1

Write-Host "Đang tìm keytool..." -ForegroundColor Yellow

# Tìm keytool trong các vị trí phổ biến
$keytoolPaths = @(
    "$env:JAVA_HOME\bin\keytool.exe",
    "C:\Program Files\Java\*\bin\keytool.exe",
    "C:\Program Files (x86)\Java\*\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Sdk\build-tools\*\lib\keytool.jar"
)

$keytool = $null
foreach ($path in $keytoolPaths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytool = $found.FullName
        break
    }
}

if (-not $keytool) {
    Write-Host "Không tìm thấy keytool. Vui lòng:" -ForegroundColor Red
    Write-Host "1. Cài đặt Java JDK" -ForegroundColor Yellow
    Write-Host "2. Hoặc sử dụng Android Studio:" -ForegroundColor Yellow
    Write-Host "   - Mở Android Studio" -ForegroundColor Cyan
    Write-Host "   - Vào Gradle > app > Tasks > android > signingReport" -ForegroundColor Cyan
    Write-Host "   - Xem SHA1 trong output" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Hoặc sử dụng Flutter:" -ForegroundColor Yellow
    Write-Host "   cd android" -ForegroundColor Cyan
    Write-Host "   gradlew.bat signingReport" -ForegroundColor Cyan
    exit 1
}

Write-Host "Tìm thấy keytool tại: $keytool" -ForegroundColor Green
Write-Host ""

$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $debugKeystore)) {
    Write-Host "Không tìm thấy debug keystore tại: $debugKeystore" -ForegroundColor Red
    Write-Host "Vui lòng chạy Flutter app ít nhất 1 lần để tạo debug keystore." -ForegroundColor Yellow
    exit 1
}

Write-Host "Đang lấy SHA-1 fingerprint từ debug keystore..." -ForegroundColor Yellow
Write-Host ""

if ($keytool -like "*.jar") {
    # Nếu là jar file, sử dụng java -jar
    java -jar $keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android
} else {
    # Nếu là exe file
    & $keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Tìm dòng 'SHA1:' ở trên và copy giá trị SHA-1" -ForegroundColor Yellow
Write-Host "Sau đó thêm vào Firebase Console:" -ForegroundColor Yellow
Write-Host "1. Vào https://console.firebase.google.com/" -ForegroundColor Cyan
Write-Host "2. Chọn project: app-timtrosinhvien" -ForegroundColor Cyan
Write-Host "3. Project Settings > Your apps > Android app" -ForegroundColor Cyan
Write-Host "4. Nhấp 'Add fingerprint' và dán SHA-1" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green

