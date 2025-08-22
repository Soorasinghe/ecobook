// lib/screens/catalog_maker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/pdf_invoice_service.dart';

class CatalogMakerScreen extends StatefulWidget {
  const CatalogMakerScreen({super.key});

  @override
  State<CatalogMakerScreen> createState() => _CatalogMakerScreenState();
}

class _CatalogMakerScreenState extends State<CatalogMakerScreen> {
  final ApiService _apiService = ApiService();
  final PdfInvoiceService _pdfService = PdfInvoiceService();
  bool _isLoading = true;
  List<dynamic> _products = [];
  final Set<String> _selectedProductIds = {};
  String? _businessName;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final businessId = businesses[0]['id'];
      final products = await _apiService.getProductsByBusiness(
        businessId,
        token,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _businessName = businesses[0]['name'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateCatalog() {
    final selectedProducts = _products
        .where((p) => _selectedProductIds.contains(p['id']))
        .toList();
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _pdfService.generateAndShareCatalog(
      selectedProducts,
      _businessName ?? 'My Business',
    );
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
            title: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                'Create a Catalog',
                style: TextStyle(
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
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final isSelected = _selectedProductIds.contains(
                        product['id'],
                      );
                      return CheckboxListTile(
                        title: Text(product['name']),
                        subtitle: Text('LKR ${product['price']}'),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedProductIds.add(product['id']);
                            } else {
                              _selectedProductIds.remove(product['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: Text(
                        'Generate Catalog (${_selectedProductIds.length} items)',
                      ),
                      onPressed: _generateCatalog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
