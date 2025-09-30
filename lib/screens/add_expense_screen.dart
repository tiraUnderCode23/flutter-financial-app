import 'package:flutter/material.dart';
import 'dart:math';
import '../models/expense_models.dart';
import '../services/advanced_database_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final AdvancedExpense? expense;
  final bool isEditing;

  const AddExpenseScreen({
    Key? key,
    this.expense,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _vendorNameController = TextEditingController();

  late DateTime _selectedDate;
  ExpenseCategory _selectedCategory = ExpenseCategory.general;
  ExpensePaymentMethod _selectedPaymentMethod = ExpensePaymentMethod.cash;
  bool _isLoading = false;
  List<ReceiptItem> _receiptItems = [];

  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();

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
    
    if (widget.isEditing && widget.expense != null) {
      _initializeForEditing();
    }
  }

  void _initializeForEditing() {
    final expense = widget.expense!;
    _titleController.text = expense.title;
    _amountController.text = expense.amount.toString();
    _notesController.text = expense.notes ?? '';
    _vendorNameController.text = expense.vendor?.name ?? '';
    _selectedDate = expense.date;
    _selectedCategory = expense.category;
    _selectedPaymentMethod = expense.paymentMethod;
    _receiptItems = List.from(expense.receiptItems ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _vendorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'עריכת הוצאה' : 'הוספת הוצאה'),
        backgroundColor: Colors.red.shade800,
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
              _buildVendorCard(),
              const SizedBox(height: 16),
              _buildReceiptItemsCard(),
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
              'פרטי ההוצאה',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'שם ההוצאה *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_cart),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'נא להזין שם להוצאה';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'הערות (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'תאריך ההוצאה',
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
              'סכום ההוצאה',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'סכום (₪) *',
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
            if (_receiptItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAmountSummary(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSummary() {
    final manualAmount = double.tryParse(_amountController.text) ?? 0;
    final itemsTotal = _receiptItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final difference = manualAmount - itemsTotal;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: difference.abs() < 0.01 ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: difference.abs() < 0.01 ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('סכום ידני:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('₪${manualAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('סכום פריטים:'),
              Text('₪${itemsTotal.toStringAsFixed(2)}'),
            ],
          ),
          if (difference.abs() >= 0.01) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('הפרש:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '₪${difference.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: difference > 0 ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
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
              'קטגוריה ותשלום',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'קטגוריית הוצאה',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ExpenseCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.hebrewName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpensePaymentMethod>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'אמצעי תשלום',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: ExpensePaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.hebrewName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'פרטי ספק',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vendorNameController,
              decoration: const InputDecoration(
                labelText: 'שם הספק/חנות (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'פריטים בקבלה',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addReceiptItem,
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף פריט'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_receiptItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'אין פריטים בקבלה',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'לחץ "הוסף פריט" כדי להוסיף פריטים',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _receiptItems.length,
                itemBuilder: (context, index) {
                  final item = _receiptItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.quantity} ${item.unit} × ₪${item.unitPrice.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₪${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editReceiptItem(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeReceiptItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
        onPressed: _isLoading ? null : _saveExpense,
        icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.save),
        label: Text(
          _isLoading 
            ? 'שומר...' 
            : (widget.isEditing ? 'עדכן הוצאה' : 'שמור הוצאה'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade800,
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

  void _addReceiptItem() {
    _showReceiptItemDialog();
  }

  void _editReceiptItem(int index) {
    _showReceiptItemDialog(item: _receiptItems[index], index: index);
  }

  void _removeReceiptItem(int index) {
    setState(() {
      _receiptItems.removeAt(index);
    });
  }

  void _showReceiptItemDialog({ReceiptItem? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '1');
    final priceController = TextEditingController(text: item?.unitPrice.toString() ?? '');
    final unitController = TextEditingController(text: item?.unit ?? 'יח');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'הוסף פריט' : 'ערוך פריט'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'שם הפריט',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'כמות',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'יחידה',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'מחיר ליחידה (₪)',
                  border: OutlineInputBorder(),
                  suffixText: '₪',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  priceController.text.isNotEmpty && 
                  quantityController.text.isNotEmpty) {
                final newItem = ReceiptItem(
                  id: item?.id ?? _generateId(),
                  name: nameController.text,
                  quantity: double.tryParse(quantityController.text) ?? 1,
                  unitPrice: double.tryParse(priceController.text) ?? 0,
                  unit: unitController.text.isNotEmpty ? unitController.text : 'יח',
                  category: _selectedCategory.hebrewName,
                );

                setState(() {
                  if (index != null) {
                    _receiptItems[index] = newItem;
                  } else {
                    _receiptItems.add(newItem);
                  }
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Vendor? vendor;
      if (_vendorNameController.text.trim().isNotEmpty) {
        vendor = Vendor(name: _vendorNameController.text.trim());
      }

      final expense = AdvancedExpense(
        id: widget.isEditing ? widget.expense!.id : _generateId(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        vendor: vendor,
        receiptItems: _receiptItems.isNotEmpty ? _receiptItems : null,
      );

      if (widget.isEditing) {
        await _databaseHelper.updateAdvancedExpense(expense);
        _showSnackBar('ההוצאה עודכנה בהצלחה!', Colors.green);
      } else {
        await _databaseHelper.insertAdvancedExpense(expense);
        _showSnackBar('ההוצאה נשמרה בהצלחה!', Colors.green);
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnackBar('שגיאה בשמירת ההוצאה: $e', Colors.red);
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