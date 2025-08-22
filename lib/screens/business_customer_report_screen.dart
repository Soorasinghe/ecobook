import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'customer_details_screen.dart';

class BusinessCustomerReportScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessCustomerReportScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BusinessCustomerReportScreen> createState() =>
      _BusinessCustomerReportScreenState();
}

class _BusinessCustomerReportScreenState
    extends State<BusinessCustomerReportScreen> {
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
      // The existing endpoint works perfectly for this
      final data = await _apiService.getCustomersByBusiness(
        widget.businessId,
        token,
      );

      if (!mounted) return;
      setState(() {
        _customers = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load customers: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customers for ${widget.businessName}'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCustomers,
              child: ListView.builder(
                itemCount: _customers.length,
                itemBuilder: (context, index) {
                  final customer = _customers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(customer['name']?.substring(0, 1) ?? '?'),
                      ),
                      title: Text(customer['name'] ?? 'Unknown'),
                      subtitle: Text(customer['phone_number'] ?? 'No phone'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                CustomerDetailsScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
