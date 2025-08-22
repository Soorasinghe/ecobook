// lib/screens/tabs_screen.dart
import 'package:flutter/material.dart';
import 'business_list_screen.dart';
import 'customer_list_screen.dart';
import 'order_list_screen.dart';
import 'more_screen.dart';
import 'create_order_screen.dart'; // Import the create order screen

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  final List<Widget> _pages = [
    const BusinessListScreen(),
    // V-- CHANGED: Remove the parameters. It now works globally.
    const CustomerListScreen(),
    const OrderListScreen(),
    const MoreScreen(),
  ];

  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void _navigateToCreateOrder() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => const CreateOrderScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: _pages[_selectedPageIndex],

      // The Floating Action Button for creating new orders
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateOrder,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
        tooltip: 'New Order',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // The Bottom Navigation Bar, wrapped in a BottomAppBar for the notch effect
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Creates the notch
        notchMargin: 8.0, // Space around the button
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildTabItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                index: 0,
              ),
              _buildTabItem(icon: Icons.people, label: 'Customers', index: 1),
              const SizedBox(width: 40), // The space for the notch
              _buildTabItem(
                icon: Icons.receipt_long,
                label: 'Orders',
                index: 2,
              ),
              _buildTabItem(icon: Icons.more_horiz, label: 'More', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each navigation item
  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedPageIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _selectPage(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
