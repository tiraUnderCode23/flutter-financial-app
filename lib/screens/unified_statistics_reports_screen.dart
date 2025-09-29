import 'package:flutter/material.dart';
import '../services/advanced_database_helper.dart';
import '../models/debt_models.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';

class UnifiedStatisticsReportsScreen extends StatefulWidget {
  const UnifiedStatisticsReportsScreen({super.key});

  @override
  State<UnifiedStatisticsReportsScreen> createState() =>
      _UnifiedStatisticsReportsScreenState();
}

class _UnifiedStatisticsReportsScreenState
    extends State<UnifiedStatisticsReportsScreen>
    with TickerProviderStateMixin {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();
  late TabController _tabController;

  // Data lists
  List<Check> _checks = [];
  List<Loan> _loans = [];
  List<AdvancedIncome> _incomes = [];
  List<AdvancedExpense> _expenses = [];
  bool _isLoading = true;

  // Time filters
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

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
          'סטטיסטיקות ודוחות',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E3A59),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'לוח בקרה'),
            Tab(icon: Icon(Icons.pie_chart), text: 'ניתוח פיננסי'),
            Tab(icon: Icon(Icons.timeline), text: 'תחזיות'),
            Tab(icon: Icon(Icons.list_alt), text: 'דוחות מפורטים'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildFinancialAnalysisTab(),
                _buildForecastTab(),
                _buildDetailedReportsTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    final filteredIncomes = _getFilteredIncomes();
    final filteredExpenses = _getFilteredExpenses();
    final totalIncome = filteredIncomes.fold<double>(
      0,
      (sum, i) => sum + i.amount,
    );
    final totalExpenses = filteredExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final netBalance = totalIncome - totalExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'סה"כ הכנסות',
                  totalIncome,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'סה"כ הוצאות',
                  totalExpenses,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'יתרה נטו',
                  netBalance,
                  netBalance >= 0 ? Colors.blue : Colors.orange,
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'עסקאות',
                  (filteredIncomes.length + filteredExpenses.length).toDouble(),
                  Colors.purple,
                  Icons.receipt,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Income vs Expenses Chart
          _buildIncomeExpensesChart(),

          const SizedBox(height: 20),

          // Debt Status
          _buildDebtStatusCard(),

          const SizedBox(height: 20),

          // Recent Transactions
          _buildRecentTransactionsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(2)} ₪',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpensesChart() {
    final filteredIncomes = _getFilteredIncomes();
    final filteredExpenses = _getFilteredExpenses();

    if (filteredIncomes.isEmpty && filteredExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('אין נתונים להצגה בתקופה שנבחרה'),
        ),
      );
    }

    final totalIncome = filteredIncomes.fold<double>(
      0,
      (sum, i) => sum + i.amount,
    );
    final totalExpenses = filteredExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final total = totalIncome + totalExpenses;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'השוואת הכנסות והוצאות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Income Bar
            Row(
              children: [
                const SizedBox(width: 80, child: Text('הכנסה:')),
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade300,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: total > 0 ? totalIncome / total : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${totalIncome.toStringAsFixed(0)} ₪'),
              ],
            ),
            const SizedBox(height: 12),

            // Expenses Bar
            Row(
              children: [
                const SizedBox(width: 80, child: Text('הוצאות:')),
                Expanded(
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade300,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: total > 0 ? totalExpenses / total : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${totalExpenses.toStringAsFixed(0)} ₪'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Expense Categories Chart
          _buildExpenseCategoriesChart(),

          const SizedBox(height: 20),

          // Income Sources Chart
          _buildIncomeSourcesChart(),

          const SizedBox(height: 20),

          // Monthly Trend
          _buildMonthlyTrendChart(),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoriesChart() {
    final filteredExpenses = _getFilteredExpenses();
    final categoryTotals = <ExpenseCategory, double>{};

    for (final expense in filteredExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('אין הוצאות להצגה בתקופה שנבחרה'),
        ),
      );
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxAmount = sortedCategories.first.value;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'הוצאות לפי קטגוריה',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Category bars
            ...sortedCategories.take(6).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key.hebrewName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade300,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: entry.value / maxAmount,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: _getCategoryColor(entry.key),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value.toStringAsFixed(0)} ₪',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeSourcesChart() {
    final filteredIncomes = _getFilteredIncomes();
    final typeTotals = <IncomeType, double>{};

    for (final income in filteredIncomes) {
      typeTotals[income.type] = (typeTotals[income.type] ?? 0) + income.amount;
    }

    if (typeTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('אין מקורות הכנסה להצגה בתקופה שנבחרה'),
        ),
      );
    }

    final sortedTypes = typeTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'מקורות הכנסה',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...sortedTypes.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(entry.key.hebrewName)),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / sortedTypes.first.value,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getIncomeTypeColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value.toStringAsFixed(0)} ₪'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    // Group data by month
    final monthlyData = <String, Map<String, double>>{};

    for (final income in _incomes) {
      final monthKey =
          '${income.date.year}-${income.date.month.toString().padLeft(2, '0')}';
      monthlyData.putIfAbsent(monthKey, () => {'income': 0, 'expense': 0});
      monthlyData[monthKey]!['income'] =
          monthlyData[monthKey]!['income']! + income.amount;
    }

    for (final expense in _expenses) {
      final monthKey =
          '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      monthlyData.putIfAbsent(monthKey, () => {'income': 0, 'expense': 0});
      monthlyData[monthKey]!['expense'] =
          monthlyData[monthKey]!['expense']! + expense.amount;
    }

    final sortedMonths = monthlyData.keys.toList()..sort();
    final lastSixMonths = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'מגמה חודשית (6 חודשים אחרונים)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Monthly data table
            if (lastSixMonths.isEmpty)
              const Text('אין נתונים להצגה')
            else
              Column(
                children: lastSixMonths.map((month) {
                  final income = monthlyData[month]!['income']!;
                  final expense = monthlyData[month]!['expense']!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(_formatMonthYear(month)),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 50,
                                    child: Text(
                                      'הכנסה:',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                  Text(
                                    '${income.toStringAsFixed(0)} ₪',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 50,
                                    child: Text(
                                      'הוצאה:',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  Text(
                                    '${expense.toStringAsFixed(0)} ₪',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDebtPaymentForecast(),
          const SizedBox(height: 20),
          _buildIncomeProjection(),
          const SizedBox(height: 20),
          _buildExpenseProjection(),
        ],
      ),
    );
  }

  Widget _buildDebtPaymentForecast() {
    final upcomingPayments = <String, List<Map<String, dynamic>>>{};

    // Calculate upcoming loan payments
    for (final loan in _loans.where((l) => !l.isPaid)) {
      var currentDate = DateTime.now();
      var remainingAmount = loan.remainingAmount;

      while (remainingAmount > 0 && upcomingPayments.length < 12) {
        final monthKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}';
        upcomingPayments.putIfAbsent(monthKey, () => []);

        final payment = remainingAmount > loan.monthlyPayment
            ? loan.monthlyPayment
            : remainingAmount;
        upcomingPayments[monthKey]!.add({
          'type': 'loan',
          'description': 'תשלום הלוואה ${loan.lenderName}',
          'amount': payment,
        });

        remainingAmount -= payment;
        currentDate = DateTime(currentDate.year, currentDate.month + 1);
      }
    }

    // Add upcoming check payments
    for (final check in _checks.where(
      (c) => !c.isPaid && c.dueDate.isAfter(DateTime.now()),
    )) {
      final monthKey =
          '${check.dueDate.year}-${check.dueDate.month.toString().padLeft(2, '0')}';
      upcomingPayments.putIfAbsent(monthKey, () => []);
      upcomingPayments[monthKey]!.add({
        'type': 'check',
        'description': 'שיק ${check.payeeName}',
        'amount': check.amount,
      });
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'תחזיות תשלום חובות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (upcomingPayments.isEmpty)
              const Text('אין תשלומים צפויים')
            else
              ...upcomingPayments.entries.take(6).map((entry) {
                final monthTotal = entry.value.fold<double>(
                  0,
                  (sum, payment) => sum + payment['amount'],
                );
                return ExpansionTile(
                  title: Text(_formatMonthYear(entry.key)),
                  subtitle: Text('סה"כ: ${monthTotal.toStringAsFixed(2)} ₪'),
                  children: entry.value
                      .map(
                        (payment) => ListTile(
                          leading: Icon(
                            payment['type'] == 'loan'
                                ? Icons.account_balance
                                : Icons.receipt,
                            color: const Color(0xFF2E3A59),
                          ),
                          title: Text(payment['description']),
                          trailing: Text(
                            '${payment['amount'].toStringAsFixed(2)} ₪',
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeProjection() {
    // Calculate projected income based on recurring income patterns
    final recurringIncomes = _incomes.where(
      (i) => i.frequency != IncomeFrequency.oneTime,
    );
    final projectedMonthly = recurringIncomes.fold<double>(0, (sum, income) {
      switch (income.frequency) {
        case IncomeFrequency.monthly:
          return sum + income.amount;
        case IncomeFrequency.weekly:
          return sum + (income.amount * 4.33); // Average weeks per month
        case IncomeFrequency.biWeekly:
          return sum + (income.amount * 2.17); // Average bi-weeks per month
        case IncomeFrequency.quarterly:
          return sum + (income.amount / 3);
        case IncomeFrequency.yearly:
          return sum + (income.amount / 12);
        default:
          return sum;
      }
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'תחזיות הכנסה',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('הכנסה חודשית צפויה'),
                    Text(
                      '${projectedMonthly.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('הכנסה שנתית צפויה'),
                    Text(
                      '${(projectedMonthly * 12).toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseProjection() {
    // Calculate average monthly expenses
    final last3Months = DateTime.now().subtract(const Duration(days: 90));
    final recentExpenses = _expenses.where((e) => e.date.isAfter(last3Months));
    final averageMonthly = recentExpenses.isEmpty
        ? 0.0
        : recentExpenses.fold<double>(0, (sum, e) => sum + e.amount) / 3;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'תחזיות הוצאות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('הוצאות חודשיות צפויות'),
                    Text(
                      '${averageMonthly.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('הוצאות שנתיות צפויות'),
                    Text(
                      '${(averageMonthly * 12).toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTransactionHistory(),
          const SizedBox(height: 20),
          _buildDebtDetails(),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final allTransactions = <Map<String, dynamic>>[];

    // Add income transactions
    for (final income in _getFilteredIncomes()) {
      allTransactions.add({
        'type': 'income',
        'title': income.title,
        'amount': income.amount,
        'date': income.date,
        'category': income.type.hebrewName,
        'description': income.description,
      });
    }

    // Add expense transactions
    for (final expense in _getFilteredExpenses()) {
      allTransactions.add({
        'type': 'expense',
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date,
        'category': expense.category.hebrewName,
        'description': expense.notes,
      });
    }

    // Sort by date (newest first)
    allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'היסטוריית עסקאות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (allTransactions.isEmpty)
              const Text('אין עסקאות בתקופה שנבחרה')
            else
              ...allTransactions
                  .take(20)
                  .map(
                    (transaction) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: transaction['type'] == 'income'
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Icon(
                            transaction['type'] == 'income'
                                ? Icons.add
                                : Icons.remove,
                            color: transaction['type'] == 'income'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(transaction['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(transaction['category']),
                            if (transaction['description'].isNotEmpty)
                              Text(
                                transaction['description'],
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${transaction['type'] == 'income' ? '+' : '-'}${transaction['amount'].toStringAsFixed(2)} ₪',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: transaction['type'] == 'income'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            Text(
                              _formatDate(transaction['date']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: transaction['description'].isNotEmpty,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פרטי חובות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Active Loans
            if (_loans.where((l) => !l.isPaid).isNotEmpty) ...[
              const Text(
                'הלוואות פעילות:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._loans.where((l) => !l.isPaid).map((loan) {
                final progress =
                    ((loan.originalAmount - loan.remainingAmount) /
                            loan.originalAmount *
                            100)
                        .clamp(0.0, 100.0);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('הלוואה מ-${loan.lenderName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'נותר: ${loan.remainingAmount.toStringAsFixed(2)} ₪ מתוך ${loan.originalAmount.toStringAsFixed(2)} ₪',
                        ),
                        LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 75
                                ? Colors.green
                                : progress > 50
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    trailing: Text('${progress.toStringAsFixed(1)}%'),
                    isThreeLine: true,
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Unpaid Checks
            if (_checks.where((c) => !c.isPaid).isNotEmpty) ...[
              const Text(
                'שיקים לא שולמו:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._checks
                  .where((c) => !c.isPaid)
                  .map(
                    (check) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('שיק ${check.payeeName}'),
                        subtitle: Text(
                          'מספר ${check.checkNumber} - ${check.amount.toStringAsFixed(2)} ₪',
                        ),
                        trailing: Text(
                          _formatDate(check.dueDate),
                          style: TextStyle(
                            color: check.dueDate.isBefore(DateTime.now())
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebtStatusCard() {
    final totalUnpaidChecks = _checks
        .where((c) => !c.isPaid)
        .fold<double>(0, (sum, c) => sum + c.amount);
    final totalUnpaidLoans = _loans
        .where((l) => !l.isPaid)
        .fold<double>(0, (sum, l) => sum + l.remainingAmount);
    final totalDebt = totalUnpaidChecks + totalUnpaidLoans;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'מצב חובות',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'סה"כ חובות',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${totalDebt.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'שיקים: ${_checks.where((c) => !c.isPaid).length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'הלוואות: ${_loans.where((l) => !l.isPaid).length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsCard() {
    final recentTransactions = <Map<String, dynamic>>[];

    // Add recent incomes
    for (final income in _incomes.take(5)) {
      recentTransactions.add({
        'type': 'income',
        'title': income.title,
        'amount': income.amount,
        'date': income.date,
      });
    }

    // Add recent expenses
    for (final expense in _expenses.take(5)) {
      recentTransactions.add({
        'type': 'expense',
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date,
      });
    }

    recentTransactions.sort((a, b) => b['date'].compareTo(a['date']));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'עסקאות אחרונות',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...recentTransactions
                .take(5)
                .map(
                  (transaction) => ListTile(
                    dense: true,
                    leading: Icon(
                      transaction['type'] == 'income'
                          ? Icons.add_circle
                          : Icons.remove_circle,
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(transaction['title']),
                    subtitle: Text(_formatDate(transaction['date'])),
                    trailing: Text(
                      '${transaction['type'] == 'income' ? '+' : '-'}${transaction['amount'].toStringAsFixed(2)} ₪',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction['type'] == 'income'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<AdvancedIncome> _getFilteredIncomes() {
    return _incomes
        .where(
          (income) =>
              income.date.isAfter(_selectedDateRange.start) &&
              income.date.isBefore(
                _selectedDateRange.end.add(const Duration(days: 1)),
              ),
        )
        .toList();
  }

  List<AdvancedExpense> _getFilteredExpenses() {
    return _expenses
        .where(
          (expense) =>
              expense.date.isAfter(_selectedDateRange.start) &&
              expense.date.isBefore(
                _selectedDateRange.end.add(const Duration(days: 1)),
              ),
        )
        .toList();
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.fuel:
        return Colors.red;
      case ExpenseCategory.housing:
        return Colors.green;
      case ExpenseCategory.health:
        return Colors.pink;
      case ExpenseCategory.entertainment:
        return Colors.purple;
      case ExpenseCategory.clothing:
        return Colors.teal;
      case ExpenseCategory.education:
        return Colors.indigo;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.general:
        return Colors.grey;
    }
  }

  Color _getIncomeTypeColor(IncomeType type) {
    switch (type) {
      case IncomeType.salary:
        return Colors.blue;
      case IncomeType.freelance:
        return Colors.green;
      case IncomeType.programming:
        return Colors.purple;
      case IncomeType.nightWork:
        return Colors.indigo;
      case IncomeType.additionalWork:
        return Colors.orange;
      case IncomeType.business:
        return Colors.red;
      case IncomeType.investment:
        return Colors.teal;
      case IncomeType.rental:
        return Colors.brown;
      case IncomeType.gift:
        return Colors.pink;
      case IncomeType.other:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMonthYear(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = parts[1];
    final monthNames = [
      '',
      'ינואר',
      'פברואר',
      'מרץ',
      'אפריל',
      'מאי',
      'יוני',
      'יולי',
      'אוגוסט',
      'ספטמבר',
      'אוקטובר',
      'נובמבר',
      'דצמבר',
    ];
    return '${monthNames[int.parse(month)]} $year';
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
