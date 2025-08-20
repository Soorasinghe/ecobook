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
      appBar: AppBar(
        title: const Text('More Options'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.auto_stories, color: Colors.teal),
            title: const Text('Product Catalog Maker'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const CatalogMakerScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.teal),
            title: const Text('Reports'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ReportsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.teal),
            title: const Text('Cashbook'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const CashbookScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: Colors.teal),
            title: const Text('Suppliers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const SupplierListScreen()),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
