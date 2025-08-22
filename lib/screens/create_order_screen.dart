// lib/screens/create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Data for the form
  List<dynamic> _allBusinesses = [];
  String? _selectedBusinessId;
  List<dynamic> _customers = []; // This will now be your FULL customer list
  List<dynamic> _products = [];
  String? _selectedCustomerId;
  final List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // V-- RENAMED: Fetches both businesses and all customers at the start.
  Future<void> _fetchInitialData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;

      // Fetch both sets of data at the same time
      final results = await Future.wait([
        _apiService.getMyBusinesses(token),
        _apiService.getAllMyCustomers(token), // Get your global customer list
      ]);

      if (mounted) {
        setState(() {
          _allBusinesses = results[0];
          _customers = results[1]; // Store the global customer list
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load initial data: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // V-- SIMPLIFIED: Now only needs to fetch products for the selected business.
  Future<void> _onBusinessSelected(String? businessId) async {
    if (businessId == null) return;
    setState(() {
      // Show loading only for the product section
      _products = [];
      _selectedBusinessId = businessId;
      _selectedCustomerId = null;
      _cartItems.clear();
      _calculateTotal();
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final productsData = await _apiService.getProductsByBusiness(
        businessId,
        token,
      );

      if (mounted) {
        setState(() {
          _products = productsData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load products for business: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  void _addProductToCart(Map<String, dynamic> product) {
    setState(() {
      int existingIndex = _cartItems.indexWhere(
        (item) => item['productId'] == product['id'],
      );
      if (existingIndex != -1) {
        _cartItems[existingIndex]['quantity']++;
      } else {
        _cartItems.add({
          'productId': product['id'],
          'name': product['name'],
          'price': double.parse(product['price'].toString()),
          'quantity': 1,
        });
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = _cartItems.fold(
      0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  void _incrementQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity'] =
          (_cartItems[index]['quantity'] as int) + 1;
      _calculateTotal();
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      final current = (_cartItems[index]['quantity'] as int);
      if (current > 1) {
        _cartItems[index]['quantity'] = current - 1;
      } else {
        _cartItems.removeAt(index);
      }
      _calculateTotal();
    });
  }

  void _submitOrder() async {
    if (_selectedBusinessId == null ||
        _selectedCustomerId == null ||
        _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a business, a customer, and add items.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final orderData = {
        'businessId': _selectedBusinessId,
        'customerId': _selectedCustomerId,
        'status': 'Processing',
        'paymentStatus': 'Unpaid',
        'items': _cartItems
            .map(
              (item) => {
                'productId': item['productId'],
                'quantity': item['quantity'],
              },
            )
            .toList(),
      };
      await _apiService.createOrder(orderData, token);
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _selectedBusinessId,
              hint: const Text('1. Select a Business'),
              items: _allBusinesses.map<DropdownMenuItem<String>>((business) {
                return DropdownMenuItem<String>(
                  value: business['id'],
                  child: Text(business['name']),
                );
              }).toList(),
              onChanged: _onBusinessSelected,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_isLoading && _selectedBusinessId != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCustomerId,
                      hint: const Text('2. Select a Customer'),
                      items: _customers
                          .map<DropdownMenuItem<String>>(
                            (c) => DropdownMenuItem<String>(
                              value: c['id'],
                              child: Text(c['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCustomerId = value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('3. Add Product to Order'),
                      onPressed: () => _showProductSelectionDialog(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const Divider(height: 32),
                    Expanded(
                      child: _cartItems.isEmpty
                          ? const Center(child: Text('No items in order.'))
                          : ListView.builder(
                              itemCount: _cartItems.length,
                              itemBuilder: (ctx, index) {
                                final item = _cartItems[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'] ?? 'Unnamed',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'LKR ${item['price'].toStringAsFixed(2)}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  _decrementQuantity(index),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              color: Colors.red,
                                            ),
                                            Text(
                                              '${item['quantity']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _incrementQuantity(index),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              color: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'LKR ${_totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('CREATE ORDER'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showProductSelectionDialog() {
    final TextEditingController searchCtrl = TextEditingController();
    List<dynamic> filtered = List.from(_products);

    return showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            void filter(String q) {
              setStateDialog(() {
                filtered = q.isEmpty
                    ? List.from(_products)
                    : _products
                          .where(
                            (p) => (p['name'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(q.toLowerCase()),
                          )
                          .toList();
              });
            }

            return AlertDialog(
              title: const Text('Select a Product'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchCtrl.clear();
                                  filter('');
                                },
                              )
                            : null,
                      ),
                      onChanged: filter,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No products found',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (dCtx, index) {
                                final p = filtered[index];
                                return ListTile(
                                  title: Text(p['name'] ?? 'Unnamed'),
                                  subtitle: Text(
                                    'LKR ${double.tryParse(p['price']?.toString() ?? '0.0')!.toStringAsFixed(2)}',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      _addProductToCart(p);
                                      Navigator.of(dCtx).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('ADD'),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
