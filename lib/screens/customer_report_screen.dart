// lib/screens/customer_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CustomerReportScreen extends StatefulWidget {
  final Map<String, dynamic> customer;
  const CustomerReportScreen({super.key, required this.customer});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _apiService.getCustomerReport(
        widget.customer['id'],
        token,
      );
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(86),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleSpacing: 0,
            toolbarHeight: 86,
            title: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                widget.customer['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
          ? const Center(child: Text('Could not load report.'))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Purchase Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Spent',
                        'LKR ${_reportData!['summary']['totalspent'] ?? '0.00'}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Orders',
                        '${_reportData!['summary']['ordercount'] ?? '0'}',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  'Order History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                for (var order in (_reportData!['orders'] as List))
                  Card(
                    child: ListTile(
                      title: Text(
                        'Order on ${DateFormat('MMM dd, yyyy').format(DateTime.parse(order['order_date']))}',
                      ),
                      subtitle: Text(order['status']),
                      trailing: Text(
                        'LKR ${order['total_amount']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
