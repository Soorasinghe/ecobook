// lib/screens/more_screen.dart
import 'package:flutter/material.dart';
import 'reports_screen.dart';
import 'cashbook_screen.dart';
import 'supplier_list_screen.dart';
import 'catalog_maker_screen.dart'; // <-- 1. IMPORT THE NEW SCREEN

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
              child: const Text(
                'More Options',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildOptionCard(
              context,
              icon: Icons.auto_stories,
              iconColor: Color(0xFF7C3AED),
              title: 'Product Catalog Maker',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const CatalogMakerScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _buildOptionCard(
              context,
              icon: Icons.analytics,
              iconColor: Color(0xFF2563EB),
              title: 'Reports',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ReportsScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _buildOptionCard(
              context,
              icon: Icons.book,
              iconColor: Color(0xFF06B6D4),
              title: 'Cashbook',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const CashbookScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _buildOptionCard(
              context,
              icon: Icons.local_shipping,
              iconColor: Color(0xFF7C3AED),
              title: 'Suppliers',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SupplierListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
