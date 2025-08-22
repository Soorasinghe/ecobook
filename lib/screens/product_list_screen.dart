// lib/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  const ProductListScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _products = [];

  // V-- NEW STATE VARIABLES FOR SEARCH AND SORT --V
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'created_at';
  String _sortOrder = 'DESC';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final products = await _apiService.getProductsByBusiness(
        widget.businessId,
        token,
        search: _searchController.text,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: ${e.toString()}')),
      );
    }
  }

  // V-- NEW FUNCTION TO SHOW SORT OPTIONS --V
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: const Text('Sort by Name (A-Z)'),
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                  _sortOrder = 'ASC';
                });
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sort by Name (Z-A)'),
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                  _sortOrder = 'DESC';
                });
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sort by Price (High-Low)'),
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                  _sortOrder = 'DESC';
                });
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sort by Price (Low-High)'),
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                  _sortOrder = 'ASC';
                });
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Sort by Newest'),
              onTap: () {
                setState(() {
                  _sortBy = 'created_at';
                  _sortOrder = 'DESC';
                });
                _fetchProducts();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddProductScreen(businessId: widget.businessId),
      ),
    );
    if (result == true) {
      _fetchProducts();
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
                widget.businessName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: _showSortOptions,
                tooltip: 'Sort',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products by Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchProducts();
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
              onSubmitted: (_) => _fetchProducts(),
            ),
          ),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchProducts,
                    child: _products.isEmpty
                        ? const Center(child: Text('No products found.'))
                        : ListView.builder(
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade400,
                                          Colors.teal.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    product['name'] ?? 'Unnamed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    product['description'] ?? 'No description',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    'LKR ${product['price']}\nStock: ${product['stock_quantity']}',
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductDetailsScreen(
                                                  product: product,
                                                ),
                                          ),
                                        );
                                    if (result == true) _fetchProducts();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
    );
  }
}
