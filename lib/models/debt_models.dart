import 'dart:convert';

// מחלקה בסיסית לחוב
abstract class BaseDebt {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final bool isPaid;
  final String description;

  BaseDebt({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.isPaid = false,
    this.description = '',
  });

  Map<String, dynamic> toMap();
}

// שטרות (שיקים)
class Check extends BaseDebt {
  final String checkNumber;
  final String payeeName;
  final DateTime dueDate;
  final String bankName;

  Check({
    required String id,
    required this.checkNumber,
    required double amount,
    required DateTime date,
    required this.dueDate,
    required this.payeeName,
    this.bankName = '',
    bool isPaid = false,
    String description = '',
  }) : super(
         id: id,
         type: 'שטר',
         amount: amount,
         date: date,
         isPaid: isPaid,
         description: description,
       );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'checkNumber': checkNumber,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'payeeName': payeeName,
      'bankName': bankName,
      'isPaid': isPaid,
      'description': description,
    };
  }

  factory Check.fromMap(Map<String, dynamic> map) {
    return Check(
      id: map['id'] ?? '',
      checkNumber: map['checkNumber'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      payeeName: map['payeeName'] ?? '',
      bankName: map['bankName'] ?? '',
      isPaid: map['isPaid'] ?? false,
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Check.fromJson(String source) => Check.fromMap(json.decode(source));

  Check copyWith({
    String? checkNumber,
    double? amount,
    DateTime? date,
    DateTime? dueDate,
    String? payeeName,
    String? bankName,
    bool? isPaid,
    String? description,
  }) {
    return Check(
      id: id,
      checkNumber: checkNumber ?? this.checkNumber,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      payeeName: payeeName ?? this.payeeName,
      bankName: bankName ?? this.bankName,
      isPaid: isPaid ?? this.isPaid,
      description: description ?? this.description,
    );
  }
}

// הוראות קבע
class StandingOrder extends BaseDebt {
  final String payeeName;
  final String frequency; // חודשי, שבועי, וכו'
  final DateTime nextPaymentDate;
  final DateTime endDate;

  StandingOrder({
    required String id,
    required double amount,
    required DateTime date,
    required this.payeeName,
    required this.frequency,
    required this.nextPaymentDate,
    required this.endDate,
    bool isPaid = false,
    String description = '',
  }) : super(
         id: id,
         type: 'הוראת קבע',
         amount: amount,
         date: date,
         isPaid: isPaid,
         description: description,
       );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'payeeName': payeeName,
      'frequency': frequency,
      'nextPaymentDate': nextPaymentDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isPaid': isPaid,
      'description': description,
    };
  }

  factory StandingOrder.fromMap(Map<String, dynamic> map) {
    return StandingOrder(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      payeeName: map['payeeName'] ?? '',
      frequency: map['frequency'] ?? '',
      nextPaymentDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextPaymentDate'] ?? 0,
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] ?? 0),
      isPaid: map['isPaid'] ?? false,
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StandingOrder.fromJson(String source) =>
      StandingOrder.fromMap(json.decode(source));
}

// הלוואות
class Loan extends BaseDebt {
  final double originalAmount;
  final double monthlyPayment;
  final DateTime startDate;
  final DateTime endDate;
  final double interestRate;
  final String lenderName;
  final double remainingAmount;

  Loan({
    required String id,
    required this.originalAmount,
    required this.monthlyPayment,
    required this.startDate,
    required this.endDate,
    required this.lenderName,
    this.interestRate = 0.0,
    this.remainingAmount = 0.0,
    String description = '',
  }) : super(
         id: id,
         type: 'הלוואה',
         amount: originalAmount,
         date: startDate,
         isPaid: false,
         description: description,
       );

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'originalAmount': originalAmount,
      'monthlyPayment': monthlyPayment,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'interestRate': interestRate,
      'lenderName': lenderName,
      'remainingAmount': remainingAmount,
      'description': description,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] ?? '',
      originalAmount: (map['originalAmount'] ?? 0.0).toDouble(),
      monthlyPayment: (map['monthlyPayment'] ?? 0.0).toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] ?? 0),
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
      lenderName: map['lenderName'] ?? '',
      remainingAmount: (map['remainingAmount'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Loan.fromJson(String source) => Loan.fromMap(json.decode(source));

  // חישוב התשלומים שנותרו
  int getRemainingPayments() {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;

    final monthsRemaining =
        ((endDate.year - now.year) * 12) + (endDate.month - now.month);
    return monthsRemaining > 0 ? monthsRemaining : 0;
  }

  // חישוב הסכום שנותר לשלם
  double calculateRemainingAmount() {
    final paymentsRemaining = getRemainingPayments();
    return paymentsRemaining * monthlyPayment;
  }
}

// תשלום חוב
class DebtPayment {
  final String id;
  final String debtId;
  final String debtType;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String notes;

  DebtPayment({
    required this.id,
    required this.debtId,
    required this.debtType,
    required this.amount,
    required this.date,
    this.paymentMethod = 'מזומן',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'debtType': debtType,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] ?? '',
      debtId: map['debtId'] ?? '',
      debtType: map['debtType'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      paymentMethod: map['paymentMethod'] ?? 'מזומן',
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DebtPayment.fromJson(String source) =>
      DebtPayment.fromMap(json.decode(source));
}
