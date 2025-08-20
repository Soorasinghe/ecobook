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
      appBar: AppBar(
        title: Text(widget.businessName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // V-- NEW SORT BUTTON --V
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // V-- NEW SEARCH BAR --V
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Products by Name',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                // Add a clear button to the search field
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
              onChanged: (value) =>
                  setState(() {}), // To show/hide clear button
              onSubmitted: (_) => _fetchProducts(),
            ),
          ),
          // Product List
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
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  title: Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    product['description'] ?? 'No description',
                                  ),
                                  trailing: Text(
                                    'LKR ${product['price']}\nStock: ${product['stock_quantity']}',
                                    textAlign: TextAlign.right,
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
                                    if (result == true) {
                                      _fetchProducts();
                                    }
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
