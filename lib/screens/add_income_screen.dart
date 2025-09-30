import 'package:flutter/material.dart';
import 'dart:math';
import '../models/income_models.dart';
import '../services/advanced_database_helper.dart';

class AddIncomeScreen extends StatefulWidget {
  final AdvancedIncome? income;
  final bool isEditing;

  const AddIncomeScreen({
    Key? key,
    this.income,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _invoiceNumberController = TextEditingController();

  late DateTime _selectedDate;
  IncomeType _selectedType = IncomeType.salary;
  IncomeFrequency _selectedFrequency = IncomeFrequency.oneTime;
  String _selectedPaymentMethod = 'העברה בנקאית';
  bool _isTaxable = true;
  bool _isReceived = false;
  bool _isLoading = false;

  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();

  final List<String> _paymentMethods = [
    'העברה בנקאית',
    'מזומן',
    'שיק',
    'כרטיס אשראי',
    'ארנק דיגיטלי',
    'אחר'
  ];

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNumber = random.nextInt(999999);
    return '${timestamp}_$randomNumber';
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    
    if (widget.isEditing && widget.income != null) {
      _initializeForEditing();
    }
  }

  void _initializeForEditing() {
    final income = widget.income!;
    _titleController.text = income.title;
    _amountController.text = income.amount.toString();
    _descriptionController.text = income.description;
    _taxAmountController.text = income.taxAmount.toString();
    _invoiceNumberController.text = income.invoiceNumber;
    _selectedDate = income.date;
    _selectedType = income.type;
    _selectedFrequency = income.frequency;
    _selectedPaymentMethod = income.paymentMethod;
    _isTaxable = income.isTaxable;
    _isReceived = income.isReceived;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _taxAmountController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'עריכת הכנסה' : 'הוספת הכנסה'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              _buildAmountCard(),
              const SizedBox(height: 16),
              _buildCategoryCard(),
              const SizedBox(height: 16),
              _buildPaymentCard(),
              const SizedBox(height: 16),
              _buildTaxCard(),
              const SizedBox(height: 16),
              _buildAdditionalInfoCard(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'פרטי ההכנסה',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'שם ההכנסה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'נא להזין שם להכנסה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'תיאור (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'תאריך ההכנסה',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'סכום ההכנסה',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'סכום ברוטו (₪) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                suffixText: '₪',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'נא להזין סכום';
                }
                if (double.tryParse(value) == null) {
                  return 'נא להזין סכום תקין';
                }
                if (double.parse(value) <= 0) {
                  return 'הסכום חייב להיות גדול מ-0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('ההכנסה התקבלה'),
              subtitle: Text(
                _isReceived ? 'ההכנסה נמצאת בחשבון' : 'ממתין לקבלת ההכנסה',
              ),
              value: _isReceived,
              onChanged: (value) {
                setState(() {
                  _isReceived = value;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'סוג ותדירות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<IncomeType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'סוג הכנסה',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: IncomeType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.hebrewName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<IncomeFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'תדירות',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: IncomeFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(frequency.hebrewName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'אמצעי תשלום',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'אמצעי תשלום',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(
                labelText: 'מספר חשבונית (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'פרטי מס',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('חייב במס'),
              subtitle: const Text('האם יש לנכות מס מההכנסה'),
              value: _isTaxable,
              onChanged: (value) {
                setState(() {
                  _isTaxable = value;
                  if (!value) {
                    _taxAmountController.text = '0';
                  }
                });
              },
              activeColor: Colors.orange,
            ),
            if (_isTaxable) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxAmountController,
                decoration: const InputDecoration(
                  labelText: 'סכום מס (₪)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calculate),
                  suffixText: '₪',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_isTaxable && (value == null || value.isEmpty)) {
                    return 'נא להזין סכום מס';
                  }
                  if (value != null && value.isNotEmpty) {
                    final taxAmount = double.tryParse(value);
                    if (taxAmount == null || taxAmount < 0) {
                      return 'נא להזין סכום מס תקין';
                    }
                    final totalAmount = double.tryParse(_amountController.text) ?? 0;
                    if (taxAmount > totalAmount) {
                      return 'סכום המס לא יכול להיות גדול מהסכום הכולל';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              if (_amountController.text.isNotEmpty && _taxAmountController.text.isNotEmpty)
                _buildTaxSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSummary() {
    final totalAmount = double.tryParse(_amountController.text) ?? 0;
    final taxAmount = double.tryParse(_taxAmountController.text) ?? 0;
    final netAmount = totalAmount - taxAmount;
    final taxPercentage = totalAmount > 0 ? (taxAmount / totalAmount) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('סכום ברוטו:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('₪${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('מס (${taxPercentage.toStringAsFixed(1)}%):', style: const TextStyle(color: Colors.red)),
              Text('-₪${taxAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('סכום נטו:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('₪${netAmount.toStringAsFixed(2)}', 
                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'מידע נוסף',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFrequency != IncomeFrequency.oneTime)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'הכנסה חוזרת - ${_selectedFrequency.hebrewName}',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveIncome,
        icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.save),
        label: Text(
          _isLoading 
            ? 'שומר...' 
            : (widget.isEditing ? 'עדכן הכנסה' : 'שמור הכנסה'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final income = AdvancedIncome(
        id: widget.isEditing ? widget.income!.id : _generateId(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _selectedType,
        frequency: _selectedFrequency,
        description: _descriptionController.text.trim(),
        isTaxable: _isTaxable,
        taxAmount: _isTaxable ? (double.tryParse(_taxAmountController.text) ?? 0) : 0,
        isReceived: _isReceived,
        paymentMethod: _selectedPaymentMethod,
        invoiceNumber: _invoiceNumberController.text.trim(),
        nextExpectedDate: _selectedFrequency != IncomeFrequency.oneTime 
          ? AdvancedIncome(
              id: '',
              title: '',
              amount: 0,
              date: _selectedDate,
              type: _selectedType,
              frequency: _selectedFrequency,
            ).calculateNextExpectedDate()
          : null,
      );

      if (widget.isEditing) {
        await _databaseHelper.updateAdvancedIncome(income);
        _showSnackBar('ההכנסה עודכנה בהצלחה!', Colors.green);
      } else {
        await _databaseHelper.insertAdvancedIncome(income);
        _showSnackBar('ההכנסה נשמרה בהצלחה!', Colors.green);
      }

      Navigator.of(context).pop(true); // מחזיר true לציין שהנתונים נשמרו
    } catch (e) {
      _showSnackBar('שגיאה בשמירת ההכנסה: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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