import 'dart:convert';

// סוגי הכנסה
enum IncomeType {
  salary('משכורת'),
  freelance('עבודה עצמאית'),
  programming('עבודת תכנות'),
  nightWork('עבודת לילה'),
  additionalWork('עבודה נוספת'),
  investment('השקעות'),
  rental('שכירות'),
  business('עסק'),
  gift('מתנה'),
  other('אחר');

  const IncomeType(this.hebrewName);
  final String hebrewName;
}

// תדירות הכנסה
enum IncomeFrequency {
  oneTime('חד פעמי'),
  daily('יומי'),
  weekly('שבועי'),
  biWeekly('דו שבועי'),
  monthly('חודשי'),
  quarterly('רבעוני'),
  yearly('שנתי');

  const IncomeFrequency(this.hebrewName);
  final String hebrewName;
}

// מקור הכנסה
class IncomeSource {
  final String id;
  final String name;
  final IncomeType type;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final bool isActive;

  IncomeSource({
    required this.id,
    required this.name,
    required this.type,
    this.contactPerson = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: IncomeType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => IncomeType.other,
      ),
      contactPerson: map['contactPerson'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory IncomeSource.fromJson(String source) =>
      IncomeSource.fromMap(json.decode(source));
}

// הכנסה מתקדמת
class AdvancedIncome {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final IncomeType type;
  final String sourceId;
  final IncomeFrequency frequency;
  final DateTime? nextExpectedDate;
  final String description;
  final bool isTaxable;
  final double taxAmount;
  final bool isReceived;
  final String paymentMethod;
  final String invoiceNumber;
  final Map<String, dynamic> additionalData;

  AdvancedIncome({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.sourceId = '',
    this.frequency = IncomeFrequency.oneTime,
    this.nextExpectedDate,
    this.description = '',
    this.isTaxable = true,
    this.taxAmount = 0.0,
    this.isReceived = false,
    this.paymentMethod = 'העברה בנקאית',
    this.invoiceNumber = '',
    this.additionalData = const {},
  });

  // חישוב הכנסה נטו
  double get netAmount => amount - taxAmount;

  // חישוב אחוז מס
  double get taxPercentage => amount > 0 ? (taxAmount / amount) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'type': type.name,
      'sourceId': sourceId,
      'frequency': frequency.name,
      'nextExpectedDate': nextExpectedDate?.millisecondsSinceEpoch,
      'description': description,
      'isTaxable': isTaxable,
      'taxAmount': taxAmount,
      'isReceived': isReceived,
      'paymentMethod': paymentMethod,
      'invoiceNumber': invoiceNumber,
      'additionalData': additionalData,
    };
  }

  factory AdvancedIncome.fromMap(Map<String, dynamic> map) {
    return AdvancedIncome(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      type: IncomeType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => IncomeType.other,
      ),
      sourceId: map['sourceId'] ?? '',
      frequency: IncomeFrequency.values.firstWhere(
        (freq) => freq.name == map['frequency'],
        orElse: () => IncomeFrequency.oneTime,
      ),
      nextExpectedDate: map['nextExpectedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextExpectedDate'])
          : null,
      description: map['description'] ?? '',
      isTaxable: map['isTaxable'] ?? true,
      taxAmount: (map['taxAmount'] ?? 0.0).toDouble(),
      isReceived: map['isReceived'] ?? false,
      paymentMethod: map['paymentMethod'] ?? 'העברה בנקאית',
      invoiceNumber: map['invoiceNumber'] ?? '',
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory AdvancedIncome.fromJson(String source) =>
      AdvancedIncome.fromMap(json.decode(source));

  AdvancedIncome copyWith({
    String? title,
    double? amount,
    DateTime? date,
    IncomeType? type,
    String? sourceId,
    IncomeFrequency? frequency,
    DateTime? nextExpectedDate,
    String? description,
    bool? isTaxable,
    double? taxAmount,
    bool? isReceived,
    String? paymentMethod,
    String? invoiceNumber,
    Map<String, dynamic>? additionalData,
  }) {
    return AdvancedIncome(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      frequency: frequency ?? this.frequency,
      nextExpectedDate: nextExpectedDate ?? this.nextExpectedDate,
      description: description ?? this.description,
      isTaxable: isTaxable ?? this.isTaxable,
      taxAmount: taxAmount ?? this.taxAmount,
      isReceived: isReceived ?? this.isReceived,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // חישוב ההכנסה הצפויה הבאה על בסיס התדירות
  DateTime? calculateNextExpectedDate() {
    switch (frequency) {
      case IncomeFrequency.oneTime:
        return null;
      case IncomeFrequency.daily:
        return date.add(const Duration(days: 1));
      case IncomeFrequency.weekly:
        return date.add(const Duration(days: 7));
      case IncomeFrequency.biWeekly:
        return date.add(const Duration(days: 14));
      case IncomeFrequency.monthly:
        return DateTime(date.year, date.month + 1, date.day);
      case IncomeFrequency.quarterly:
        return DateTime(date.year, date.month + 3, date.day);
      case IncomeFrequency.yearly:
        return DateTime(date.year + 1, date.month, date.day);
    }
  }
}

// פרויקט או עבודה
class WorkProject {
  final String id;
  final String name;
  final String clientName;
  final DateTime startDate;
  final DateTime? endDate;
  final double hourlyRate;
  final double hoursWorked;
  final double totalAmount;
  final bool isCompleted;
  final String description;
  final List<String> skills;
  final IncomeType projectType;

  WorkProject({
    required this.id,
    required this.name,
    required this.clientName,
    required this.startDate,
    this.endDate,
    this.hourlyRate = 0.0,
    this.hoursWorked = 0.0,
    this.totalAmount = 0.0,
    this.isCompleted = false,
    this.description = '',
    this.skills = const [],
    this.projectType = IncomeType.freelance,
  });

  double get calculatedTotal => hourlyRate * hoursWorked;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'hourlyRate': hourlyRate,
      'hoursWorked': hoursWorked,
      'totalAmount': totalAmount,
      'isCompleted': isCompleted,
      'description': description,
      'skills': skills,
      'projectType': projectType.name,
    };
  }

  factory WorkProject.fromMap(Map<String, dynamic> map) {
    return WorkProject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      clientName: map['clientName'] ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
      hoursWorked: (map['hoursWorked'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      description: map['description'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      projectType: IncomeType.values.firstWhere(
        (type) => type.name == map['projectType'],
        orElse: () => IncomeType.freelance,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkProject.fromJson(String source) =>
      WorkProject.fromMap(json.decode(source));
}
