// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // The base URL of your Node.js backend
  final String _baseUrl = 'http://10.0.2.2:3001/api';

  // Function to handle the login API call
  Future<String> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK, parse the JSON and return the token
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      // If the server returns an error, throw an exception
      throw Exception('Failed to login');
    }
  }

  Future<List<dynamic>> getMyBusinesses(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/businesses'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Send the token for protected routes
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load businesses');
    }
  }

  Future<void> createBusiness(
    String name,
    String description,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/businesses'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create business.');
    }
  }

  Future<void> deleteBusiness(String businessId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/businesses/$businessId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete business.');
    }
  }

  Future<void> updateBusiness(
    String businessId,
    String name,
    String description,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/businesses/$businessId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update business.');
    }
  }

  Future<List<dynamic>> getProductsByBusiness(
    String businessId,
    String token, {
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    // Build the query string
    var uri = Uri.parse('$_baseUrl/products?businessId=$businessId');
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    uri = uri.replace(
      queryParameters: queryParams..addAll(uri.queryParameters),
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> createProduct(
    Map<String, dynamic> productData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create product.');
    }
  }

  Future<void> deleteProduct(String productId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product.');
    }
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> productData,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update product.');
    }
  }

  Future<List<dynamic>> getCustomersByBusiness(
    String businessId,
    String token, {
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    var uri = Uri.parse('$_baseUrl/customers?businessId=$businessId');
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    uri = uri.replace(
      queryParameters: queryParams..addAll(uri.queryParameters),
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<void> createCustomer(
    Map<String, dynamic> customerData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/customers'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(customerData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create customer.');
    }
  }

  Future<void> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/customers/$customerId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(customerData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update customer.');
    }
  }

  Future<void> deleteCustomer(String customerId, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/customers/$customerId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete customer.');
    }
  }

  Future<Map<String, dynamic>> getOrdersByBusiness(
    // <-- Changed from List<dynamic> to Map<String, dynamic>
    String businessId,
    String token, {
    String? search,
    String? sortBy,
    String? sortOrder,
    String? status,
  }) async {
    var uri = Uri.parse('$_baseUrl/orders?businessId=$businessId');
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
    if (status != null) queryParams['status'] = status;

    uri = uri.replace(
      queryParameters: queryParams..addAll(uri.queryParameters),
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Map<String, dynamic>> getOrderById(
    String orderId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load order details.');
    }
  }

  Future<void> createOrder(Map<String, dynamic> orderData, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode != 201) {
      // Try to parse the error message from the backend
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to create order: ${errorData['error']}');
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status,
    String paymentStatus,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'status': status,
        'paymentStatus': paymentStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status.');
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary(
    String businessId,
    String period,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/reports/dashboard-summary?businessId=$businessId&period=$period',
      ),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard summary.');
    }
  }

  Future<Map<String, dynamic>> getProfitLossReport(
    String businessId,
    String startDate,
    String endDate,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/reports/profit-loss?businessId=$businessId&startDate=$startDate&endDate=$endDate',
      ),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load P&L report.');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    // Note: Your backend should be configured to return both user and profile data at this endpoint.
    // We will assume the GET /api/profile/me endpoint on your backend already does this.
    final response = await http.get(
      Uri.parse('$_baseUrl/profile/me'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile.');
    }
  }

  // Updates the user's profile data
  Future<void> updateUserProfile(
    Map<String, dynamic> profileData,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/profile/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile.');
    }
  }

  Future<Map<String, dynamic>> getCustomerReport(
    String customerId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/customer-summary?customerId=$customerId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load customer report.');
    }
  }

  Future<Map<String, dynamic>> getTransactions(
    String businessId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/transactions?businessId=$businessId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions.');
    }
  }

  Future<void> createTransaction(
    Map<String, dynamic> transactionData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/transactions'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(transactionData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create transaction.');
    }
  }

  Future<List<dynamic>> getSuppliersByBusiness(
    String businessId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/suppliers?businessId=$businessId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load suppliers.');
  }

  Future<void> createSupplier(Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/suppliers'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 201)
      throw Exception('Failed to create supplier.');
  }

  Future<void> updateSupplier(
    String id,
    Map<String, dynamic> data,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/suppliers/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200)
      throw Exception('Failed to update supplier.');
  }

  Future<void> deleteSupplier(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/suppliers/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200)
      throw Exception('Failed to delete supplier.');
  }

  Future<List<dynamic>> getInventoryInsights(
    String businessId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reports/inventory-insights?businessId=$businessId'),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load inventory insights.');
    }
  }

  Future<Map<String, dynamic>> getTopPerformers(
    String businessId,
    String period,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/dashboard/performers?businessId=$businessId&period=$period',
      ),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load top performers.');
    }
  }

  Future<Map<String, dynamic>> getOrderReport(
    String businessId,
    String startDate,
    String endDate,
    String sortBy,
    String sortOrder,
    String token,
  ) async {
    // ... (the rest of the function is the same, it already returns a Map)
    final uri = Uri.parse(
      '$_baseUrl/reports/order-report'
      '?businessId=$businessId&startDate=$startDate&endDate=$endDate&sortBy=$sortBy&sortOrder=$sortOrder',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load order report.');
    }
  }

  Future<void> registerUser(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      // If the server returns an error, parse the message if possible
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to register: ${errorData.toString()}');
    }
  }

  Future<List<dynamic>> getAllMyCustomers(
    String token, {
    String search = '',
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
  }) async {
    // Note the new endpoint path: /customers/all
    final uri = Uri.parse('$_baseUrl/customers/all').replace(
      queryParameters: {
        'search': search,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load all customers');
    }
  }

  Future<List<dynamic>> getAllMyOrders(
    String token, {
    String? search,
    String? status,
  }) async {
    var uri = Uri.parse('$_baseUrl/orders/all');
    final Map<String, dynamic> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status;

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load all orders');
    }
  }
}
