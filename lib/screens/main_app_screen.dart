import 'package:flutter/material.dart';
import '../services/advanced_database_helper.dart';
import '../models/debt_models.dart';
import '../models/income_models.dart';
import '../models/expense_models.dart';
import 'unified_data_entry_screen.dart';
import 'unified_analytics_screen.dart';
import 'unified_settings_management_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen>
    with TickerProviderStateMixin {
  final AdvancedDatabaseHelper _databaseHelper = AdvancedDatabaseHelper();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dashboard data
  double _totalBalance = 0.0;
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  double _pendingChecks = 0.0;
  double _totalLoans = 0.0;
  
  List<AdvancedIncome> _recentIncomes = [];
  List<AdvancedExpense> _recentExpenses = [];
  List<Check> _upcomingChecks = [];
  List<Loan> _activeLoans = [];

  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _buildMainContent(),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const UnifiedDataEntryScreen();
      case 2:
        return const UnifiedAnalyticsScreen();
      case 3:
        return const UnifiedSettingsManagementScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفحة الرئيسية'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    _buildQuickStats(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildRecentActivity(),
                    const SizedBox(height: 20),
                    _buildUpcomingReminders(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'صباح الخير';
    } else if (hour < 17) {
      greeting = 'مساء الخير';
    } else {
      greeting = 'مساء الخير';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مرحباً بك في تطبيق إدارة الأموال',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balanceColor = _totalBalance >= 0 ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'الرصيد الإجمالي',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _totalBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                color: balanceColor,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '₪${_formatAmount(_totalBalance)}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'الدخل الشهري',
                  _monthlyIncome,
                  Icons.arrow_upward,
                  Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildBalanceItem(
                  'المصروفات الشهرية',
                  _monthlyExpenses,
                  Icons.arrow_downward,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '₪${_formatAmount(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'الشيكات المعلقة',
            _pendingChecks,
            Icons.receipt,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'إجمالي القروض',
            _totalLoans,
            Icons.account_balance,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'إضافة دخل',
                Icons.add_circle,
                Colors.green,
                () => _navigateToDataEntry(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                'إضافة مصروف',
                Icons.remove_circle,
                Colors.red,
                () => _navigateToDataEntry(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'عرض التقارير',
                Icons.analytics,
                Colors.blue,
                () => setState(() => _selectedIndex = 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionCard(
                'الإعدادات',
                Icons.settings,
                Colors.grey,
                () => setState(() => _selectedIndex = 3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentTransactions = [
      ..._recentIncomes.map((income) => {
            'title': income.title,
            'amount': income.amount,
            'type': 'دخل',
            'date': income.date,
            'icon': Icons.arrow_upward,
            'color': Colors.green,
          }),
      ..._recentExpenses.map((expense) => {
            'title': expense.title,
            'amount': expense.amount,
            'type': 'مصروف',
            'date': expense.date,
            'icon': Icons.arrow_downward,
            'color': Colors.red,
          }),
    ];

    recentTransactions.sort((a, b) => 
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'النشاط الأخير',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: recentTransactions.take(5).map((transaction) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (transaction['color'] as Color).withOpacity(0.1),
                  child: Icon(
                    transaction['icon'] as IconData,
                    color: transaction['color'] as Color,
                    size: 20,
                  ),
                ),
                title: Text(
                  transaction['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${transaction['type']} - ${_formatDate(transaction['date'] as DateTime)}',
                ),
                trailing: Text(
                  '₪${_formatAmount(transaction['amount'] as double)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction['color'] as Color,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تذكيرات قادمة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ..._upcomingChecks.take(3).map((check) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.receipt, color: Colors.orange),
                    ),
                    title: Text('شيك #${check.checkNumber}'),
                    subtitle: Text('استحقاق: ${_formatDate(check.dueDate)}'),
                    trailing: Text(
                      '₪${_formatAmount(check.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  )),
              ..._activeLoans.take(2).map((loan) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      child: const Icon(Icons.account_balance, color: Colors.purple),
                    ),
                    title: Text('قرض - ${loan.lenderName}'),
                    subtitle: const Text('قسط شهري'),
                    trailing: Text(
                      '₪${_formatAmount(loan.monthlyPayment)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  )),
              if (_upcomingChecks.isEmpty && _activeLoans.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'لا توجد تذكيرات قادمة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        children: [
          _buildBottomNavItem(Icons.home, 'الرئيسية', 0),
          _buildBottomNavItem(Icons.add_box, 'إدخال', 1),
          const Spacer(),
          _buildBottomNavItem(Icons.analytics, 'تحليلات', 2),
          _buildBottomNavItem(Icons.settings, 'إعدادات', 3),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.indigo : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.indigo : Colors.grey,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _navigateToDataEntry(0),
      backgroundColor: Colors.indigo,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      // Load recent data
      _recentIncomes = await _databaseHelper.getAdvancedIncomes();
      _recentExpenses = await _databaseHelper.getAdvancedExpenses();
      _upcomingChecks = await _databaseHelper.getChecks();
      _activeLoans = await _databaseHelper.getLoans();

      // Filter for current month
      final monthlyIncomes = _recentIncomes.where((income) =>
          income.date.isAfter(monthStart) && income.date.isBefore(monthEnd.add(Duration(days: 1)))
      ).toList();
      
      final monthlyExpensesData = _recentExpenses.where((expense) =>
          expense.date.isAfter(monthStart) && expense.date.isBefore(monthEnd.add(Duration(days: 1)))
      ).toList();

      // Calculate totals
      _monthlyIncome = monthlyIncomes.fold(0.0, (sum, income) => sum + income.amount);
      _monthlyExpenses = monthlyExpensesData.fold(0.0, (sum, expense) => sum + expense.amount);
      _totalBalance = _monthlyIncome - _monthlyExpenses;
      
      _pendingChecks = _upcomingChecks
          .where((check) => !check.isPaid)
          .fold(0.0, (sum, check) => sum + check.amount);
      
      _totalLoans = _activeLoans.fold(0.0, (sum, loan) => sum + loan.remainingAmount);

      // Sort by date
      _recentIncomes.sort((a, b) => b.date.compareTo(a.date));
      _recentExpenses.sort((a, b) => b.date.compareTo(a.date));
      _upcomingChecks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    } catch (e) {
      print('Error loading dashboard data: $e');
      _showSnackBar('خطأ في تحميل البيانات', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDataEntry(int tabIndex) {
    setState(() => _selectedIndex = 1);
    // You can add logic here to navigate to specific tab in data entry screen
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإشعارات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_upcomingChecks.isNotEmpty)
              Text('لديك ${_upcomingChecks.length} شيك مستحق قريباً'),
            if (_activeLoans.isNotEmpty)
              Text('لديك ${_activeLoans.length} قرض نشط'),
            if (_upcomingChecks.isEmpty && _activeLoans.isEmpty)
              const Text('لا توجد إشعارات جديدة'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
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

  String _formatAmount(double amount) {
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}