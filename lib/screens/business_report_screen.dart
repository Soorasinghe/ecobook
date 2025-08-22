// lib/screens/business_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'product_list_screen.dart';
import 'customer_list_screen.dart';
import 'order_list_screen.dart';
import 'business_order_report_screen.dart';
import 'business_customer_report_screen.dart';

class BusinessReportScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessReportScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BusinessReportScreen> createState() => _BusinessReportScreenState();
}

class _BusinessReportScreenState extends State<BusinessReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      // We use the 'monthly' period for a general summary
      final summary = await _apiService.getDashboardSummary(
        widget.businessId,
        'monthly',
        token,
      );
      if (mounted) {
        setState(() {
          _summaryData = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSummary,
              child: ListView(
                children: [
                  // Summary Cards Section
                  if (_summaryData != null)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.0,
                      children: [
                        _buildSummaryCard(
                          'Sales (Month)',
                          'LKR ${_summaryData!['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                          Icons.trending_up,
                          Colors.green,
                        ),
                        _buildSummaryCard(
                          'Profit (Month)',
                          'LKR ${_summaryData!['totalProfit']?.toStringAsFixed(2) ?? '0.00'}',
                          Icons.attach_money,
                          Colors.blue,
                        ),
                        _buildSummaryCard(
                          'Orders (Month)',
                          _summaryData!['orderCount']?.toString() ?? '0',
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                        _buildSummaryCard(
                          'New Customers',
                          _summaryData!['newCustomerCount']?.toString() ?? '0',
                          Icons.person_add,
                          Colors.purple,
                        ),
                      ],
                    ),

                  const Divider(),

                  // Navigation Links
                  _buildNavTile(
                    context: context,
                    icon: Icons.inventory_2,
                    title: 'Manage Products',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ProductListScreen(
                            businessId: widget.businessId,
                            businessName: widget.businessName,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavTile(
                    context: context,
                    icon: Icons.receipt_long,
                    title: 'View Orders',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => BusinessOrderReportScreen(
                            businessId: widget.businessId,
                            businessName: widget.businessName,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavTile(
                    context: context,
                    icon: Icons.people,
                    title: 'View Customers',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => BusinessCustomerReportScreen(
                            businessId: widget.businessId,
                            businessName: widget.businessName,
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    // This is the same helper widget from your main dashboard
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal, size: 30),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
