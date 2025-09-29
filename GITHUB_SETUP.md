# הוראות העלאת הפרויקט ל-GitHub

## שלב 1: יצירת Repository ב-GitHub

1. היכנס ל-GitHub.com
2. לחץ על "New repository" או "+"
3. מלא את הפרטים:
   - **Repository name**: `flutter-financial-app`
   - **Description**: `אפליקציית ניהול כספים מתקדמה בעברית עם OCR ובינה מלאכותית`
   - **Public/Private**: בחר לפי הצורך
   - **לא לסמן**: Add a README file, Add .gitignore, Choose a license (כבר יש לנו)

## שלב 2: חיבור למאגר המקומי

הרץ את הפקודות הבאות ב-PowerShell:

```bash
# הוספת מאגר GitHub כ-remote
git remote add origin https://github.com/YOUR_USERNAME/flutter-financial-app.git

# דחיפת הקוד ל-GitHub
git push -u origin master
```

## שלב 3: יצירת Release ב-GitHub

1. עבור למאגר ב-GitHub
2. לחץ על "Releases" בצד ימין
3. לחץ על "Create a new release"
4. מלא את הפרטים:
   - **Tag version**: `v1.0.0`
   - **Release title**: `אפליקציית ניהול כספים v1.0.0`
   - **Description**: העתק את התיאור מ-CHANGELOG.md
   - **Attach files**: העלה את הקובץ `releases/flutter-financial-app-v1.0.0.apk`

## שלב 4: עדכון README עם הקישור הנכון

לאחר יצירת הRelease, עדכן את README.md:
```markdown
## 📱 הורדת האפליקציה

ניתן להוריד את ה-APK המוכן מהקישור: [הורדת APK](https://github.com/YOUR_USERNAME/flutter-financial-app/releases/latest)
```

## פרטי המאגר:
- 📁 קבצי הקוד: lib/, android/, ios/, web/, windows/, linux/, macos/
- 📱 APK מוכן: releases/flutter-financial-app-v1.0.0.apk (51.1MB)
- 📚 תיעוד: README.md, CHANGELOG.md, PROJECT_SUMMARY.md
- ⚖️ רישיון: MIT License

זה הכל! המאגר שלך מוכן ומכיל את כל הקבצים הנדרשים.