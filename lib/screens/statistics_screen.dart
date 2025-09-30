import 'package:flutter/material.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';
import '../services/advanced_database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();

  List<AdvancedIncome> _incomes = [];
  List<AdvancedExpense> _expenses = [];
  bool _isLoading = false;
  
  Map<String, double> _expensesByCategory = {};
  Map<String, double> _incomesByType = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final incomes = await _databaseHelper.getAdvancedIncomes();
      final expenses = await _databaseHelper.getAdvancedExpenses();
      final expensesByCategory = await _databaseHelper.getExpensesByCategory();
      final incomesByType = await _databaseHelper.getIncomesByType();

      setState(() {
        _incomes = incomes;
        _expenses = expenses;
        _expensesByCategory = expensesByCategory;
        _incomesByType = incomesByType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('שגיאה בטעינת הנתונים: $e', Colors.red);
    }
  }

  double get _totalIncomes => _incomes.fold(0, (sum, income) => sum + income.amount);
  double get _totalExpenses => _expenses.fold(0, (sum, expense) => sum + expense.amount);
  double get _balance => _totalIncomes - _totalExpenses;

  // הכנסות החודש הנוכחי
  double get _monthlyIncomes {
    final now = DateTime.now();
    return _incomes.where((income) {
      return income.date.year == now.year && income.date.month == now.month;
    }).fold(0, (sum, income) => sum + income.amount);
  }

  // הוצאות החודש הנוכחי
  double get _monthlyExpenses {
    final now = DateTime.now();
    return _expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).fold(0, (sum, expense) => sum + expense.amount);
  }

  // ממוצע הוצאות יומי
  double get _dailyAverageExpenses {
    if (_expenses.isEmpty) return 0;
    
    final now = DateTime.now();
    final thisMonth = _expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
    
    if (thisMonth.isEmpty) return 0;
    
    final totalDays = now.day;
    final totalAmount = thisMonth.fold(0.0, (sum, expense) => sum + expense.amount);
    
    return totalAmount / totalDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('סטטיסטיקות פיננסיות'),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildMonthlyAnalysis(),
                    const SizedBox(height: 24),
                    _buildExpensesCategoryChart(),
                    const SizedBox(height: 24),
                    _buildIncomesTypeChart(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סיכום כללי',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'סך הכנסות',
                '₪${_totalIncomes.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'סך הוצאות',
                '₪${_totalExpenses.toStringAsFixed(2)}',
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'יתרה',
          '₪${_balance.toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          _balance >= 0 ? Colors.green : Colors.red,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          amount,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMonthlyAnalysis() {
    final monthlyBalance = _monthlyIncomes - _monthlyExpenses;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ניתוח החודש הנוכחי',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisItem(
                    'הכנסות החודש',
                    '₪${_monthlyIncomes.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalysisItem(
                    'הוצאות החודש',
                    '₪${_monthlyExpenses.toStringAsFixed(2)}',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: monthlyBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: monthlyBalance >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'יתרה חודשית:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: monthlyBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    '₪${monthlyBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: monthlyBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildAnalysisItem(
              'ממוצע הוצאות יומי',
              '₪${_dailyAverageExpenses.toStringAsFixed(2)}',
              Icons.timeline,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesCategoryChart() {
    if (_expensesByCategory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'הוצאות לפי קטגוריה',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.pie_chart, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('אין נתוני הוצאות להצגה', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final sortedCategories = _expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'הוצאות לפי קטגוריה',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedCategories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final percentage = (_totalExpenses > 0) ? (entry.value / _totalExpenses) * 100 : 0;
                
                return _buildCategoryItem(
                  entry.key,
                  entry.value,
                  percentage.toDouble(),
                  _getCategoryColor(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomesTypeChart() {
    if (_incomesByType.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'הכנסות לפי סוג',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('אין נתוני הכנסות להצגה', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final sortedTypes = _incomesByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'הכנסות לפי סוג',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTypes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = sortedTypes[index];
                final percentage = (_totalIncomes > 0) ? (entry.value / _totalIncomes) * 100 : 0;
                
                return _buildCategoryItem(
                  _getIncomeTypeHebrew(entry.key),
                  entry.value,
                  percentage.toDouble(),
                  _getIncomeColor(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '₪${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalTransactions = _incomes.length + _expenses.length;
    final averageIncome = _incomes.isNotEmpty ? _totalIncomes / _incomes.length : 0;
    final averageExpense = _expenses.isNotEmpty ? _totalExpenses / _expenses.length : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'סטטיסטיקות מהירות',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    'סך עסקאות',
                    totalTransactions.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatItem(
                    'ממוצע הכנסה',
                    '₪${averageIncome.toStringAsFixed(0)}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickStatItem(
              'ממוצע הוצאה',
              '₪${averageExpense.toStringAsFixed(0)}',
              Icons.trending_down,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.grey,
    ];
    return colors[index % colors.length];
  }

  Color _getIncomeColor(int index) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.teal,
      Colors.cyan,
      Colors.lightGreen,
      Colors.lime,
      Colors.indigo,
      Colors.purple,
      Colors.orange,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  String _getIncomeTypeHebrew(String type) {
    final types = {
      'salary': 'משכורת',
      'freelance': 'עבודה עצמאית',
      'programming': 'עבודת תכנות',
      'nightWork': 'עבודת לילה',
      'additionalWork': 'עבודה נוספת',
      'investment': 'השקעות',
      'rental': 'שכירות',
      'business': 'עסק',
      'gift': 'מתנה',
      'other': 'אחר',
    };
    return types[type] ?? type;
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