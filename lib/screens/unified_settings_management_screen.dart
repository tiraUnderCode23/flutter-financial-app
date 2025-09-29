import 'package:flutter/material.dart';
import '../services/advanced_database_helper.dart';
import '../models/debt_models.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';

class UnifiedSettingsManagementScreen extends StatefulWidget {
  const UnifiedSettingsManagementScreen({super.key});

  @override
  State<UnifiedSettingsManagementScreen> createState() =>
      _UnifiedSettingsManagementScreenState();
}

class _UnifiedSettingsManagementScreenState
    extends State<UnifiedSettingsManagementScreen>
    with TickerProviderStateMixin {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();
  late TabController _tabController;

  // Data lists
  List<Check> _checks = [];
  List<Loan> _loans = [];
  List<AdvancedIncome> _incomes = [];
  List<AdvancedExpense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final checks = await _databaseHelper.getChecks();
      final loans = await _databaseHelper.getLoans();
      final incomes = await _databaseHelper.getAdvancedIncomes();
      final expenses = await _databaseHelper.getAdvancedExpenses();

      setState(() {
        _checks = checks;
        _loans = loans;
        _incomes = incomes;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת נתונים: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'הגדרות וניהול',
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
            Tab(icon: Icon(Icons.credit_card), text: 'ניהול חובות'),
            Tab(icon: Icon(Icons.work), text: 'מקורות הכנסה'),
            Tab(icon: Icon(Icons.category), text: 'קטגוריות הוצאות'),
            Tab(icon: Icon(Icons.settings), text: 'הגדרות מערכת'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDebtManagementTab(),
                _buildIncomeSourcesTab(),
                _buildExpenseCategoriesTab(),
                _buildSystemSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildDebtManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildDebtSummaryCard(),
          const SizedBox(height: 20),

          // Checks Section
          _buildSectionHeader('שיקים', Icons.receipt, _checks.length),
          ..._checks.map((check) => _buildCheckCard(check)),
          const SizedBox(height: 20),

          // Loans Section
          _buildSectionHeader('הלוואות', Icons.account_balance, _loans.length),
          ..._loans.map((loan) => _buildLoanCard(loan)),
          const SizedBox(height: 20),

          // Add New Debt Button
          _buildAddDebtButton(),
        ],
      ),
    );
  }

  Widget _buildDebtSummaryCard() {
    final totalChecks = _checks
        .where((c) => !c.isPaid)
        .fold<double>(0, (sum, c) => sum + c.amount);
    final totalLoans = _loans
        .where((l) => !l.isPaid)
        .fold<double>(0, (sum, l) => sum + l.remainingAmount);
    final totalDebts = totalChecks + totalLoans;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'סיכום חובות',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'סה"כ חובות',
                  '${totalDebts.toStringAsFixed(2)} ₪',
                  Colors.white,
                ),
                _buildSummaryItem(
                  'מספר שיקים',
                  '${_checks.where((c) => !c.isPaid).length}',
                  Colors.yellow.shade300,
                ),
                _buildSummaryItem(
                  'מספר הלוואות',
                  '${_loans.where((l) => !l.isPaid).length}',
                  Colors.green.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E3A59)),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3A59),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard(Check check) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: check.isPaid
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: check.isPaid ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          'שיק מספר ${check.checkNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('מוטב: ${check.payeeName}'),
            Text('סכום: ${check.amount.toStringAsFixed(2)} ₪'),
            Text('תאריך פירעון: ${_formatDate(check.dueDate)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!check.isPaid)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _markCheckAsPaid(check),
              ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('עריכה')),
                const PopupMenuItem(value: 'delete', child: Text('מחיקה')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editCheck(check);
                } else if (value == 'delete') {
                  _deleteCheck(check);
                }
              },
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final progressPercentage =
        ((loan.originalAmount - loan.remainingAmount) /
                loan.originalAmount *
                100)
            .clamp(0.0, 100.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'הלוואה מ-${loan.lenderName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'payment',
                      child: Text('הוספת תשלום'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('עריכה')),
                    const PopupMenuItem(value: 'delete', child: Text('מחיקה')),
                  ],
                  onSelected: (value) {
                    if (value == 'payment') {
                      _addLoanPayment(loan);
                    } else if (value == 'edit') {
                      _editLoan(loan);
                    } else if (value == 'delete') {
                      _deleteLoan(loan);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('סכום מקורי: ${loan.originalAmount.toStringAsFixed(2)} ₪'),
            Text('נותר: ${loan.remainingAmount.toStringAsFixed(2)} ₪'),
            Text('ריבית: ${loan.interestRate}%'),
            Text('תשלום חודשי: ${loan.monthlyPayment.toStringAsFixed(2)} ₪'),
            const SizedBox(height: 12),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage > 75
                          ? Colors.green
                          : progressPercentage > 50
                          ? Colors.orange
                          : Colors.red,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progressPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSourcesTab() {
    final groupedIncomes = <IncomeType, List<AdvancedIncome>>{};
    for (final income in _incomes) {
      groupedIncomes.putIfAbsent(income.type, () => []).add(income);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Income Summary
          _buildIncomeSummaryCard(),
          const SizedBox(height: 20),

          // Income Types
          ...groupedIncomes.entries.map(
            (entry) => _buildIncomeTypeSection(entry.key, entry.value),
          ),

          const SizedBox(height: 20),
          _buildAddIncomeSourceButton(),
        ],
      ),
    );
  }

  Widget _buildIncomeSummaryCard() {
    final currentMonth = DateTime.now();
    final monthlyIncome = _incomes
        .where(
          (income) =>
              income.date.year == currentMonth.year &&
              income.date.month == currentMonth.month,
        )
        .fold<double>(0, (sum, income) => sum + income.amount);

    final totalIncome = _incomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'סיכום הכנסות',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'הכנסה חודשית',
                  '${monthlyIncome.toStringAsFixed(2)} ₪',
                  Colors.white,
                ),
                _buildSummaryItem(
                  'סה"כ הכנסות',
                  '${totalIncome.toStringAsFixed(2)} ₪',
                  Colors.yellow.shade300,
                ),
                _buildSummaryItem(
                  'מספר מקורות',
                  '${_incomes.length}',
                  Colors.blue.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTypeSection(
    IncomeType type,
    List<AdvancedIncome> incomes,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(_getIncomeTypeIcon(type), color: const Color(0xFF2E3A59)),
        title: Text(
          type.hebrewName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${incomes.length} מקורות - ${incomes.fold<double>(0, (sum, i) => sum + i.amount).toStringAsFixed(2)} ₪',
        ),
        children: incomes
            .map(
              (income) => ListTile(
                title: Text(income.title),
                subtitle: Text(
                  '${income.amount.toStringAsFixed(2)} ₪ - ${_formatDate(income.date)}',
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('עריכה')),
                    const PopupMenuItem(value: 'delete', child: Text('מחיקה')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editIncome(income);
                    } else if (value == 'delete') {
                      _deleteIncome(income);
                    }
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildExpenseCategoriesTab() {
    final groupedExpenses = <ExpenseCategory, List<AdvancedExpense>>{};
    for (final expense in _expenses) {
      groupedExpenses.putIfAbsent(expense.category, () => []).add(expense);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Expense Summary
          _buildExpenseSummaryCard(),
          const SizedBox(height: 20),

          // Expense Categories
          ...groupedExpenses.entries.map(
            (entry) => _buildExpenseCategorySection(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSummaryCard() {
    final currentMonth = DateTime.now();
    final monthlyExpenses = _expenses
        .where(
          (expense) =>
              expense.date.year == currentMonth.year &&
              expense.date.month == currentMonth.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final categoriesCount = _expenses.map((e) => e.category).toSet().length;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFF87171)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'סיכום הוצאות',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'הוצאות חודשיות',
                  '${monthlyExpenses.toStringAsFixed(2)} ₪',
                  Colors.white,
                ),
                _buildSummaryItem(
                  'סה"כ הוצאות',
                  '${totalExpenses.toStringAsFixed(2)} ₪',
                  Colors.yellow.shade300,
                ),
                _buildSummaryItem(
                  'מספר קטגוריות',
                  '$categoriesCount',
                  Colors.blue.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategorySection(
    ExpenseCategory category,
    List<AdvancedExpense> expenses,
  ) {
    final totalAmount = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          _getExpenseCategoryIcon(category),
          color: const Color(0xFF2E3A59),
        ),
        title: Text(
          category.hebrewName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${expenses.length} עסקאות - ${totalAmount.toStringAsFixed(2)} ₪',
        ),
        children: expenses
            .take(5)
            .map(
              (expense) => ListTile(
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.amount.toStringAsFixed(2)} ₪ - ${_formatDate(expense.date)}',
                ),
                trailing: expense.vendor != null
                    ? Chip(
                        label: Text(
                          expense.vendor!.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue.shade100,
                      )
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSystemSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsSection('גיבוי ושחזור', [
            _buildSettingsTile(
              'יצירת גיבוי',
              'שמירת כל הנתונים',
              Icons.backup,
              _createBackup,
            ),
            _buildSettingsTile(
              'שחזור גיבוי',
              'שחזור הנתונים השמורים',
              Icons.restore,
              _restoreBackup,
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsSection('ניהול נתונים', [
            _buildSettingsTile(
              'ייצוא נתונים',
              'ייצוא לקובץ Excel',
              Icons.file_download,
              _exportData,
            ),
            _buildSettingsTile(
              'מחיקת כל הנתונים',
              'מחיקת כל הרשומות',
              Icons.delete_forever,
              _clearAllData,
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsSection('הגדרות בינה מלאכותית', [
            _buildSettingsTile(
              'הגדרות OCR',
              'הגדרת ניתוח קבלות',
              Icons.camera_alt,
              _configureOCR,
            ),
            _buildSettingsTile(
              'שיפור דיוק',
              'אימון המודל',
              Icons.auto_awesome,
              _improveAccuracy,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF2E3A59),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildAddDebtButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAddDebtDialog,
        icon: const Icon(Icons.add),
        label: const Text('הוספת חוב חדש'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E3A59),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAddIncomeSourceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAddIncomeDialog,
        icon: const Icon(Icons.add),
        label: const Text('הוספת מקור הכנסה חדש'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getIncomeTypeIcon(IncomeType type) {
    switch (type) {
      case IncomeType.salary:
        return Icons.work;
      case IncomeType.freelance:
        return Icons.computer;
      case IncomeType.programming:
        return Icons.code;
      case IncomeType.nightWork:
        return Icons.nights_stay;
      case IncomeType.additionalWork:
        return Icons.work_outline;
      case IncomeType.business:
        return Icons.business;
      case IncomeType.investment:
        return Icons.trending_up;
      case IncomeType.rental:
        return Icons.home;
      case IncomeType.gift:
        return Icons.card_giftcard;
      case IncomeType.other:
        return Icons.more_horiz;
    }
  }

  IconData _getExpenseCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.fuel:
        return Icons.local_gas_station;
      case ExpenseCategory.housing:
        return Icons.home;
      case ExpenseCategory.health:
        return Icons.local_hospital;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.clothing:
        return Icons.shopping_bag;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.utilities:
        return Icons.electrical_services;
      case ExpenseCategory.general:
        return Icons.category;
    }
  }

  // Action methods
  Future<void> _markCheckAsPaid(Check check) async {
    try {
      // Update check status to paid
      final updatedCheck = Check(
        id: check.id,
        checkNumber: check.checkNumber,
        payeeName: check.payeeName,
        amount: check.amount,
        date: check.date,
        dueDate: check.dueDate,
        bankName: check.bankName,
        isPaid: true,
        description: check.description,
      );

      await _databaseHelper.updateCheck(updatedCheck);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('השיק סומן כשולם')));

      // Reload data
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה בעדכון השיק: $e')));
    }
  }

  void _editCheck(Check check) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('עריכת שיקים תהיה זמינה בגרסה הבאה'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteCheck(Check check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת שיק'),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את השיק של ${check.description}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseHelper.deleteCheck(check.id);
                await _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('השיק נמחק בהצלחה')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה במחיקת השיק: $e')),
                );
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addLoanPayment(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוספת תשלום'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('הוספת תשלום להלוואה: ${loan.description}'),
            const SizedBox(height: 16),
            Text('יתרה נוכחית: ₪${loan.remainingAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('תשלום חודשי: ₪${loan.monthlyPayment.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('הוספת תשלומים תהיה זמינה במסך הרישום היומי'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('הוסף תשלום'),
          ),
        ],
      ),
    );
  }

  void _editLoan(Loan loan) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('עריכת הלוואות תהיה זמינה בגרסה הבאה'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteLoan(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת הלוואה'),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את ההלוואה של ${loan.description}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseHelper.deleteLoan(loan.id);
                await _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ההלוואה נמחקה בהצלחה')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה במחיקת ההלוואה: $e')),
                );
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editIncome(AdvancedIncome income) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('עריכת הכנסות תהיה זמינה בגרסה הבאה'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteIncome(AdvancedIncome income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת הכנסה'),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את ההכנסה "${income.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseHelper.deleteAdvancedIncome(income.id);
                await _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ההכנסה נמחקה בהצלחה')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה במחיקת ההכנסה: $e')),
                );
              }
            },
            child: const Text('מחק', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הוספת חוב חדש'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('הוספת שיק'),
              subtitle: const Text('יצירת שיק חדש למעקב'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('הוספת שיקים זמינה במסך הרישום היומי'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('הוספת הלוואה'),
              subtitle: const Text('יצירת הלוואה חדשה למעקב'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('הוספת הלוואות זמינה במסך הרישום היומי'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _showAddIncomeDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הוספת הכנסות זמינה במסך הרישום היומי'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      await _databaseHelper.createBackup();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('הגיבוי נוצר בהצלחה!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה ביצירת הגיבוי: $e')));
    }
  }

  Future<void> _restoreBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'שחזור גיבוי זמין רק כשקובץ גיבוי מוכן. יש ליצור גיבוי תחילה.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ייצוא נתונים'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('בחר את סוג הנתונים לייצוא:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('ייצוא שיקים'),
              onTap: () {
                Navigator.pop(context);
                _exportChecks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('ייצוא הלוואות'),
              onTap: () {
                Navigator.pop(context);
                _exportLoans();
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('ייצוא הכנסות'),
              onTap: () {
                Navigator.pop(context);
                _exportIncomes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('ייצוא הוצאות'),
              onTap: () {
                Navigator.pop(context);
                _exportExpenses();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  void _exportChecks() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'נמצאו ${_checks.length} שיקים לייצוא. התכונה תושלם בגרסה הבאה.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportLoans() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'נמצאו ${_loans.length} הלוואות לייצוא. התכונה תושלם בגרסה הבאה.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportIncomes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'נמצאו ${_incomes.length} הכנסות לייצוא. התכונה תושלם בגרסה הבאה.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportExpenses() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'נמצאו ${_expenses.length} הוצאות לייצוא. התכונה תושלם בגרסה הבאה.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת כל הנתונים'),
        content: const Text(
          'האם אתה בטוח שברצונך למחוק את כל הנתונים? פעולה זו לא ניתנת לביטול!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseHelper.clearAllData();
                await _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('כל הנתונים נמחקו בהצלחה')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה במחיקת הנתונים: $e')),
                );
              }
            },
            child: const Text('מחק הכל', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _configureOCR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הגדרות OCR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'הגדרות ניתוח קבלות אוטומטי:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('שפת זיהוי'),
              subtitle: const Text('עברית ואנגלית'),
              trailing: const Icon(Icons.check, color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('רמת דיוק'),
              subtitle: const Text('גבוהה'),
              trailing: const Icon(Icons.check, color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('זיהוי אוטומטי'),
              subtitle: const Text('פריטים וסכומים'),
              trailing: const Icon(Icons.check, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('הגדרות OCR מותאמות לעברית')),
              );
            },
            child: const Text('שמור הגדרות'),
          ),
        ],
      ),
    );
  }

  void _improveAccuracy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שיפור דיוק המודל'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('אופציות לשיפור דיוק זיהוי הקבלות:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('איכות צילום'),
              subtitle: const Text('הנחיות לצילום טוב יותר'),
              onTap: () {
                Navigator.pop(context);
                _showPhotoTips();
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('דיווח שגיאות'),
              subtitle: const Text('עזרה בתיקון זיהוי שגוי'),
              onTap: () {
                Navigator.pop(context);
                _reportAccuracyIssue();
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('סטטיסטיקות דיוק'),
              subtitle: const Text('צפייה בביצועי המודל'),
              onTap: () {
                Navigator.pop(context);
                _showAccuracyStats();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  void _showPhotoTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('טיפים לצילום קבלות'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• צלם בתאורה טובה'),
            Text('• החזק את המכשיר יציב'),
            Text('• ודא שהקבלה שטוחה'),
            Text('• צלם מזווית ישרה'),
            Text('• הקפד על חדות התמונה'),
            Text('• הימנע מצללים'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('הבנתי'),
          ),
        ],
      ),
    );
  }

  void _reportAccuracyIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('דיווח שגיאות יתווסף בגרסה הבאה'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showAccuracyStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סטטיסטיקות דיוק'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('זיהוי מוצלח'),
              trailing: const Text('85%'),
            ),
            ListTile(
              leading: const Icon(Icons.error, color: Colors.orange),
              title: const Text('זיהוי חלקי'),
              trailing: const Text('12%'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('זיהוי כושל'),
              trailing: const Text('3%'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
