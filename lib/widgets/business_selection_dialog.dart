// lib/widgets/business_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class BusinessSelectionDialog extends StatefulWidget {
  const BusinessSelectionDialog({super.key});

  @override
  State<BusinessSelectionDialog> createState() =>
      _BusinessSelectionDialogState();
}

class _BusinessSelectionDialogState extends State<BusinessSelectionDialog> {
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _businessesFuture;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    _businessesFuture = _apiService.getMyBusinesses(token);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer To...'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<dynamic>>(
          future: _businessesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load businesses.'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No businesses found. Create one first!'),
              );
            }

            final businesses = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: businesses.length,
              itemBuilder: (ctx, index) {
                final business = businesses[index];
                return ListTile(
                  title: Text(business['name']),
                  onTap: () {
                    // Return the selected business map when tapped
                    Navigator.of(context).pop(business);
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Return null on cancel
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}
