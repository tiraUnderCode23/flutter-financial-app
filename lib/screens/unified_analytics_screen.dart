import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../services/advanced_database_helper.dart';
import '../models/debt_models.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';

class UnifiedAnalyticsScreen extends StatefulWidget {
  const UnifiedAnalyticsScreen({super.key});

  @override
  State<UnifiedAnalyticsScreen> createState() => _UnifiedAnalyticsScreenState();
}

class _UnifiedAnalyticsScreenState extends State<UnifiedAnalyticsScreen>
    with TickerProviderStateMixin {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();
  late TabController _tabController;

  // Analytics data
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _totalChecks = 0.0;
  double _totalLoans = 0.0;
  List<AdvancedIncome> _incomes = [];
  List<AdvancedExpense> _expenses = [];
  List<Check> _checks = [];
  List<Loan> _loans = [];

  // Chart data
  List<PieChartSectionData> _expenseChartData = [];
  List<PieChartSectionData> _incomeChartData = [];
  List<FlSpot> _monthlyTrendData = [];

  // Time period
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'شهر';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات والتقارير'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
          PopupMenuButton<String>(
            onSelected: _changePeriod,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'أسبوع', child: Text('أسبوع')),
              const PopupMenuItem(value: 'شهر', child: Text('شهر')),
              const PopupMenuItem(value: '3 أشهر', child: Text('3 أشهر')),
              const PopupMenuItem(value: 'سنة', child: Text('سنة')),
              const PopupMenuItem(value: 'مخصص', child: Text('فترة مخصصة')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedPeriod),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'نظرة عامة'),
            Tab(icon: Icon(Icons.pie_chart), text: 'الرسوم البيانية'),
            Tab(icon: Icon(Icons.trending_up), text: 'الاتجاهات'),
            Tab(icon: Icon(Icons.list), text: 'المعاملات'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildChartsTab(),
                _buildTrendsTab(),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final balance = _totalIncome - _totalExpenses;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildSummaryCards(balance),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('توزيع المصروفات', Icons.pie_chart, Colors.red),
          const SizedBox(height: 16),
          _buildExpenseChart(),
          const SizedBox(height: 32),
          _buildSectionHeader('توزيع الدخل', Icons.pie_chart, Colors.green),
          const SizedBox(height: 16),
          _buildIncomeChart(),
          const SizedBox(height: 32),
          _buildSectionHeader('مقارنة الدخل والمصروفات', Icons.bar_chart, Colors.blue),
          const SizedBox(height: 16),
          _buildComparisonChart(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('الاتجاه الشهري', Icons.trending_up, Colors.purple),
          const SizedBox(height: 16),
          _buildMonthlyTrendChart(),
          const SizedBox(height: 32),
          _buildSectionHeader('إحصائيات متقدمة', Icons.analytics, Colors.orange),
          const SizedBox(height: 16),
          _buildAdvancedStats(),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'الدخل'),
              Tab(text: 'المصروفات'),
              Tab(text: 'الشيكات'),
              Tab(text: 'القروض'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildIncomeTransactions(),
                _buildExpenseTransactions(),
                _buildCheckTransactions(),
                _buildLoanTransactions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الفترة الزمنية: $_selectedPeriod',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'من ${_formatDate(_startDate)} إلى ${_formatDate(_endDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double balance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'إجمالي الدخل',
                _totalIncome,
                Icons.arrow_upward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'إجمالي المصروفات',
                _totalExpenses,
                Icons.arrow_downward,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'الرصيد',
                balance,
                balance >= 0 ? Icons.trending_up : Icons.trending_down,
                balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'الشيكات',
                _totalChecks,
                Icons.receipt,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  '₪${_formatAmount(amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات سريعة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('متوسط الدخل اليومي', _totalIncome / 30),
            _buildStatRow('متوسط المصروفات اليومية', _totalExpenses / 30),
            _buildStatRow('نسبة الادخار', 
                _totalIncome > 0 ? ((_totalIncome - _totalExpenses) / _totalIncome) * 100 : 0,
                isPercentage: true),
            _buildStatRow('عدد المعاملات', (_incomes.length + _expenses.length).toDouble()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, {bool isPercentage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            isPercentage 
                ? '${value.toStringAsFixed(1)}%'
                : '₪${_formatAmount(value)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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

  Widget _buildExpenseChart() {
    if (_expenseChartData.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات للمصروفات'),
      );
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: _expenseChartData,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildIncomeChart() {
    if (_incomeChartData.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات للدخل'),
      );
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: _incomeChartData,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildComparisonChart() {
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: max(_totalIncome, _totalExpenses) * 1.2,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _totalIncome,
                  color: Colors.green,
                  width: 40,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _totalExpenses,
                  color: Colors.red,
                  width: 40,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('الدخل');
                    case 1:
                      return const Text('المصروفات');
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    if (_monthlyTrendData.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات كافية للاتجاه'),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: _monthlyTrendData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تحليل متقدم',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('أعلى مصروف', _getHighestExpense()),
            _buildStatRow('أعلى دخل', _getHighestIncome()),
            _buildStatRow('متوسط المعاملة', _getAverageTransaction()),
            _buildStatRow('القروض المعلقة', _totalLoans),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = [
      ..._incomes.take(3).map((i) => {
            'title': i.title,
            'amount': i.amount,
            'type': 'دخل',
            'date': i.date,
            'color': Colors.green,
          }),
      ..._expenses.take(3).map((e) => {
            'title': e.title,
            'amount': e.amount,
            'type': 'مصروف',
            'date': e.date,
            'color': Colors.red,
          }),
    ];

    recentTransactions.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آخر المعاملات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentTransactions.take(5).map((transaction) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (transaction['color'] as Color).withOpacity(0.1),
                    child: Icon(
                      transaction['type'] == 'دخل' 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward,
                      color: transaction['color'] as Color,
                    ),
                  ),
                  title: Text(transaction['title'] as String),
                  subtitle: Text(transaction['type'] as String),
                  trailing: Text(
                    '₪${_formatAmount(transaction['amount'] as double)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transaction['color'] as Color,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTransactions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incomes.length,
      itemBuilder: (context, index) {
        final income = _incomes[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.attach_money, color: Colors.green),
            ),
            title: Text(income.title),
            subtitle: Text(_formatDate(income.date)),
            trailing: Text(
              '₪${_formatAmount(income.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseTransactions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: const Icon(Icons.shopping_cart, color: Colors.red),
            ),
            title: Text(expense.title),
            subtitle: Text('${expense.category.hebrewName} - ${_formatDate(expense.date)}'),
            trailing: Text(
              '₪${_formatAmount(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckTransactions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _checks.length,
      itemBuilder: (context, index) {
        final check = _checks[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(
                check.isPaid ? Icons.check_circle : Icons.receipt,
                color: check.isPaid ? Colors.green : Colors.blue,
              ),
            ),
            title: Text('شيك #${check.checkNumber}'),
            subtitle: Text('${check.payeeName} - ${_formatDate(check.dueDate)}'),
            trailing: Text(
              '₪${_formatAmount(check.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: check.isPaid ? Colors.green : Colors.orange,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoanTransactions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loan = _loans[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.account_balance, color: Colors.orange),
            ),
            title: Text(loan.lenderName),
            subtitle: Text('قسط شهري: ₪${_formatAmount(loan.monthlyPayment)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₪${_formatAmount(loan.remainingAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'متبقي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all data
      _incomes = await _databaseHelper.getAdvancedIncomes();
      _expenses = await _databaseHelper.getAdvancedExpenses();
      _checks = await _databaseHelper.getChecks();
      _loans = await _databaseHelper.getLoans();

      // Filter by date range
      _incomes = _incomes.where((income) => 
          income.date.isAfter(_startDate) && income.date.isBefore(_endDate.add(Duration(days: 1)))
      ).toList();
      
      _expenses = _expenses.where((expense) => 
          expense.date.isAfter(_startDate) && expense.date.isBefore(_endDate.add(Duration(days: 1)))
      ).toList();

      // Calculate totals
      _totalIncome = _incomes.fold(0.0, (sum, income) => sum + income.amount);
      _totalExpenses = _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      _totalChecks = _checks.fold(0.0, (sum, check) => sum + check.amount);
      _totalLoans = _loans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);

      // Generate chart data
      _generateChartData();
      
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateChartData() {
    // Expense chart data
    final expenseCategories = <ExpenseCategory, double>{};
    for (final expense in _expenses) {
      expenseCategories[expense.category] = 
          (expenseCategories[expense.category] ?? 0) + expense.amount;
    }

    _expenseChartData = expenseCategories.entries.map((entry) {
      final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue];
      final color = colors[entry.key.index % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key.hebrewName}\n₪${_formatAmount(entry.value)}',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    // Income chart data
    final incomeTypes = <IncomeType, double>{};
    for (final income in _incomes) {
      incomeTypes[income.type] = 
          (incomeTypes[income.type] ?? 0) + income.amount;
    }

    _incomeChartData = incomeTypes.entries.map((entry) {
      final colors = [Colors.green, Colors.teal, Colors.cyan, Colors.lightGreen, Colors.lime];
      final color = colors[entry.key.index % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.key.hebrewName}\n₪${_formatAmount(entry.value)}',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    // Monthly trend data (placeholder)
    _monthlyTrendData = List.generate(6, (index) {
      return FlSpot(index.toDouble(), (Random().nextDouble() * 1000) + 500);
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case 'أسبوع':
          _startDate = now.subtract(Duration(days: 7));
          _endDate = now;
          break;
        case 'شهر':
          _startDate = now.subtract(Duration(days: 30));
          _endDate = now;
          break;
        case '3 أشهر':
          _startDate = now.subtract(Duration(days: 90));
          _endDate = now;
          break;
        case 'سنة':
          _startDate = now.subtract(Duration(days: 365));
          _endDate = now;
          break;
        case 'مخصص':
          _showCustomDatePicker();
          return;
      }
    });
    
    _loadAnalyticsData();
  }

  Future<void> _showCustomDatePicker() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (dateRange != null) {
      setState(() {
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });
      _loadAnalyticsData();
    }
  }

  double _getHighestExpense() {
    if (_expenses.isEmpty) return 0.0;
    return _expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  double _getHighestIncome() {
    if (_incomes.isEmpty) return 0.0;
    return _incomes.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  }

  double _getAverageTransaction() {
    final totalTransactions = _incomes.length + _expenses.length;
    if (totalTransactions == 0) return 0.0;
    return (_totalIncome + _totalExpenses) / totalTransactions;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}