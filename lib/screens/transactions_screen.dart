import 'package:flutter/material.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';
import '../services/advanced_database_helper.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();

  List<AdvancedIncome> _incomes = [];
  List<AdvancedExpense> _expenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final incomes = await _databaseHelper.getAdvancedIncomes();
      final expenses = await _databaseHelper.getAdvancedExpenses();

      setState(() {
        _incomes = incomes;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('שגיאה בטעינת הנתונים: $e', Colors.red);
    }
  }

  List<AdvancedIncome> get _todayIncomes {
    final today = DateTime.now();
    return _incomes.where((income) {
      return income.date.year == today.year &&
             income.date.month == today.month &&
             income.date.day == today.day;
    }).toList();
  }

  List<AdvancedExpense> get _todayExpenses {
    final today = DateTime.now();
    return _expenses.where((expense) {
      return expense.date.year == today.year &&
             expense.date.month == today.month &&
             expense.date.day == today.day;
    }).toList();
  }

  double get _totalIncomes => _incomes.fold(0, (sum, income) => sum + income.amount);
  double get _totalExpenses => _expenses.fold(0, (sum, expense) => sum + expense.amount);
  double get _balance => _totalIncomes - _totalExpenses;

  double get _todayIncomesTotal => _todayIncomes.fold(0, (sum, income) => sum + income.amount);
  double get _todayExpensesTotal => _todayExpenses.fold(0, (sum, expense) => sum + expense.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עסקאות פיננסיות'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'היום'),
            Tab(icon: Icon(Icons.trending_up), text: 'הכנסות'),
            Tab(icon: Icon(Icons.trending_down), text: 'הוצאות'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildIncomesTab(),
                _buildExpensesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionMenu,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodaySummaryCards(),
            const SizedBox(height: 24),
            _buildTodayIncomes(),
            const SizedBox(height: 24),
            _buildTodayExpenses(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'סיכום היום',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'הכנסות היום',
                '₪${_todayIncomesTotal.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.green,
                '${_todayIncomes.length} עסקאות',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'הוצאות היום',
                '₪${_todayExpensesTotal.toStringAsFixed(2)}',
                Icons.trending_down,
                Colors.red,
                '${_todayExpenses.length} עסקאות',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'יתרה כללית',
          '₪${_balance.toStringAsFixed(2)}',
          Icons.account_balance_wallet,
          _balance >= 0 ? Colors.green : Colors.red,
          'מכלל התקופה',
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color,
    String subtitle, {
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
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTodayIncomes() {
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
                  'הכנסות היום (${_todayIncomes.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addIncome(),
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_todayIncomes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.trending_up, color: Colors.grey, size: 48),
                      SizedBox(height: 8),
                      Text('אין הכנסות היום', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todayIncomes.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final income = _todayIncomes[index];
                  return _buildIncomeListTile(income);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayExpenses() {
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
                  'הוצאות היום (${_todayExpenses.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addExpense(),
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_todayExpenses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.trending_down, color: Colors.grey, size: 48),
                      SizedBox(height: 8),
                      Text('אין הוצאות היום', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todayExpenses.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final expense = _todayExpenses[index];
                  return _buildExpenseListTile(expense);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'סך הכנסות: ₪${_totalIncomes.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                Text('${_incomes.length} הכנסות'),
              ],
            ),
          ),
          Expanded(
            child: _incomes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('אין הכנסות', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _incomes.length,
                    itemBuilder: (context, index) {
                      final income = _incomes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildIncomeListTile(income),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'סך הוצאות: ₪${_totalExpenses.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text('${_expenses.length} הוצאות'),
              ],
            ),
          ),
          Expanded(
            child: _expenses.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('אין הוצאות', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildExpenseListTile(expense),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeListTile(AdvancedIncome income) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(Icons.trending_up, color: Colors.green.shade700),
      ),
      title: Text(income.title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(income.type.hebrewName),
          Text(
            '${income.date.day}/${income.date.month}/${income.date.year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '₪${income.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 16,
            ),
          ),
          if (income.isReceived)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'התקבל',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: () => _editIncome(income),
    );
  }

  Widget _buildExpenseListTile(AdvancedExpense expense) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: Icon(Icons.trending_down, color: Colors.red.shade700),
      ),
      title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(expense.category.hebrewName),
          Text(
            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Text(
        '₪${expense.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
          fontSize: 16,
        ),
      ),
      onTap: () => _editExpense(expense),
    );
  }

  void _showAddTransactionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'הוסף עסקה חדשה',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.green),
              title: const Text('הוסף הכנסה'),
              onTap: () {
                Navigator.pop(context);
                _addIncome();
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_down, color: Colors.red),
              title: const Text('הוסף הוצאה'),
              onTap: () {
                Navigator.pop(context);
                _addExpense();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addIncome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddIncomeScreen(),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editIncome(AdvancedIncome income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddIncomeScreen(
          income: income,
          isEditing: true,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editExpense(AdvancedExpense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          expense: expense,
          isEditing: true,
        ),
      ),
    );
    if (result == true) {
      _loadData();
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