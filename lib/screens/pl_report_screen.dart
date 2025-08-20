// lib/screens/pl_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PLReportScreen extends StatefulWidget {
  final String businessId;
  const PLReportScreen({super.key, required this.businessId});

  @override
  State<PLReportScreen> createState() => _PLReportScreenState();
}

class _PLReportScreenState extends State<PLReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    // Fetch report for the last 30 days by default
    _fetchReport(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );
  }

  Future<void> _fetchReport(DateTime start, DateTime end) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      // Format dates to YYYY-MM-DD
      final startDate = DateFormat('yyyy-MM-dd').format(start);
      final endDate = DateFormat('yyyy-MM-dd').format(end);

      final data = await _apiService.getProfitLossReport(
        widget.businessId,
        startDate,
        endDate,
        token,
      );
      setState(() {
        _reportData = data;
      });
    } catch (e) {
      // Handle error
    } finally {
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
        title: const Text('Profit & Loss Report'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportData == null
          ? const Center(child: Text('Could not load report.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // You can add Date Pickers here later for custom ranges
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
