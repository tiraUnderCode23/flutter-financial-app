import 'package:flutter/material.dart';
import '../services/advanced_database_helper.dart';
import 'unified_settings_management_screen.dart';
import 'add_income_screen.dart';
import 'add_expense_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();

  bool _isLoading = false;
  bool _isConnectedToGitHub = false;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      // טעינת נתונים אמיתיים מהמסד
      final incomes = await _databaseHelper.getAdvancedIncomes();
      final expenses = await _databaseHelper.getAdvancedExpenses();
      
      final totalIncomes = incomes.fold(0.0, (sum, income) => sum + income.amount);
      final totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      _totalIncome = totalIncomes;
      _totalExpenses = totalExpenses;
      _balance = _totalIncome - _totalExpenses;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('אפליקציה פיננסית מתקדמת'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // מחוון סטטוס GitHub
          IconButton(
            icon: Icon(
              _isConnectedToGitHub ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnectedToGitHub
                  ? Colors.green.shade300
                  : Colors.red.shade300,
            ),
            onPressed: () => _showGitHubInfo(),
            tooltip: _isConnectedToGitHub
                ? 'מחובר ל-GitHub'
                : 'לא מחובר ל-GitHub',
          ),
          // הגדרות
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UnifiedSettingsManagementScreen(),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'לוח בקרה'),
            Tab(icon: Icon(Icons.today), text: 'היום'),
            Tab(icon: Icon(Icons.trending_up), text: 'סטטיסטיקות'),
            Tab(icon: Icon(Icons.sync), text: 'סנכרון'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildTodayTab(),
                _buildStatisticsTab(),
                _buildSyncTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionMenu,
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('טוען את האפליקציה...'),
          SizedBox(height: 8),
          Text(
            'אנא המתן בזמן שאנו מכינים את הנתונים',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildFinancialCards(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'שלום וברוך הבא!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'ניהול פיננסי חכם עם סנכרון GitHub',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // מחוון סטטוס
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnectedToGitHub
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isConnectedToGitHub ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isConnectedToGitHub
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: _isConnectedToGitHub ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnectedToGitHub ? 'מחובר' : 'לא מחובר',
                        style: TextStyle(
                          color: _isConnectedToGitHub
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCards() {
    return Row(
      children: [
        Expanded(
          child: _buildFinancialCard(
            'יתרה נוכחית',
            '₪${_balance.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            _balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFinancialCard(
            'סך הכנסות',
            '₪${_totalIncome.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFinancialCard(
            'סך הוצאות',
            '₪${_totalExpenses.toStringAsFixed(2)}',
            Icons.trending_down,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'פעולות מהירות',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'הוסף הוצאה',
                    Icons.remove_circle_outline,
                    Colors.red,
                    () => _showAddExpenseDialog(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'הוסף הכנסה',
                    Icons.add_circle_outline,
                    Colors.green,
                    () => _showAddIncomeDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'ניהול חובות',
                    Icons.account_balance,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const UnifiedSettingsManagementScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    'סנכרון GitHub',
                    Icons.sync,
                    Colors.blue,
                    () => _performSync(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(title, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  Widget _buildRecentTransactions() {
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
                  'עסקאות אחרונות',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('הצג הכל'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(Icons.inbox, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'אין עסקאות אחרונות',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'התחל בהוספת הכנסה או הוצאה',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const TransactionsScreen(),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const StatisticsScreen(),
        );
      },
    );
  }

  Widget _buildSyncTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isConnectedToGitHub ? Icons.cloud_done : Icons.cloud_off,
              size: 64,
              color: _isConnectedToGitHub ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isConnectedToGitHub ? 'מחובר ל-GitHub' : 'לא מחובר ל-GitHub',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnectedToGitHub
                  ? 'הנתונים שלך מסונכרנים בענן'
                  : 'התחבר כדי לסנכרן את הנתונים',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isConnectedToGitHub ? _performSync : _connectToGitHub,
              icon: Icon(_isConnectedToGitHub ? Icons.sync : Icons.link),
              label: Text(
                _isConnectedToGitHub ? 'סנכרן עכשיו' : 'התחבר ל-GitHub',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionMenu() {
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
              'בחר פעולה',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
              ),
              title: const Text('הוסף הוצאה'),
              onTap: () {
                Navigator.pop(context);
                _showAddExpenseDialog();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: Colors.green,
              ),
              title: const Text('הוסף הכנסה'),
              onTap: () {
                Navigator.pop(context);
                _showAddIncomeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.blue),
              title: const Text('הוסף שיק'),
              onTap: () {
                Navigator.pop(context);
                _showAddCheckDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.purple),
              title: const Text('סנכרון עם GitHub'),
              onTap: () {
                Navigator.pop(context);
                _performSync();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // רענן את הנתונים
      }
    });
  }

  void _showAddIncomeDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddIncomeScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // רענן את הנתונים
      }
    });
  }

  void _showAddCheckDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _performSync() {
    if (!_isConnectedToGitHub) {
      _showSnackBar('לא מחובר ל-GitHub');
      return;
    }

    _showSnackBar('מתחיל סנכרון...');

    // סימולציה של סנכרון
    Future.delayed(const Duration(seconds: 2), () {
      _showSnackBar('הסנכרון הושלם בהצלחה ✅');
    });
  }

  void _connectToGitHub() {
    setState(() {
      _isConnectedToGitHub = true;
    });
    _showSnackBar('התחברת ל-GitHub בהצלחה!');
  }

  void _showGitHubInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סטטוס GitHub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnectedToGitHub ? Icons.cloud_done : Icons.cloud_off,
              size: 48,
              color: _isConnectedToGitHub ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _isConnectedToGitHub
                  ? 'מחובר ל-GitHub\nהנתונים מסונכרנים בענן'
                  : 'לא מחובר ל-GitHub\nהנתונים שמורים רק מקומית',
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
