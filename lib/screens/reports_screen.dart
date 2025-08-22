// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'customer_report_screen.dart';
import 'order_report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130), // Increased height for tabs
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleSpacing: 0,
            toolbarHeight: 86,
            title: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                'Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true, // ▼▼▼ THIS IS THE FIX ▼▼▼
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart),
                      SizedBox(width: 8),
                      Text('Profit & Loss'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 8),
                      Text('Customers'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long),
                      SizedBox(width: 8),
                      Text('Orders'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const PLReportView(),
          const CustomerReportView(),
          const OrderReportView(),
        ],
      ),
    );
  }
}

// --- P&L Report Widget ---
enum ReportDateRange { last7Days, last30Days, thisMonth, custom }

class PLReportView extends StatefulWidget {
  const PLReportView({super.key});
  @override
  State<PLReportView> createState() => _PLReportViewState();
}

class _PLReportViewState extends State<PLReportView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  ReportDateRange _selectedRange = ReportDateRange.last30Days;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _fetchReportForRange(_selectedRange);
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);

    final startDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? now,
      firstDate: firstDate,
      lastDate: now,
    );

    if (startDate == null) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? startDate,
      firstDate: startDate,
      lastDate: now,
    );

    if (endDate == null) return;

    setState(() {
      _customStartDate = startDate;
      _customEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
    });
    _fetchReportForRange(ReportDateRange.custom);
  }

  Future<void> _fetchReportForRange(ReportDateRange range) async {
    setState(() {
      _isLoading = true;
      _selectedRange = range;
    });

    DateTime startDate;
    DateTime endDate = DateTime.now();

    switch (range) {
      case ReportDateRange.last7Days:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case ReportDateRange.last30Days:
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      case ReportDateRange.thisMonth:
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case ReportDateRange.custom:
        if (_customStartDate == null || _customEndDate == null) {
          setState(() => _isLoading = false);
          return;
        }
        startDate = _customStartDate!;
        endDate = _customEndDate!;
        break;
    }

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        setState(() {
          _isLoading = false;
          _reportData = null;
        });
        return;
      }
      final businessId = businesses[0]['id'];
      final data = await _apiService.getProfitLossReport(
        businessId,
        DateFormat('yyyy-MM-dd').format(startDate),
        DateFormat('yyyy-MM-dd').format(endDate),
        token,
      );
      setState(() => _reportData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getFormattedDateRange() {
    if (_reportData == null) return '';
    final start = DateFormat(
      'MMM dd, yyyy',
    ).format(DateTime.parse(_reportData!['startDate']));
    final end = DateFormat(
      'MMM dd, yyyy',
    ).format(DateTime.parse(_reportData!['endDate']));
    return '$start to $end';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ReportDateRange>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.deepPurple.shade50,
                selectedForegroundColor: Colors.deepPurple,
                side: BorderSide(color: Colors.grey.shade300),
              ),
              segments: const [
                ButtonSegment(
                  value: ReportDateRange.last7Days,
                  label: Text('7 Days'),
                ),
                ButtonSegment(
                  value: ReportDateRange.last30Days,
                  label: Text('30 Days'),
                ),
                ButtonSegment(
                  value: ReportDateRange.thisMonth,
                  label: Text('This Month'),
                ),
                ButtonSegment(
                  value: ReportDateRange.custom,
                  icon: Icon(Icons.calendar_today),
                  label: Text('Custom'),
                ),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (newSelection) {
                final selection = newSelection.first;
                if (selection == ReportDateRange.custom) {
                  _selectCustomDateRange();
                } else {
                  _fetchReportForRange(selection);
                }
              },
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reportData == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMetricCard(
                        title: 'Gross Profit',
                        value:
                            'LKR ${_reportData!['grossProfit'].toStringAsFixed(2)}',
                        dateRange: _getFormattedDateRange(),
                        icon: Icons.monetization_on,
                        color: Colors.deepPurple,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildMetricTile(
                              icon: Icons.trending_up,
                              title: 'Total Revenue',
                              value:
                                  'LKR ${_reportData!['totalRevenue'].toStringAsFixed(2)}',
                              color: Colors.green,
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _buildMetricTile(
                              icon: Icons.trending_down,
                              title: 'Cost of Goods',
                              value:
                                  'LKR ${_reportData!['totalCostOfGoods'].toStringAsFixed(2)}',
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String dateRange,
    required IconData icon,
    required Color color,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 28),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateRange,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Report Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a date range to view your report.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// --- Customer Report Selection Widget ---
class CustomerReportView extends StatefulWidget {
  const CustomerReportView({super.key});
  @override
  State<CustomerReportView> createState() => _CustomerReportViewState();
}

class _CustomerReportViewState extends State<CustomerReportView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final customers = await _apiService.getCustomersByBusiness(
        businesses[0]['id'],
        token,
      );
      if (mounted) setState(() => _customers = customers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchCustomers,
            child: _customers.isEmpty
                ? _buildEmptyCustomerState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _customers.length,
                    itemBuilder: (ctx, index) {
                      final customer = _customers[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            customer['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            customer['phone_number'] ?? 'No phone number',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerReportScreen(customer: customer),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          );
  }

  Widget _buildEmptyCustomerState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Customers Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add customers to see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
