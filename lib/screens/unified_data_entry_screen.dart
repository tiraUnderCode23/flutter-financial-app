import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/advanced_database_helper.dart';
import '../models/debt_models.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';

class UnifiedDataEntryScreen extends StatefulWidget {
  const UnifiedDataEntryScreen({super.key});

  @override
  State<UnifiedDataEntryScreen> createState() => _UnifiedDataEntryScreenState();
}

class _UnifiedDataEntryScreenState extends State<UnifiedDataEntryScreen>
    with TickerProviderStateMixin {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();
  late TabController _tabController;

  // Form keys for validation
  final _incomeFormKey = GlobalKey<FormState>();
  final _expenseFormKey = GlobalKey<FormState>();
  final _checkFormKey = GlobalKey<FormState>();
  final _loanFormKey = GlobalKey<FormState>();

  // Controllers
  final _incomeAmountController = TextEditingController();
  final _incomeTitleController = TextEditingController();
  final _incomeNotesController = TextEditingController();

  final _expenseAmountController = TextEditingController();
  final _expenseTitleController = TextEditingController();
  final _expenseNotesController = TextEditingController();
  final _vendorController = TextEditingController();

  final _checkAmountController = TextEditingController();
  final _checkNumberController = TextEditingController();
  final _checkPayeeController = TextEditingController();
  final _checkBankController = TextEditingController();
  final _checkDescriptionController = TextEditingController();

  final _loanAmountController = TextEditingController();
  final _loanPaymentController = TextEditingController();
  final _loanRateController = TextEditingController();
  final _lenderController = TextEditingController();
  final _loanDescriptionController = TextEditingController();

  // State variables
  DateTime _incomeDate = DateTime.now();
  DateTime _expenseDate = DateTime.now();
  DateTime _checkIssueDate = DateTime.now();
  DateTime _checkDueDate = DateTime.now().add(Duration(days: 30));
  DateTime _loanStartDate = DateTime.now();
  DateTime _loanEndDate = DateTime.now().add(Duration(days: 365));

  bool _isLoading = false;
  bool _checkIsPaid = false;
  String? _selectedIncomeSource;
  String? _selectedExpenseCategory;
  String? _selectedPaymentMethod;
  List<ReceiptItem> _receiptItems = [];
  File? _receiptImage;

  // Quick access data
  List<String> _incomeSources = ['راتب', 'مشروع', 'استثمار', 'أخرى'];
  List<String> _expenseCategories = ['طعام', 'مواصلات', 'ترفيه', 'فواتير', 'أخرى'];
  List<String> _paymentMethods = ['نقد', 'بطاقة ائتمان', 'تحويل بنكي', 'شيك'];
  List<String> _vendors = [];

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNumber = random.nextInt(999999);
    return 'entry_${timestamp}_$randomNumber';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadQuickAccessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomeAmountController.dispose();
    _incomeTitleController.dispose();
    _incomeNotesController.dispose();
    _expenseAmountController.dispose();
    _expenseTitleController.dispose();
    _expenseNotesController.dispose();
    _vendorController.dispose();
    _checkAmountController.dispose();
    _checkNumberController.dispose();
    _checkPayeeController.dispose();
    _checkBankController.dispose();
    _checkDescriptionController.dispose();
    _loanAmountController.dispose();
    _loanPaymentController.dispose();
    _loanRateController.dispose();
    _lenderController.dispose();
    _loanDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadQuickAccessData() async {
    try {
      final expenses = await _databaseHelper.getAdvancedExpenses();
      final vendors = expenses
          .where((e) => e.vendor?.name != null && e.vendor!.name.isNotEmpty)
          .map((e) => e.vendor!.name)
          .toSet()
          .toList();
      setState(() {
        _vendors = vendors;
      });
    } catch (e) {
      print('Error loading quick access data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التسجيل والإدخال الموحد'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.attach_money), text: 'دخل'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'مصروفات'),
            Tab(icon: Icon(Icons.receipt_long), text: 'شيكات'),
            Tab(icon: Icon(Icons.account_balance), text: 'قروض'),
            Tab(icon: Icon(Icons.speed), text: 'تسجيل سريع'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomeTab(),
          _buildExpenseTab(),
          _buildCheckTab(),
          _buildLoanTab(),
          _buildQuickEntryTab(),
        ],
      ),
    );
  }

  Widget _buildIncomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _incomeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('تسجيل دخل جديد', Icons.attach_money, Colors.green),
            const SizedBox(height: 16),
            _buildAmountField(_incomeAmountController, 'المبلغ'),
            const SizedBox(height: 16),
            _buildTextField(_incomeTitleController, 'عنوان الدخل', Icons.title),
            const SizedBox(height: 16),
            _buildDropdownField(
              'مصدر الدخل',
              _selectedIncomeSource,
              _incomeSources,
              (value) => setState(() => _selectedIncomeSource = value),
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              'طريقة الدفع',
              _selectedPaymentMethod,
              _paymentMethods,
              (value) => setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 16),
            _buildDateField('تاريخ الدخل', _incomeDate, (date) => setState(() => _incomeDate = date)),
            const SizedBox(height: 16),
            _buildTextField(_incomeNotesController, 'ملاحظات', Icons.note, maxLines: 3),
            const SizedBox(height: 24),
            _buildSaveButton('حفظ الدخل', _saveIncome, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _expenseFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('تسجيل مصروف جديد', Icons.shopping_cart, Colors.red),
            const SizedBox(height: 16),
            _buildAmountField(_expenseAmountController, 'المبلغ'),
            const SizedBox(height: 16),
            _buildTextField(_expenseTitleController, 'عنوان المصروف', Icons.title),
            const SizedBox(height: 16),
            _buildDropdownField(
              'فئة المصروف',
              _selectedExpenseCategory,
              _expenseCategories,
              (value) => setState(() => _selectedExpenseCategory = value),
            ),
            const SizedBox(height: 16),
            _buildVendorField(),
            const SizedBox(height: 16),
            _buildDateField('تاريخ المصروف', _expenseDate, (date) => setState(() => _expenseDate = date)),
            const SizedBox(height: 16),
            _buildTextField(_expenseNotesController, 'ملاحظات', Icons.note, maxLines: 3),
            const SizedBox(height: 16),
            _buildReceiptSection(),
            const SizedBox(height: 24),
            _buildSaveButton('حفظ المصروف', _saveExpense, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _checkFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('تسجيل شيك جديد', Icons.receipt_long, Colors.blue),
            const SizedBox(height: 16),
            _buildTextField(_checkNumberController, 'رقم الشيك', Icons.numbers, isRequired: true),
            const SizedBox(height: 16),
            _buildAmountField(_checkAmountController, 'المبلغ'),
            const SizedBox(height: 16),
            _buildTextField(_checkPayeeController, 'المدفوع له', Icons.person, isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(_checkBankController, 'اسم البنك', Icons.account_balance),
            const SizedBox(height: 16),
            _buildDateField('تاريخ الإصدار', _checkIssueDate, (date) => setState(() => _checkIssueDate = date)),
            const SizedBox(height: 16),
            _buildDateField('تاريخ الاستحقاق', _checkDueDate, (date) => setState(() => _checkDueDate = date)),
            const SizedBox(height: 16),
            _buildCheckboxField('شيك مدفوع', _checkIsPaid, (value) => setState(() => _checkIsPaid = value ?? false)),
            const SizedBox(height: 16),
            _buildTextField(_checkDescriptionController, 'وصف', Icons.description, maxLines: 2),
            const SizedBox(height: 24),
            _buildSaveButton('حفظ الشيك', _saveCheck, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _loanFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('تسجيل قرض جديد', Icons.account_balance, Colors.orange),
            const SizedBox(height: 16),
            _buildAmountField(_loanAmountController, 'مبلغ القرض'),
            const SizedBox(height: 16),
            _buildAmountField(_loanPaymentController, 'القسط الشهري'),
            const SizedBox(height: 16),
            _buildTextField(_loanRateController, 'معدل الفائدة (%)', Icons.percent, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField(_lenderController, 'اسم المقرض', Icons.person, isRequired: true),
            const SizedBox(height: 16),
            _buildDateField('تاريخ البداية', _loanStartDate, (date) => setState(() => _loanStartDate = date)),
            const SizedBox(height: 16),
            _buildDateField('تاريخ النهاية', _loanEndDate, (date) => setState(() => _loanEndDate = date)),
            const SizedBox(height: 16),
            _buildTextField(_loanDescriptionController, 'وصف القرض', Icons.description, maxLines: 2),
            const SizedBox(height: 24),
            _buildSaveButton('حفظ القرض', _saveLoan, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('التسجيل السريع', Icons.speed, Colors.purple),
          const SizedBox(height: 16),
          _buildQuickEntryCard('دخل سريع', Icons.attach_money, Colors.green, () => _quickAddIncome()),
          const SizedBox(height: 12),
          _buildQuickEntryCard('مصروف سريع', Icons.shopping_cart, Colors.red, () => _quickAddExpense()),
          const SizedBox(height: 12),
          _buildQuickEntryCard('مسح فاتورة', Icons.camera_alt, Colors.blue, () => _scanReceipt()),
          const SizedBox(height: 12),
          _buildQuickEntryCard('شيك سريع', Icons.receipt_long, Colors.indigo, () => _quickAddCheck()),
          const SizedBox(height: 16),
          _buildRecentEntriesSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label (₪) *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.attach_money),
        suffixText: '₪',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'نا להזين $label';
        }
        if (double.tryParse(value) == null) {
          return 'נא להזין מספר תקין';
        }
        if (double.parse(value) <= 0) {
          return 'הסכום חייב להיות גדול מ-0';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'נא להזין $label';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildVendorField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _vendorController,
            decoration: const InputDecoration(
              labelText: 'اسم البائع/المورد',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) {
            _vendorController.text = value;
          },
          itemBuilder: (context) => _vendors
              .map((vendor) => PopupMenuItem(value: vendor, child: Text(vendor)))
              .toList(),
          child: const Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () => _selectDate(context, date, onChanged),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text('${date.day}/${date.month}/${date.year}'),
      ),
    );
  }

  Widget _buildCheckboxField(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildReceiptSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرفق الفاتورة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickReceiptImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('التقاط صورة'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickReceiptFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('من المعرض'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            if (_receiptImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _receiptImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _processReceiptWithOCR,
                icon: const Icon(Icons.text_fields),
                label: const Text('استخراج البيانات'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntryCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentEntriesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'العمليات الأخيرة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('سيتم عرض آخر العمليات المسجلة هنا'),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'جاري الحفظ...' : text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onChanged) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != initialDate) {
      onChanged(picked);
    }
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _receiptImage = File(image.path));
    }
  }

  Future<void> _pickReceiptFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _receiptImage = File(image.path));
    }
  }

  Future<void> _processReceiptWithOCR() async {
    if (_receiptImage == null) return;

    setState(() => _isLoading = true);
    try {
      // Placeholder for OCR functionality
      // You can implement OCR service integration here
      _showSnackBar('ميزة استخراج البيانات قيد التطوير', Colors.orange);
    } catch (e) {
      _showSnackBar('خطأ في استخراج البيانات: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveIncome() async {
    if (!_incomeFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final income = AdvancedIncome(
        id: _generateId(),
        title: _incomeTitleController.text.trim(),
        amount: double.parse(_incomeAmountController.text),
        date: _incomeDate,
        type: IncomeType.other,
        sourceId: '',
        description: _incomeNotesController.text.trim(),
        paymentMethod: _selectedPaymentMethod ?? 'نقد',
        taxAmount: 0.0,
      );

      await _databaseHelper.insertAdvancedIncome(income);
      _showSnackBar('تم حفظ الدخل بنجاح!', Colors.green);
      _clearIncomeForm();
    } catch (e) {
      _showSnackBar('خطأ في حفظ الدخل: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveExpense() async {
    if (!_expenseFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final expense = AdvancedExpense(
        id: _generateId(),
        title: _expenseTitleController.text.trim(),
        amount: double.parse(_expenseAmountController.text),
        date: _expenseDate,
        category: ExpenseCategory.general,
        paymentMethod: ExpensePaymentMethod.cash,
        notes: _expenseNotesController.text.trim(),
        vendor: Vendor(name: _vendorController.text.trim()),
        receiptItems: _receiptItems,
        receiptImagePath: _receiptImage?.path ?? '',
      );

      await _databaseHelper.insertAdvancedExpense(expense);
      _showSnackBar('تم حفظ المصروف بنجاح!', Colors.green);
      _clearExpenseForm();
    } catch (e) {
      _showSnackBar('خطأ في حفظ المصروف: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCheck() async {
    if (!_checkFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final check = Check(
        id: _generateId(),
        checkNumber: _checkNumberController.text.trim(),
        amount: double.parse(_checkAmountController.text),
        date: _checkIssueDate,
        payeeName: _checkPayeeController.text.trim(),
        bankName: _checkBankController.text.trim(),
        dueDate: _checkDueDate,
        isPaid: _checkIsPaid,
        description: _checkDescriptionController.text.trim(),
      );

      await _databaseHelper.insertCheck(check);
      _showSnackBar('تم حفظ الشيك بنجاح!', Colors.green);
      _clearCheckForm();
    } catch (e) {
      _showSnackBar('خطأ في حفظ الشيك: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLoan() async {
    if (!_loanFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final originalAmount = double.parse(_loanAmountController.text);
      final loan = Loan(
        id: _generateId(),
        originalAmount: originalAmount,
        monthlyPayment: double.parse(_loanPaymentController.text),
        startDate: _loanStartDate,
        endDate: _loanEndDate,
        lenderName: _lenderController.text.trim(),
        interestRate: double.tryParse(_loanRateController.text) ?? 0.0,
        remainingAmount: originalAmount,
        description: _loanDescriptionController.text.trim(),
      );

      await _databaseHelper.insertLoan(loan);
      _showSnackBar('تم حفظ القرض بنجاح!', Colors.green);
      _clearLoanForm();
    } catch (e) {
      _showSnackBar('خطأ في حفظ القرض: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _quickAddIncome() {
    _tabController.animateTo(0);
  }

  void _quickAddExpense() {
    _tabController.animateTo(1);
  }

  void _quickAddCheck() {
    _tabController.animateTo(2);
  }

  Future<void> _scanReceipt() async {
    await _pickReceiptImage();
    if (_receiptImage != null) {
      _tabController.animateTo(1);
      await _processReceiptWithOCR();
    }
  }

  void _clearIncomeForm() {
    _incomeAmountController.clear();
    _incomeTitleController.clear();
    _incomeNotesController.clear();
    setState(() {
      _selectedIncomeSource = null;
      _selectedPaymentMethod = null;
      _incomeDate = DateTime.now();
    });
  }

  void _clearExpenseForm() {
    _expenseAmountController.clear();
    _expenseTitleController.clear();
    _expenseNotesController.clear();
    _vendorController.clear();
    setState(() {
      _selectedExpenseCategory = null;
      _expenseDate = DateTime.now();
      _receiptItems.clear();
      _receiptImage = null;
    });
  }

  void _clearCheckForm() {
    _checkAmountController.clear();
    _checkNumberController.clear();
    _checkPayeeController.clear();
    _checkBankController.clear();
    _checkDescriptionController.clear();
    setState(() {
      _checkIsPaid = false;
      _checkIssueDate = DateTime.now();
      _checkDueDate = DateTime.now().add(Duration(days: 30));
    });
  }

  void _clearLoanForm() {
    _loanAmountController.clear();
    _loanPaymentController.clear();
    _loanRateController.clear();
    _lenderController.clear();
    _loanDescriptionController.clear();
    setState(() {
      _loanStartDate = DateTime.now();
      _loanEndDate = DateTime.now().add(Duration(days: 365));
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}