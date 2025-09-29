# Quick Start - העלאה מהירה ל-GitHub

## אופציה 1: GitHub CLI (מהיר)

### התקנה והתחברות:
```powershell
# GitHub CLI כבר מותקן, רק התחבר:
& "C:\Program Files\GitHub CLI\gh.exe" auth login
# בחר: GitHub.com → HTTPS → Yes → Login with web browser
```

### יצירת Repository:
```powershell
# הרץ את הscript האוטומטי:
.\create_github_repo.ps1
```

## אופציה 2: ידני (דפדפן)

### 1. צור Repository חדש ב-GitHub.com:
- Repository name: `flutter-financial-app`
- Description: `אפליקציית ניהול כספים מתקדמה בעברית`
- Public repository
- לא להוסיף README/License/.gitignore

### 2. חבר למאגר המקומי:
```bash
git remote add origin https://github.com/YOUR_USERNAME/flutter-financial-app.git
git push -u origin master
```

### 3. צור Release:
- עבור ל-Releases → Create new release
- Tag: `v1.0.0`
- Title: `אפליקציית ניהול כספים v1.0.0`
- העלה: `releases/flutter-financial-app-v1.0.0.apk`

---

## מה תקבל:
✅ Repository מלא עם כל הקוד
✅ APK מוכן להורדה (51.1MB)  
✅ תיעוד בעברית מקיף
✅ Release מוכן לפרסום

**הבחר באופציה הנוחה לך!** 🚀