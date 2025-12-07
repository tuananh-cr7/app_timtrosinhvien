@echo off
echo ========================================
echo Building Firebase Cloud Functions
echo ========================================
echo.

cd functions
echo Installing dependencies...
call npm install
if %errorlevel% neq 0 (
    echo Install failed!
    pause
    exit /b 1
)

echo.
echo Building TypeScript...
call npm run build
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo To deploy, run: DEPLOY_FUNCTIONS.bat
pause

