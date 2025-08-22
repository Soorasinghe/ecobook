// lib/screens/order_report_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

enum OrderReportDateRange { last7Days, last30Days, thisMonth, custom }

class OrderReportView extends StatefulWidget {
  const OrderReportView({super.key});
  @override
  State<OrderReportView> createState() => _OrderReportViewState();
}

class _OrderReportViewState extends State<OrderReportView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];
  Map<String, dynamic>? _summary; // State for the summary data
  OrderReportDateRange _selectedRange = OrderReportDateRange.last30Days;
  String _sortBy = 'date';
  String _sortOrder = 'DESC';

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
    _fetchReportForRange(OrderReportDateRange.custom);
  }

  Future<void> _fetchReportForRange(OrderReportDateRange range) async {
    setState(() {
      _isLoading = true;
      _selectedRange = range;
    });
    DateTime startDate;
    DateTime endDate = DateTime.now();
    switch (range) {
      case OrderReportDateRange.last7Days:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case OrderReportDateRange.last30Days:
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      case OrderReportDateRange.thisMonth:
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case OrderReportDateRange.custom:
        if (_customStartDate == null || _customEndDate == null) {
          setState(() => _isLoading = false);
          return;
        }
        startDate = _customStartDate!;
        endDate = _customEndDate!;
        break;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        // Handle not logged in
        return;
      }
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        setState(() {
          _isLoading = false;
          _orders = [];
          _summary = null;
        });
        return;
      }
      final businessId = businesses[0]['id'];
      final data = await _apiService.getOrderReport(
        businessId,
        DateFormat('yyyy-MM-dd').format(startDate),
        DateFormat('yyyy-MM-dd').format(endDate),
        _sortBy,
        _sortOrder,
        token,
      );
      setState(() {
        _orders = List<dynamic>.from(data['orders'] ?? []);
        _summary = data['summary'];
      });
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

  // ===================================================================
  // ▼▼▼ NEW HELPER WIDGET FOR SUMMARY CARDS ▼▼▼
  // ===================================================================
  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Filter Controls ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<OrderReportDateRange>(
            // ... (this part remains the same)
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: Colors.deepPurple.shade50,
              selectedForegroundColor: Colors.deepPurple,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            segments: const [
              ButtonSegment(
                value: OrderReportDateRange.last7Days,
                label: Text('7 Days'),
              ),
              ButtonSegment(
                value: OrderReportDateRange.last30Days,
                label: Text('30 Days'),
              ),
              ButtonSegment(
                value: OrderReportDateRange.thisMonth,
                label: Text('This Month'),
              ),
              ButtonSegment(
                value: OrderReportDateRange.custom,
                icon: Icon(Icons.calendar_today),
                label: Text('Custom'),
              ),
            ],
            selected: {_selectedRange},
            onSelectionChanged: (Set<OrderReportDateRange> selected) {
              final range = selected.first;
              if (range == OrderReportDateRange.custom) {
                _selectCustomDateRange();
              } else {
                _fetchReportForRange(range);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: '$_sortBy-$_sortOrder',
                items: const [
                  DropdownMenuItem(
                    value: 'date-DESC',
                    child: Text('Newest First'),
                  ),
                  DropdownMenuItem(
                    value: 'date-ASC',
                    child: Text('Oldest First'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) {
                    final parts = value.split('-');
                    setState(() {
                      _sortBy = parts[0];
                      _sortOrder = parts[1];
                    });
                    _fetchReportForRange(_selectedRange);
                  }
                },
              ),
            ],
          ),
        ),

        // ===================================================================
        // ▼▼▼ NEW SUMMARY CARDS SECTION ▼▼▼
        // ===================================================================
        if (_summary != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildSummaryCard(
                  'Total Orders',
                  _summary!['total_orders']?.toString() ?? '0',
                ),
                _buildSummaryCard(
                  'Completed',
                  _summary!['completed_orders']?.toString() ?? '0',
                ),
                _buildSummaryCard(
                  'Pending',
                  _summary!['pending_orders']?.toString() ?? '0',
                ),
                _buildSummaryCard(
                  'Shipped',
                  _summary!['shipped_orders']?.toString() ?? '0',
                ),
              ],
            ),
          ),

        const Divider(height: 1),

        // --- Order List ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? const Center(child: Text('No orders found for this period'))
              : ListView.builder(
                  // ... (this part remains the same)
                  padding: const EdgeInsets.all(8),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final totalAmount =
                        double.tryParse(order['total_amount'] ?? '0.0') ?? 0.0;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          'Order #${order['id']} - ${order['customer_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(order['order_date']))}\nTotal: \$${totalAmount.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          (order['status'] ?? '').toUpperCase(),
                          style: TextStyle(
                            color: order['status'] == 'Delivered'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
