@echo off
echo ========================================
echo Deploying Firebase Cloud Functions
echo ========================================
echo.

cd functions
echo Building TypeScript...
call npm run build
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Deploying to Firebase...
cd ..
firebase deploy --only functions

if %errorlevel% neq 0 (
    echo Deploy failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deploy completed successfully!
echo ========================================
pause

