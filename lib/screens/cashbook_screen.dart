// lib/screens/cashbook_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  double _currentBalance = 0.0;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);
      if (businesses.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final businessId = businesses[0]['id'];
      final data = await _apiService.getTransactions(businessId, token);
      setState(() {
        _transactions = data['transactions'];
        _currentBalance = (data['currentBalance'] as num).toDouble();
        _businessId = businessId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load cashbook: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddTransactionDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'Income';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Transaction'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButton<String>(
                    value: type,
                    isExpanded: true,
                    items: ['Income', 'Expense']
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) =>
                        setDialogState(() => type = newValue!),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (descriptionController.text.isEmpty ||
                    amountController.text.isEmpty)
                  return;
                final transactionData = {
                  'businessId': _businessId,
                  'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  'description': descriptionController.text,
                  'amount': double.parse(amountController.text),
                  'type': type,
                };
                try {
                  final token = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).token!;
                  await _apiService.createTransaction(transactionData, token);
                  Navigator.of(ctx).pop();
                  _fetchData();
                } catch (e) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to add transaction: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbook'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Balance:',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'LKR ${_currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _currentBalance >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    child: _transactions.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions yet. Add one using the + button.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              // V-- THE FIX IS HERE --V
                              final amount = double.parse(tx['amount']);
                              final isIncome = amount >= 0;

                              return ListTile(
                                leading: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                                title: Text(tx['description']),
                                subtitle: Text(
                                  DateFormat('MMM dd, yyyy').format(
                                    DateTime.parse(tx['transaction_date']),
                                  ),
                                ),
                                trailing: Text(
                                  // V-- AND THE FIX IS HERE --V
                                  'LKR ${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _businessId == null ? null : _showAddTransactionDialog,
        backgroundColor: _businessId == null ? Colors.grey : Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}
