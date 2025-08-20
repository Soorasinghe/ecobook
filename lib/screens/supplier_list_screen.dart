// lib/screens/supplier_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'add_supplier_screen.dart';
import 'supplier_details_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _suppliers = [];
  String? _businessId;
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final firstBusiness = businesses[0];
      final suppliers = await _apiService.getSuppliersByBusiness(
        firstBusiness['id'],
        token,
      );
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _businessId = firstBusiness['id'];
          _businessName = firstBusiness['name'];
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

  void _navigateToAddSupplier() async {
    if (_businessId == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddSupplierScreen(businessId: _businessId!),
      ),
    );
    if (result == true) _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _businessName != null ? 'Suppliers for $_businessName' : 'Suppliers',
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: _suppliers.isEmpty
                  ? const Center(child: Text('No suppliers found.'))
                  : ListView.builder(
                      itemCount: _suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = _suppliers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.local_shipping,
                              color: Colors.teal,
                            ),
                            title: Text(
                              supplier['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              supplier['phone_number'] ?? 'No phone number',
                            ),
                            onTap: () async {
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SupplierDetailsScreen(
                                            supplier: supplier,
                                          ),
                                    ),
                                  );
                              if (result == true) _fetchData();
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSupplier,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add Supplier',
      ),
    );
  }
}
