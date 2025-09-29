#!/bin/bash
# Script להעלאת הפרויקט ל-GitHub

echo "🚀 העלאת אפליקציית ניהול כספים ל-GitHub"
echo "========================================"

# בדיקה שיש remote
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "❌ לא נמצא remote origin. הוסף אותו עם:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/flutter-financial-app.git"
    exit 1
fi

echo "📦 בניית APK חדש..."
flutter build apk --release

echo "📁 העתקת APK לתיקיית releases..."
cp build/app/outputs/flutter-apk/app-release.apk releases/flutter-financial-app-v1.0.0.apk

echo "📤 הוספת קבצים ל-Git..."
git add .
git commit -m "Update release files"

echo "🌐 דחיפה ל-GitHub..."
git push origin master

echo "✅ ההעלאה הושלמה בהצלחה!"
echo "🔗 עבור ל-GitHub ליצירת Release חדש:"
echo "https://github.com/YOUR_USERNAME/flutter-financial-app/releases/new"