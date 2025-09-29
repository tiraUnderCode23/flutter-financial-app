import 'package:flutter/material.dart';
import '../services/advanced_database_helper.dart';
import '../services/gemini_ocr_service.dart';
import '../models/expense_models.dart';
import '../models/income_models.dart';
import '../models/debt_models.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UnifiedDailyRegistrationScreen extends StatefulWidget {
  const UnifiedDailyRegistrationScreen({super.key});

  @override
  State<UnifiedDailyRegistrationScreen> createState() =>
      _UnifiedDailyRegistrationScreenState();
}

class _UnifiedDailyRegistrationScreenState
    extends State<UnifiedDailyRegistrationScreen>
    with TickerProviderStateMixin {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();
  final GeminiOCRService _ocrService = GeminiOCRService();
  late TabController _tabController;

  // Controllers
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _vendorController = TextEditingController();

  // Selected values
  DateTime _selectedDate = DateTime.now();
  String? _selectedStore;
  bool _isLoading = false;
  File? _receiptImage;
  List<ReceiptItem> _receiptItems = [];

  // Quick access data
  List<String> _frequentStores = [];
  Map<String, List<ReceiptItem>> _storeHistory = {};
  List<Loan> _availableLoans = [];
  String? _selectedLoanId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadQuickAccessData();
  }

  Future<void> _loadQuickAccessData() async {
    try {
      final expenses = await _databaseHelper.getAdvancedExpenses();
      final loans = await _databaseHelper.getLoans();
      final Set<String> stores = {};
      final Map<String, List<ReceiptItem>> storeItems = {};

      for (final expense in expenses) {
        if (expense.vendor?.name != null) {
          stores.add(expense.vendor!.name);
          if (expense.receiptItems?.isNotEmpty == true) {
            storeItems[expense.vendor!.name] = expense.receiptItems!;
          }
        }
      }

      setState(() {
        _frequentStores = stores.toList()..sort();
        _storeHistory = storeItems;
        _availableLoans = loans.where((loan) => !loan.isPaid).toList();
      });
    } catch (e) {
      print('שגיאה בטעינת נתונים: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'רישום יומי מקיף',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E3A59),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'קניות'),
            Tab(icon: Icon(Icons.attach_money), text: 'הכנסה'),
            Tab(icon: Icon(Icons.credit_card), text: 'חוב/הלוואה'),
            Tab(icon: Icon(Icons.payment), text: 'תשלום'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPurchaseTab(),
          _buildIncomeTab(),
          _buildDebtTab(),
          _buildPaymentTab(),
        ],
      ),
    );
  }

  Widget _buildPurchaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick OCR Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'סריקת קבלה חכמה',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _scanReceipt(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('צלם קבלה'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _scanReceipt(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('מהגלריה'),
                        ),
                      ),
                    ],
                  ),
                  if (_receiptImage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_receiptImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Manual Entry Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'רישום ידני',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Store Selection with History
                  DropdownButtonFormField<String>(
                    value: _selectedStore,
                    decoration: const InputDecoration(
                      labelText: 'בחר חנות',
                      prefixIcon: Icon(Icons.store),
                    ),
                    items: _frequentStores.map((store) {
                      return DropdownMenuItem(value: store, child: Text(store));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStore = value;
                        if (value != null && _storeHistory.containsKey(value)) {
                          _receiptItems = List.from(_storeHistory[value]!);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Amount and Title
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'סכום',
                            prefixIcon: Icon(Icons.money),
                            suffixText: '₪',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'תיאור',
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date Selection
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('תאריך'),
                    subtitle: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    onTap: () => _selectDate(),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'הערות',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Receipt Items List
                  if (_receiptItems.isNotEmpty) ...[
                    const Text(
                      'פריטים בקבלה:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_receiptItems.length, (index) {
                      final item = _receiptItems[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text('כמות: ${item.quantity}'),
                          trailing: Text(
                            '₪${item.totalPrice.toStringAsFixed(2)}',
                          ),
                          onTap: () => _editReceiptItem(index),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addReceiptItem,
                      icon: const Icon(Icons.add),
                      label: const Text('הוסף פריט'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePurchase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'שמור קנייה',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'רישום הכנסה',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'סכום הכנסה',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '₪',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'מקור ההכנסה',
                  prefixIcon: Icon(Icons.work),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'הערות',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveIncome();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'שמור הכנסה',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'רישום חוב/הלוואה',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'סכום החוב',
                  prefixIcon: Icon(Icons.credit_card),
                  suffixText: '₪',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'לבנק/לאדם',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'מטרת החוב',
                  prefixIcon: Icon(Icons.info),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveDebt();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('שמור חוב', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'תשלום חוב',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'סכום התשלום',
                  prefixIcon: Icon(Icons.payment),
                  suffixText: '₪',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'בחר חוב לתשלום',
                  prefixIcon: Icon(Icons.list),
                ),
                items: _availableLoans
                    .map(
                      (loan) => DropdownMenuItem(
                        value: loan.id,
                        child: Text(
                          '${loan.lenderName} - ${loan.remainingAmount.toStringAsFixed(2)} ₪',
                        ),
                      ),
                    )
                    .toList(),
                value: _selectedLoanId,
                onChanged: (value) {
                  setState(() {
                    _selectedLoanId = value;
                    if (value != null) {
                      final selectedLoan = _availableLoans.firstWhere(
                        (loan) => loan.id == value,
                      );
                      _titleController.text = selectedLoan.lenderName;
                      _amountController.text = selectedLoan.monthlyPayment
                          .toString();
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'הערות על התשלום',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _savePayment();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'שמור תשלום',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanReceipt(ImageSource source) async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() => _receiptImage = File(image.path));

        // Process with OCR
        final result = await _ocrService.processReceiptImage(File(image.path));

        setState(() {
          if (result.vendorName.isNotEmpty) {
            _vendorController.text = result.vendorName;
            _selectedStore = result.vendorName;
          }
          if (result.totalAmount > 0) {
            _amountController.text = result.totalAmount.toString();
          }
          _receiptItems = result.items;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בעיבוד הקבלה: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא מלא את כל השדות הנדרשים')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final expense = AdvancedExpense(
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: ExpenseCategory.general, // ברירת מחדל
        paymentMethod: ExpensePaymentMethod.cash, // ברירת מחדל
        vendor: _selectedStore != null ? Vendor(name: _selectedStore!) : null,
        receiptItems: _receiptItems,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await _databaseHelper.insertAdvancedExpense(expense);

      // Clear form
      _amountController.clear();
      _titleController.clear();
      _notesController.clear();
      _vendorController.clear();
      setState(() {
        _selectedStore = null;
        _receiptImage = null;
        _receiptItems = [];
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('הקנייה נשמרה בהצלחה')));

      // Refresh quick access data
      _loadQuickAccessData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בשמירת הקנייה: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Temporary variables for dialog inputs
  String _tempItemName = '';
  double _tempItemPrice = 0.0;
  double _tempItemQuantity = 1.0;

  Future<void> _saveIncome() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא מלא את כל השדות הנדרשים')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final income = AdvancedIncome(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: IncomeType.other,
        frequency: IncomeFrequency.oneTime,
        description: _notesController.text,
      );

      await _databaseHelper.insertAdvancedIncome(income);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('הכנסה נשמרה בהצלחה')));

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בשמירת הכנסה: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDebt() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא מלא את כל השדות הנדרשים')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loan = Loan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        lenderName: _titleController.text,
        originalAmount: double.parse(_amountController.text),
        remainingAmount: double.parse(_amountController.text),
        interestRate: 0.0,
        monthlyPayment: 0.0,
        startDate: _selectedDate,
        endDate: _selectedDate.add(const Duration(days: 365)),
        description: _notesController.text,
      );

      await _databaseHelper.insertLoan(loan);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('חוב נשמר בהצלחה')));

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בשמירת חוב: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePayment() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא מלא את כל השדות הנדרשים')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final check = Check(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        payeeName: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        dueDate: _selectedDate,
        checkNumber: 'CHK${DateTime.now().millisecondsSinceEpoch}',
        description: _notesController.text,
      );

      await _databaseHelper.insertCheck(check);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('תשלום נשמר בהצלחה')));

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בשמירת תשלום: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addReceiptItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוסף פריט'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'שם הפריט'),
              onChanged: (value) => _tempItemName = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'מחיר'),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _tempItemPrice = double.tryParse(value) ?? 0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'כמות'),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _tempItemQuantity = double.tryParse(value) ?? 1.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              if (_tempItemName.isNotEmpty && _tempItemPrice > 0) {
                setState(() {
                  _receiptItems.add(
                    ReceiptItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _tempItemName,
                      unitPrice: _tempItemPrice,
                      quantity: _tempItemQuantity,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('הוסף'),
          ),
        ],
      ),
    );
  }

  void _editReceiptItem(int index) {
    final item = _receiptItems[index];
    _tempItemName = item.name;
    _tempItemPrice = item.unitPrice;
    _tempItemQuantity = item.quantity;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ערוך פריט'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'שם הפריט'),
              controller: TextEditingController(text: _tempItemName),
              onChanged: (value) => _tempItemName = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'מחיר'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(
                text: _tempItemPrice.toString(),
              ),
              onChanged: (value) =>
                  _tempItemPrice = double.tryParse(value) ?? 0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'כמות'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(
                text: _tempItemQuantity.toString(),
              ),
              onChanged: (value) =>
                  _tempItemQuantity = double.tryParse(value) ?? 1.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _receiptItems.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              if (_tempItemName.isNotEmpty && _tempItemPrice > 0) {
                setState(() {
                  _receiptItems[index] = ReceiptItem(
                    id: _receiptItems[index].id, // keep original ID
                    name: _tempItemName,
                    unitPrice: _tempItemPrice,
                    quantity: _tempItemQuantity,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _amountController.clear();
    _titleController.clear();
    _notesController.clear();
    _vendorController.clear();
    setState(() {
      _selectedStore = null;
      _receiptItems.clear();
      _receiptImage = null;
      _selectedDate = DateTime.now();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _vendorController.dispose();
    super.dispose();
  }
}
