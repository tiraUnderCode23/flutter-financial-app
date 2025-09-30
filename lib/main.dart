import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_app_screen.dart';

void main() {
  runApp(const FinancialApp());
}

class FinancialApp extends StatelessWidget {
  const FinancialApp({super.key});

  @override
  Widget build(BuildContext context) {
    // הגדרת שורת הסטטוס
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'מנהל כספים מתקדם',
      debugShowCheckedModeBanner: false,

      // תמיכה בעברית
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'), // עברית
        Locale('en', 'US'), // אנגלית כגיבוי
      ],
      locale: const Locale('he', 'IL'),

      // כיוון RTL לעברית
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },

      theme: ThemeData(
        useMaterial3: true,

        // ערכת צבעים ירוקה-כחולה (צבעי הדגל הישראלי)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0066CC), // כחול ישראלי
          brightness: Brightness.light,
        ),

        // גופן תומך עברית
        fontFamily: 'Roboto',

        // עיצוב שורת הכותרת
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),

        // עיצוב כרטיסים
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.1),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        // עיצוב כפתורים
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // עיצוב שדות טקסט
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),

        // עיצוב תפריטים
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),

        // עיצוב טאבים
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF0066CC),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF0066CC),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),

        // עיצוב תיבות דו-שיח
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),

        // כפתור צף
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          backgroundColor: Color(0xFF0066CC),
        ),
      ),

      home: const MainAppScreen(),
    );
  }
}
