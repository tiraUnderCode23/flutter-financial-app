import 'dart:convert';

// קטגוריות הוצאות
enum ExpenseCategory {
  food('מזון'),
  transport('תחבורה'),
  fuel('דלק'),
  housing('דיור'),
  health('בריאות'),
  entertainment('בידור'),
  clothing('לבוש'),
  education('חינוך'),
  utilities('שירותים'),
  general('כללי');

  const ExpenseCategory(this.hebrewName);
  final String hebrewName;
}

// אמצעי תשלום
enum ExpensePaymentMethod {
  cash('מזומן'),
  creditCard('כרטיס אשראי'),
  debitCard('כרטיס חיוב'),
  bankTransfer('העברה בנקאית'),
  digitalWallet('ארנק דיגיטלי'),
  check('שטר');

  const ExpensePaymentMethod(this.hebrewName);
  final String hebrewName;
}

// פריט רכישה מתוך קבלה
class ReceiptItem {
  final String id;
  final String name;
  final double quantity;
  final double unitPrice;
  final String unit;
  final String category;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.unit = 'יח',
    this.category = 'אחר',
  });

  double get totalPrice => unitPrice * quantity;
  double get price => unitPrice; // alias for backward compatibility

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'price': unitPrice, // for database compatibility
      'unit': unit,
      'category': category,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 1.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? map['price'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'יח',
      category: map['category'] ?? 'אחר',
    );
  }

  String toJson() => json.encode(toMap());

  factory ReceiptItem.fromJson(String source) =>
      ReceiptItem.fromMap(json.decode(source));
}

// מקום מכירה
class Vendor {
  final String name;
  final String? address;
  final String? phone;
  final String? category;
  final String? website;
  final Map<String, dynamic> additionalInfo;

  Vendor({
    required this.name,
    this.address,
    this.phone,
    this.category,
    this.website,
    this.additionalInfo = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'category': category,
      'website': website,
      'additionalInfo': additionalInfo,
    };
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      name: map['name'] ?? '',
      address: map['address'],
      phone: map['phone'],
      category: map['category'],
      website: map['website'],
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory Vendor.fromJson(String source) => Vendor.fromMap(json.decode(source));
}

// הוצאה מתקדמת עם קבלה
class AdvancedExpense {
  final String? id;
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final ExpensePaymentMethod paymentMethod;
  final String? notes;
  final String? receiptImagePath;
  final Vendor? vendor;
  final List<ReceiptItem>? receiptItems;
  final ReceiptOCRData? ocrData;
  final bool isRecurring;

  AdvancedExpense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
    this.notes,
    this.receiptImagePath,
    this.vendor,
    this.receiptItems,
    this.ocrData,
    this.isRecurring = false,
  });

  // חישוב סכום כולל מפריטים
  double get calculatedTotal =>
      receiptItems?.fold<double>(0.0, (sum, item) => sum + item.totalPrice) ??
      amount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'receiptImagePath': receiptImagePath,
      'vendor': vendor?.toMap(),
      'receiptItems': receiptItems?.map((item) => item.toMap()).toList(),
      'ocrData': ocrData?.toMap(),
      'isRecurring': isRecurring,
    };
  }

  factory AdvancedExpense.fromMap(Map<String, dynamic> map) {
    return AdvancedExpense(
      id: map['id'],
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      category: ExpenseCategory.values.firstWhere(
        (cat) => cat.name == map['category'],
        orElse: () => ExpenseCategory.general,
      ),
      paymentMethod: ExpensePaymentMethod.values.firstWhere(
        (method) => method.name == map['paymentMethod'],
        orElse: () => ExpensePaymentMethod.cash,
      ),
      notes: map['notes'],
      receiptImagePath: map['receiptImagePath'],
      vendor: map['vendor'] != null
          ? Vendor.fromMap(Map<String, dynamic>.from(map['vendor']))
          : null,
      receiptItems: (map['receiptItems'] as List<dynamic>?)
          ?.map((item) => ReceiptItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      ocrData: map['ocrData'] != null
          ? ReceiptOCRData.fromMap(Map<String, dynamic>.from(map['ocrData']))
          : null,
      isRecurring: map['isRecurring'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AdvancedExpense.fromJson(String source) =>
      AdvancedExpense.fromMap(json.decode(source));

  AdvancedExpense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    String? notes,
    String? receiptImagePath,
    Vendor? vendor,
    List<ReceiptItem>? receiptItems,
    ReceiptOCRData? ocrData,
    bool? isRecurring,
  }) {
    return AdvancedExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      vendor: vendor ?? this.vendor,
      receiptItems: receiptItems ?? this.receiptItems,
      ocrData: ocrData ?? this.ocrData,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}

// נתוני OCR מקבלה
class ReceiptOCRData {
  final String vendorName;
  final String vendorAddress;
  final String vendorPhone;
  final DateTime? transactionDate;
  final String receiptNumber;
  final double totalAmount;
  final List<ReceiptItem> items;
  final Vendor? vendor;
  final double confidence;
  final Map<String, dynamic> rawData;

  ReceiptOCRData({
    required this.vendorName,
    this.vendorAddress = '',
    this.vendorPhone = '',
    this.transactionDate,
    this.receiptNumber = '',
    required this.totalAmount,
    this.items = const [],
    this.vendor,
    this.confidence = 0.0,
    this.rawData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'vendorName': vendorName,
      'vendorAddress': vendorAddress,
      'vendorPhone': vendorPhone,
      'transactionDate': transactionDate?.millisecondsSinceEpoch,
      'receiptNumber': receiptNumber,
      'totalAmount': totalAmount,
      'items': items.map((item) => item.toMap()).toList(),
      'vendor': vendor?.toMap(),
      'confidence': confidence,
      'rawData': rawData,
    };
  }

  factory ReceiptOCRData.fromMap(Map<String, dynamic> map) {
    return ReceiptOCRData(
      vendorName: map['vendorName'] ?? '',
      vendorAddress: map['vendorAddress'] ?? '',
      vendorPhone: map['vendorPhone'] ?? '',
      transactionDate: map['transactionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['transactionDate'])
          : null,
      receiptNumber: map['receiptNumber'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      items:
          (map['items'] as List<dynamic>?)
              ?.map(
                (item) => ReceiptItem.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          [],
      vendor: map['vendor'] != null
          ? Vendor.fromMap(Map<String, dynamic>.from(map['vendor']))
          : null,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      rawData: Map<String, dynamic>.from(map['rawData'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReceiptOCRData.fromJson(String source) =>
      ReceiptOCRData.fromMap(json.decode(source));
}
