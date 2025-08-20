// lib/screens/create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final String businessId;
  const CreateOrderScreen({super.key, required this.businessId});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Data for the form
  List<dynamic> _customers = [];
  List<dynamic> _products = [];
  String? _selectedCustomerId;
  final List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final customers = await _apiService.getCustomersByBusiness(
        widget.businessId,
        token,
      );
      final products = await _apiService.getProductsByBusiness(
        widget.businessId,
        token,
      );
      setState(() {
        _customers = customers;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _addProductToCart(Map<String, dynamic> product) {
    setState(() {
      // Check if product is already in cart
      int existingIndex = _cartItems.indexWhere(
        (item) => item['productId'] == product['id'],
      );
      if (existingIndex != -1) {
        _cartItems[existingIndex]['quantity']++;
      } else {
        _cartItems.add({
          'productId': product['id'],
          'name': product['name'],
          'price': double.parse(product['price']),
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

  void _submitOrder() async {
    if (_selectedCustomerId == null || _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer and add items.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final orderData = {
        'businessId': widget.businessId,
        'customerId': _selectedCustomerId,
        'status': 'Processing', // Default status
        'paymentStatus': 'Unpaid', // Default status
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
      Navigator.of(context).pop(true); // Go back and signal success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Create New Order'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Customer Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    hint: const Text('Select a Customer'),
                    items: _customers.map<DropdownMenuItem<String>>((customer) {
                      return DropdownMenuItem<String>(
                        value: customer['id'],
                        child: Text(customer['name']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCustomerId = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Product Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add Product to Order'),
                    onPressed: () => _showProductSelectionDialog(),
                  ),
                  const Divider(height: 32),

                  // Cart Items List
                  Expanded(
                    child: _cartItems.isEmpty
                        ? const Center(child: Text('No items in order.'))
                        : ListView.builder(
                            itemCount: _cartItems.length,
                            itemBuilder: (ctx, index) {
                              final item = _cartItems[index];
                              return ListTile(
                                title: Text(item['name']),
                                subtitle: Text('LKR ${item['price']}'),
                                trailing: Text('Qty: ${item['quantity']}'),
                              );
                            },
                          ),
                  ),

                  // Total Amount and Submit Button
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
                          'LKR $_totalAmount',
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
                      onPressed: _isLoading ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CREATE ORDER'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Dialog to show product list
  Future<void> _showProductSelectionDialog() {
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select a Product'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _products.length,
              itemBuilder: (dCtx, index) {
                final product = _products[index];
                return ListTile(
                  title: Text(product['name']),
                  onTap: () {
                    _addProductToCart(product);
                    Navigator.of(dCtx).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
