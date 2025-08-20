// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'customer_report_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Reports'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.teal[100],
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Profit & Loss'),
            Tab(icon: Icon(Icons.people), text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [PLReportView(), CustomerReportView()],
      ),
    );
  }
}

// --- P&L Report Widget ---
enum ReportDateRange { last7Days, last30Days, thisMonth }

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

  @override
  void initState() {
    super.initState();
    _fetchReportForRange(_selectedRange);
  }

  Future<void> _fetchReportForRange(ReportDateRange range) async {
    setState(() {
      _isLoading = true;
      _selectedRange = range;
    });
    DateTime endDate = DateTime.now();
    DateTime startDate;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<ReportDateRange>(
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
            ],
            selected: {_selectedRange},
            onSelectionChanged: (newSelection) =>
                _fetchReportForRange(newSelection.first),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reportData == null
              ? const Center(child: Text('No report data available.'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const Text(
                      "Profit & Loss Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Showing report from ${DateFormat('MMM dd').format(DateTime.parse(_reportData!['startDate']))} to ${DateFormat('MMM dd').format(DateTime.parse(_reportData!['endDate']))}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildReportCard(
                      'Total Revenue',
                      'LKR ${_reportData!['totalRevenue'].toStringAsFixed(2)}',
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildReportCard(
                      'Cost of Goods',
                      'LKR ${_reportData!['totalCostOfGoods'].toStringAsFixed(2)}',
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildReportCard(
                      'Gross Profit',
                      'LKR ${_reportData!['grossProfit'].toStringAsFixed(2)}',
                      Colors.blue,
                      isLarge: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String value,
    Color color, {
    bool isLarge = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isLarge ? 18 : 16,
                color: Colors.grey[700],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 22 : 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
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
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final customers = await _apiService.getCustomersByBusiness(
        businesses[0]['id'],
        token,
      );
      setState(() {
        _customers = customers;
        _isLoading = false;
      });
    } catch (e) {
      /* Handle error */
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchCustomers,
            child: _customers.isEmpty
                ? const Center(
                    child: Text('No customers to generate reports for.'),
                  )
                : ListView.builder(
                    itemCount: _customers.length,
                    itemBuilder: (ctx, index) {
                      final customer = _customers[index];
                      return ListTile(
                        title: Text(customer['name']),
                        subtitle: Text(
                          customer['phone_number'] ?? 'No phone number',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerReportScreen(customer: customer),
                            ),
                          );
                        },
                      );
                    },
                  ),
          );
  }
}
