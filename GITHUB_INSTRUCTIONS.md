# יצירת Repository ב-GitHub - הוראות מפורטות

## שיטה 1: דרך דפדפן האינטרנט (מומלץ)

### שלב 1: יצירת Repository חדש
1. פתח https://github.com
2. התחבר לחשבון שלך
3. לחץ על הכפתור הירוק "New" או על "+" בפינה הימנית העליונה
4. בחר "New repository"

### שלב 2: הגדרות Repository
מלא את הפרטים הבאים:
- **Repository name**: `flutter-financial-app`
- **Description**: `אפליקציית ניהול כספים מתקדמה בעברית עם OCR ובינה מלאכותית - Flutter app for advanced financial management in Hebrew`
- **Visibility**: Public או Private (לפי בחירתך)
- **לא לסמן**: Add a README, Add .gitignore, Choose a license (כבר יש לנו)

### שלב 3: חיבור למאגר המקומי
לאחר יצירת הRepository, GitHub יציג הוראות. הרץ את הפקודות הבאות:

```bash
# חיבור למאגר GitHub (החלף YOUR_USERNAME בשם המשתמש שלך)
git remote add origin https://github.com/YOUR_USERNAME/flutter-financial-app.git

# דחיפת הקוד למאגר
git push -u origin master
```

### שלב 4: יצירת Release
1. עבור לדף הRepository ב-GitHub
2. לחץ על "Releases" בצד ימין
3. לחץ על "Create a new release"
4. מלא:
   - **Tag version**: `v1.0.0`
   - **Release title**: `אפליקציית ניהול כספים v1.0.0 - Flutter Financial App`
   - **Description**: העתק את התוכן מקובץ CHANGELOG.md
5. בחלק "Attach binaries":
   - גרור והטל את הקובץ `releases/flutter-financial-app-v1.0.0.apk`
6. לחץ על "Publish release"

## שיטה 2: דרך GitHub CLI (אם הצלחת להתחבר)

```bash
# יצירת repository
gh repo create flutter-financial-app --public --description "אפליקציית ניהול כספים מתקדמה בעברית עם OCR ובינה מלאכותית"

# דחיפת הקוד
git push -u origin master

# יצירת release עם APK
gh release create v1.0.0 releases/flutter-financial-app-v1.0.0.apk --title "אפליקציית ניהול כספים v1.0.0" --notes-file CHANGELOG.md
```

## מידע על הAPK שנוצר:
- **שם קובץ**: `flutter-financial-app-v1.0.0.apk`
- **גודל**: 51.1MB (53,608,619 bytes)
- **מיקום**: `releases/flutter-financial-app-v1.0.0.apk`
- **גרסה**: v1.0.0 (Release)

## תכונות האפליקציה:
✅ ממשק בעברית מלא עם תמיכה ב-RTL
✅ רישום הכנסות והוצאות יומי
✅ ניהול חובות (שיקים והלוואות)
✅ זיהוי קבלות אוטומטי עם OCR
✅ דוחות וגרפים מתקדמים
✅ גיבוי ושחזור נתונים
✅ עיצוב Material Design 3

## לאחר ההעלאה:
- הקישור לRepository יהיה: https://github.com/YOUR_USERNAME/flutter-financial-app
- הקישור להורדת APK יהיה: https://github.com/YOUR_USERNAME/flutter-financial-app/releases/latest