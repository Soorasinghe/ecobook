// lib/screens/order_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OrderReportScreen extends StatefulWidget {
  final String businessId;
  const OrderReportScreen({super.key, required this.businessId});

  @override
  State<OrderReportScreen> createState() => _OrderReportScreenState();
}

class _OrderReportScreenState extends State<OrderReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  Map<String, dynamic>? _summary; // <-- State for the summary data
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _sortBy = 'date';
  String _sortOrder = 'DESC';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _apiService.getOrderReport(
        widget.businessId,
        DateFormat('yyyy-MM-dd').format(_startDate),
        DateFormat('yyyy-MM-dd').format(_endDate),
        _sortBy,
        _sortOrder,
        token,
      );
      if (mounted) {
        setState(() {
          _orders = data['orders'];
          _summary = data['summary'];
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    // ... (This function remains the same)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Report'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter and Sort Controls
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(/* ... (This Row is the same) */),
                ),

                // V-- NEW SUMMARY CARDS SECTION --V
                if (_summary != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      childAspectRatio: 2.5,
                      children: [
                        _buildSummaryCard(
                          'Total Orders',
                          _summary!['total_orders'] ?? '0',
                        ),
                        _buildSummaryCard(
                          'Completed',
                          _summary!['completed_orders'] ?? '0',
                        ),
                        _buildSummaryCard(
                          'Pending',
                          _summary!['pending_orders'] ?? '0',
                        ),
                        _buildSummaryCard(
                          'Shipped',
                          _summary!['shipped_orders'] ?? '0',
                        ),
                      ],
                    ),
                  ),

                const Divider(),

                // Data Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Customer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                // Data Table List
                Expanded(
                  child: _orders.isEmpty
                      ? const Center(
                          child: Text('No orders found for this period'),
                        )
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      DateFormat('MMM dd').format(
                                        DateTime.parse(order['order_date']),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(order['customer_name']),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(order['status']),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      order['total_amount'],
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Helper for summary cards
  Widget _buildSummaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
