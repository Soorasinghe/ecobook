// lib/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _customers = [];
  String? _businessId;
  String? _businessName;

  // State for search and sort
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'created_at';
  String _sortOrder = 'DESC';

  @override
  void initState() {
    super.initState();
    // Add a listener to fetch data whenever search text changes
    _searchController.addListener(() {
      // You might want to add a debounce here in a real app to avoid excessive API calls
      _fetchData();
    });
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    // Only set loading to true on the initial fetch, not for every search keystroke
    if (_searchController.text.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _customers = []; // Ensure customers list is empty
          });
        }
        return;
      }
      final firstBusiness = businesses[0];
      final businessId = firstBusiness['id']
          .toString(); // Ensure ID is a string if needed
      final customers = await _apiService.getCustomersByBusiness(
        businessId,
        token,
        search: _searchController.text,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (mounted) {
        setState(() {
          _customers = customers;
          _businessId = businessId;
          _businessName = firstBusiness['name'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optionally show a snackbar on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            _buildSortOption(
              context,
              title: 'Sort by Newest',
              groupValue: '$_sortBy:$_sortOrder',
              value: 'created_at:DESC',
            ),
            _buildSortOption(
              context,
              title: 'Sort by Name (A-Z)',
              groupValue: '$_sortBy:$_sortOrder',
              value: 'name:ASC',
            ),
            _buildSortOption(
              context,
              title: 'Sort by Name (Z-A)',
              groupValue: '$_sortBy:$_sortOrder',
              value: 'name:DESC',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required String groupValue,
    required String value,
  }) {
    final bool isSelected = groupValue == value;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.teal : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Colors.teal.shade400)
          : null,
      onTap: () {
        final parts = value.split(':');
        setState(() {
          _sortBy = parts[0];
          _sortOrder = parts[1];
        });
        _fetchData();
        Navigator.pop(context);
      },
    );
  }

  void _navigateToAddCustomer() async {
    if (_businessId == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(businessId: _businessId!),
      ),
    );
    if (result == true) _fetchData();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // <-- REMOVED: Redundant title, which is now in the AppBar
          Text(
            'Manage your customer relationships.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _showSortOptions,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.sort, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerListItem(Map<String, dynamic> customer, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) =>
                      CustomerDetailsScreen(customer: customer),
                ),
              );
              if (result == true) _fetchData();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.teal.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer['phone_number'] ?? 'No phone number',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer['loyalty_points']?.toString() ?? '0',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            'No Customers Found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              _searchController.text.isEmpty
                  ? "Tap the '+' button to add your first customer."
                  : "Try adjusting your search or sort parameters.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        // <-- MODIFIED: Styled AppBar for the top bar
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(
          _businessName ?? 'Customers',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        // Add a subtle bottom border to separate the AppBar from the content
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: Colors.teal,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                ),
              )
            else if (_customers.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildCustomerListItem(_customers[index], index),
                  childCount: _customers.length,
                ),
              ),
            // Add some padding at the bottom for the FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCustomer,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Customer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
