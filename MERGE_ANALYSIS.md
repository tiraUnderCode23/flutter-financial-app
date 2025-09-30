# تحليل الملفات للدمج والتنظيم

## الملفات الحالية في lib/screens:
1. add_check_screen.dart - شاشة إضافة الشيكات
2. add_expense_screen.dart - شاشة إضافة المصروفات  
3. add_income_screen.dart - شاشة إضافة الدخل
4. add_loan_screen.dart - شاشة إضافة القروض
5. enhanced_home_screen_simple.dart - الشاشة الرئيسية المحسنة
6. financial_app_main_screen.dart - الشاشة الرئيسية للتطبيق
7. statistics_screen.dart - شاشة الإحصائيات البسيطة
8. transactions_screen.dart - شاشة المعاملات
9. unified_daily_registration_screen.dart - شاشة التسجيل اليومي الموحدة
10. unified_settings_management_screen.dart - شاشة إدارة الإعدادات الموحدة
11. unified_statistics_reports_screen.dart - شاشة الإحصائيات والتقارير الموحدة

## خطة الدمج:

### 1. شاشة التسجيل اليومي الموحدة (unified_data_entry_screen.dart)
**دمج الملفات:**
- add_income_screen.dart
- add_expense_screen.dart
- add_check_screen.dart
- add_loan_screen.dart
- unified_daily_registration_screen.dart

**المميزات:**
- 5 تبويبات: دخل، مصروفات، شيكات، قروض، تسجيل سريع
- جميع وظائف الإدخال في مكان واحد
- إمكانية التبديل السريع بين أنواع البيانات

### 2. شاشة الإحصائيات والتقارير الموحدة (unified_analytics_screen.dart)
**دمج الملفات:**
- statistics_screen.dart
- unified_statistics_reports_screen.dart
- transactions_screen.dart

**المميزات:**
- 4 تبويبات: إحصائيات عامة، تقارير مفصلة، المعاملات، التحليلات المتقدمة
- جميع أنواع التقارير والإحصائيات في مكان واحد

### 3. شاشة الإعدادات الشاملة (unified_management_screen.dart)
**الاحتفاظ بـ:**
- unified_settings_management_screen.dart (محسن ومحدث)

**المميزات:**
- إدارة الديون والإعدادات
- لا تحتاج دمج لأنها شاملة بالفعل

### 4. الشاشة الرئيسية النهائية (main_app_screen.dart)
**دمج الملفات:**
- enhanced_home_screen_simple.dart
- financial_app_main_screen.dart

**المميزات:**
- تصميم موحد ومحسن
- دمج أفضل ميزات الشاشتين

## الملفات التي ستُحذف بعد الدمج:
1. add_check_screen.dart
2. add_expense_screen.dart
3. add_income_screen.dart
4. add_loan_screen.dart
5. statistics_screen.dart
6. transactions_screen.dart
7. unified_daily_registration_screen.dart
8. unified_statistics_reports_screen.dart
9. enhanced_home_screen_simple.dart
10. financial_app_main_screen.dart

## الملفات النهائية (4 ملفات فقط):
1. main_app_screen.dart - الشاشة الرئيسية
2. unified_data_entry_screen.dart - التسجيل والإدخال
3. unified_analytics_screen.dart - الإحصائيات والتحليلات
4. unified_management_screen.dart - الإعدادات والإدارة