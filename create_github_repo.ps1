# Script ליצירת Repository ב-GitHub באמצעות GitHub CLI
# הרץ script זה רק לאחר שהתחברת ל-GitHub CLI עם: gh auth login

Write-Host "🚀 יצירת Repository ב-GitHub" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

# הגדרת נתיב GitHub CLI
$ghPath = "C:\Program Files\GitHub CLI\gh.exe"

# בדיקה שGitHub CLI זמין
if (-not (Test-Path $ghPath)) {
    Write-Host "❌ GitHub CLI לא נמצא. אנא התקן אותו תחילה." -ForegroundColor Red
    exit 1
}

Write-Host "🔐 בדיקת חיבור ל-GitHub..." -ForegroundColor Blue
try {
    & $ghPath auth status
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ לא מחובר ל-GitHub. אנא התחבר עם: gh auth login" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ שגיאה בבדיקת חיבור ל-GitHub" -ForegroundColor Red
    exit 1
}

Write-Host "📁 יצירת Repository..." -ForegroundColor Blue
$repoName = "flutter-financial-app"
$description = "אפליקציית ניהול כספים מתקדמה בעברית עם OCR ובינה מלאכותית - Flutter Financial Management App"

try {
    & $ghPath repo create $repoName --public --description $description --source=. --remote=origin --push
    Write-Host "✅ Repository נוצר בהצלחה!" -ForegroundColor Green
} catch {
    Write-Host "❌ שגיאה ביצירת Repository: $_" -ForegroundColor Red
    exit 1
}

Write-Host "📦 יצירת Release עם APK..." -ForegroundColor Blue
try {
    & $ghPath release create "v1.0.0" "releases/flutter-financial-app-v1.0.0.apk" --title "אפליקציית ניהול כספים v1.0.0" --notes-file "CHANGELOG.md"
    Write-Host "✅ Release נוצר בהצלחה!" -ForegroundColor Green
} catch {
    Write-Host "❌ שגיאה ביצירת Release: $_" -ForegroundColor Red
}

Write-Host "🎉 הפרויקט הועלה בהצלחה ל-GitHub!" -ForegroundColor Green
Write-Host "🔗 URL: https://github.com/$(& $ghPath auth status --show-hostname)/$(& $ghPath repo view --json name --jq .name)" -ForegroundColor Cyan

Write-Host "`n📱 להורדת APK:" -ForegroundColor Yellow
Write-Host "https://github.com/$(& $ghPath auth status --show-hostname)/$(& $ghPath repo view --json name --jq .name)/releases/latest" -ForegroundColor Cyan