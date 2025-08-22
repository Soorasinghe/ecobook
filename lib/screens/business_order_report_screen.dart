import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'order_details_screen.dart';

class BusinessOrderReportScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessOrderReportScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BusinessOrderReportScreen> createState() =>
      _BusinessOrderReportScreenState();
}

class _BusinessOrderReportScreenState extends State<BusinessOrderReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _apiService.getOrdersByBusiness(
        widget.businessId,
        token,
      );

      if (!mounted) return;
      setState(() {
        _orders = data['orders'];
        _summary = data['summary'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load report: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders for ${widget.businessName}'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReport,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSummarySection()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final order = _orders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(
                            order['customer_name'] ?? 'Unknown Customer',
                          ),
                          subtitle: Text(
                            'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(order['order_date']))}',
                          ),
                          trailing: Text(
                            'LKR ${order['total_amount']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) =>
                                    OrderDetailsScreen(orderId: order['id']),
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: _orders.length),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard(
            'Total Orders',
            _summary?['totalOrders']?.toString() ?? '0',
            Icons.receipt_long,
            Colors.blue,
          ),
          _buildSummaryCard(
            'Total Revenue',
            'LKR ${_summary?['totalRevenue']?.toString() ?? '0.00'}',
            Icons.attach_money,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
