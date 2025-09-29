import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/expense_models.dart';

class GeminiOCRService {
  static const String _apiKey =
      'YOUR_GEMINI_API_KEY'; // יש להחליף עם המפתח האמיתי
  late final GenerativeModel _model;

  GeminiOCRService() {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
  }

  // קריאת קבלה מתמונה
  Future<ReceiptOCRData> processReceiptImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('קובץ התמונה לא נמצא');
      }

      final imageBytes = await imageFile.readAsBytes();

      final prompt = _buildHebrewPrompt();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), imagePart]),
      ]);

      if (response.text != null) {
        return _parseGeminiResponse(response.text!) ??
            _createEmptyReceiptData('לא ניתן לנתח את הקבלה');
      }

      return _createEmptyReceiptData('לא התקבלה תגובה מהשירות');
    } catch (e) {
      print('שגיאה בקריאת הקבלה: $e');
      return _createEmptyReceiptData('שגיאה בעיבוד הקבלה: $e');
    }
  }

  // יצירת נתוני קבלה ריקים במקרה של שגיאה
  ReceiptOCRData _createEmptyReceiptData(String errorMessage) {
    return ReceiptOCRData(
      vendorName: 'לא זוהה',
      totalAmount: 0.0,
      confidence: 0.0,
      rawData: {'error': errorMessage},
    );
  }

  // בניית הפרומפט בעברית
  String _buildHebrewPrompt() {
    return '''
נתח את התמונה של הקבלה וחלץ את המידע הבא בפורמט JSON:
{
  "vendorName": "שם החנות",
  "vendorAddress": "כתובת החנות",
  "vendorPhone": "טלפון החנות",
  "transactionDate": "תאריך העסקה בפורמט YYYY-MM-DD",
  "receiptNumber": "מספר הקבלה",
  "totalAmount": סכום כולל כמספר,
  "items": [
    {
      "name": "שם המוצר",
      "quantity": כמות כמספר,
      "unitPrice": מחיר_ליחידה כמספר,
      "unit": "יחידת מידה"
    }
  ],
  "confidence": רמת ביטחון בין 0-1
}

חשוב:
- תרגם את שמות המוצרים לעברית
- זהה מחירים בשקלים (₪)
- אם אין מידע על פריט מסוים, השאר ריק או 0
- ודא שהסכום הכולל תואם לסכום הפריטים
- החזר רק את ה-JSON ללא טקסט נוסף
''';
  }

  // פענוח תגובת Gemini
  ReceiptOCRData? _parseGeminiResponse(String response) {
    try {
      // ניקוי התגובה מטקסט מיותר
      String cleanJson = response.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }

      final data = json.decode(cleanJson);

      // המרת פריטים
      final List<ReceiptItem> items = [];
      if (data['items'] is List) {
        for (final item in data['items']) {
          items.add(
            ReceiptItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: item['name'] ?? '',
              quantity: (item['quantity'] ?? 1.0).toDouble(),
              unitPrice: (item['unitPrice'] ?? 0.0).toDouble(),
              unit: item['unit'] ?? 'יח',
            ),
          );
        }
      }

      // המרת תאריך
      DateTime? transactionDate;
      if (data['transactionDate'] != null) {
        try {
          transactionDate = DateTime.parse(data['transactionDate']);
        } catch (e) {
          print('שגיאה בפענוח התאריך: $e');
        }
      }

      return ReceiptOCRData(
        vendorName: data['vendorName'] ?? '',
        vendorAddress: data['vendorAddress'] ?? '',
        vendorPhone: data['vendorPhone'] ?? '',
        transactionDate: transactionDate,
        receiptNumber: data['receiptNumber'] ?? '',
        totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
        items: items,
        confidence: (data['confidence'] ?? 0.0).toDouble(),
        rawData: data,
      );
    } catch (e) {
      print('שגיאה בפענוח תגובת Gemini: $e');
      return null;
    }
  }

  // קטגוריזציה אוטומטית של מוצרים
  Future<String> categorizeItem(String itemName) async {
    try {
      final prompt =
          '''
קטגורז את המוצר הבא לאחת מהקטגוריות: מזון, תחבורה, דיור, בריאות, בידור, לבוש, חינוך, שירותים, כללי
מוצר: $itemName
השב רק עם שם הקטגוריה בעברית.
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      return response.text?.trim() ?? 'כללי';
    } catch (e) {
      print('שגיאה בקטגוריזציה: $e');
      return 'כללי';
    }
  }

  // זיהוי וחילוץ מידע על החנות
  Future<Vendor?> extractVendorInfo(
    String vendorName,
    String address,
    String phone,
  ) async {
    try {
      final prompt =
          '''
נתח את המידע הבא על החנות וחזר JSON עם מידע נוסף:
שם: $vendorName
כתובת: $address
טלפון: $phone

{
  "category": "קטגוריית החנות (סופרמרקט, מסעדה, בגדים וכו')",
  "website": "אתר אינטרנט אם ידוע"
}

השב רק עם ה-JSON.
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        final data = json.decode(response.text!.trim());
        return Vendor(
          name: vendorName,
          address: address.isNotEmpty ? address : null,
          phone: phone.isNotEmpty ? phone : null,
          category: data['category'],
          website: data['website'],
        );
      }

      return null;
    } catch (e) {
      print('שגיאה בחילוץ מידע החנות: $e');
      return null;
    }
  }

  // ניתוח מגמות רכישה
  Future<Map<String, dynamic>> analyzeSpendingPatterns(
    List<AdvancedExpense> expenses,
  ) async {
    try {
      final expensesData = expenses
          .take(20)
          .map(
            (expense) => {
              'amount': expense.amount,
              'category': expense.category.hebrewName,
              'vendor': expense.vendor?.name ?? 'לא ידוע',
              'date': expense.date.toIso8601String(),
              'items':
                  expense.receiptItems?.map((item) => item.name).join(', ') ??
                  '',
            },
          )
          .toList();

      final prompt =
          '''
נתח את דפוסי ההוצאות הבאים והחזר JSON עם תובנות:
${json.encode(expensesData)}

{
  "topCategories": ["הקטגוריות עם ההוצאה הגבוהה ביותר"],
  "frequentVendors": ["החנויות הנפוצות ביותר"],
  "spendingTrends": "מגמות הוצאה כלליות",
  "recommendations": ["המלצות לחיסכון"],
  "budgetSuggestions": {
    "מזון": סכום מומלץ,
    "תחבורה": סכום מומלץ
  }
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        return json.decode(response.text!.trim());
      }

      return {};
    } catch (e) {
      print('שגיאה בניתוח דפוסי הוצאה: $e');
      return {};
    }
  }

  // בדיקת תקינות מחיר
  Future<bool> validateReceiptAmount(
    double totalAmount,
    List<ReceiptItem> items,
  ) async {
    final calculatedTotal = items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final difference = (totalAmount - calculatedTotal).abs();

    // אם ההפרש גדול מ-10 שקלים או 10%, בקש בדיקה נוספת
    if (difference > 10 || (difference / totalAmount) > 0.1) {
      try {
        final prompt =
            '''
בדוק את התאמת המחירים בקבלה:
סכום כולל בקבלה: $totalAmount ₪
סכום מחושב מפריטים: $calculatedTotal ₪
פריטים: ${items.map((item) => '${item.name}: ${item.unitPrice}₪ x ${item.quantity}').join(', ')}

האם יש טעות בחישוב? תן הסבר קצר.
''';

        final response = await _model.generateContent([Content.text(prompt)]);

        print('אזהרת מחיר: ${response.text}');
        return false;
      } catch (e) {
        print('שגיאה בבדיקת מחיר: $e');
        return false;
      }
    }

    return true;
  }
}
