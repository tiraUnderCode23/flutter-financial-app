# Script להעלאת הפרויקט ל-GitHub (Windows PowerShell)

Write-Host "🚀 העלאת אפליקציית ניהול כספים ל-GitHub" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# בדיקה שיש remote
try {
    git remote get-url origin | Out-Null
} catch {
    Write-Host "❌ לא נמצא remote origin. הוסף אותו עם:" -ForegroundColor Red
    Write-Host "git remote add origin https://github.com/YOUR_USERNAME/flutter-financial-app.git" -ForegroundColor Yellow
    exit 1
}

Write-Host "📦 בניית APK חדש..." -ForegroundColor Blue
flutter build apk --release

Write-Host "📁 העתקת APK לתיקיית releases..." -ForegroundColor Blue
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "releases\flutter-financial-app-v1.0.0.apk" -Force

Write-Host "📤 הוספת קבצים ל-Git..." -ForegroundColor Blue
git add .
git commit -m "Update release files"

Write-Host "🌐 דחיפה ל-GitHub..." -ForegroundColor Blue
git push origin master

Write-Host "✅ ההעלאה הושלמה בהצלחה!" -ForegroundColor Green
Write-Host "🔗 עבור ל-GitHub ליצירת Release חדש:" -ForegroundColor Cyan
Write-Host "https://github.com/YOUR_USERNAME/flutter-financial-app/releases/new" -ForegroundColor Cyan