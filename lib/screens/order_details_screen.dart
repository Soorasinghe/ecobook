// lib/screens/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- 1. IMPORT THIS
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/pdf_invoice_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final ApiService _apiService = ApiService();
  final PdfInvoiceService _pdfService = PdfInvoiceService();
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final details = await _apiService.getOrderById(widget.orderId, token);
      if (mounted) {
        setState(() {
          _orderDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateStatusDialog() {
    String currentStatus = _orderDetails!['status'];
    String currentPaymentStatus = _orderDetails!['payment_status'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Order Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    items:
                        [
                              'Pending',
                              'Processing',
                              'Shipped',
                              'Delivered',
                              'Cancelled',
                            ]
                            .map(
                              (label) => DropdownMenuItem(
                                value: label,
                                child: Text(label),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setDialogState(() => currentStatus = value!),
                    decoration: const InputDecoration(
                      labelText: 'Order Status',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: currentPaymentStatus,
                    items: ['Unpaid', 'Paid', 'COD']
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => currentPaymentStatus = value!),
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    try {
                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token!;
                      await _apiService.updateOrderStatus(
                        widget.orderId,
                        currentStatus,
                        currentPaymentStatus,
                        token,
                      );
                      if (mounted) Navigator.of(ctx).pop();
                      _fetchOrderDetails();
                    } catch (e) {
                      // Handle error
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onShareInvoice() async {
    if (_orderDetails == null) return;
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final profileData = await _apiService.getUserProfile(token);
      final paymentDetails = profileData['payment_details'] as String?;
      _pdfService.generateAndShareInvoice(_orderDetails!, paymentDetails);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // V-- 2. THIS IS THE NEW REMINDER FUNCTION --V
  void _sendPaymentReminder() async {
    if (_orderDetails == null) return;

    final customerName = _orderDetails!['customer_name'];
    final phone = _orderDetails!['phone_number'];
    final totalAmount = _orderDetails!['total_amount'];

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number is not available.'),
        ),
      );
      return;
    }

    String whatsappNumber = phone;
    if (whatsappNumber.startsWith('0')) {
      whatsappNumber = '+94${whatsappNumber.substring(1)}';
    } else if (!whatsappNumber.startsWith('+')) {
      whatsappNumber = '+94$whatsappNumber';
    }

    final message = Uri.encodeComponent(
      'Dear $customerName,\nThis is a friendly reminder for your pending payment of LKR $totalAmount for order #${widget.orderId.substring(0, 8)}.\n\nThank you,\n[Your Business Name]',
    );

    final whatsappUrl = Uri.parse(
      "https://wa.me/$whatsappNumber?text=$message",
    );

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
    }
  }

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
              child: Text(
                'Order #${widget.orderId.substring(0, 8)}',
                style: const TextStyle(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderDetails == null
          ? const Center(child: Text('Could not load order details.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFF7C3AED),
                      ),
                      title: const Text('Customer'),
                      subtitle: Text(
                        _orderDetails!['customer_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: Color(0xFF2563EB),
                      ),
                      title: const Text('Phone'),
                      subtitle: Text(
                        _orderDetails!['phone_number'] ?? 'N/A',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.info, color: Color(0xFF06B6D4)),
                      title: const Text('Status'),
                      subtitle: Text(
                        _orderDetails!['status'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.payment,
                        color: Color(0xFF7C3AED),
                      ),
                      title: const Text('Payment'),
                      subtitle: Text(
                        _orderDetails!['payment_status'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Items in Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...(_orderDetails!['items'] as List).map<Widget>(
                    (item) => Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          item['product_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Price: LKR ${item['price_at_purchase']}',
                        ),
                        trailing: Text('Qty: ${item['quantity']}'),
                      ),
                    ),
                  ),
                  const Divider(height: 32, thickness: 1),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total: LKR ${_orderDetails!['total_amount']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sync),
                      label: const Text('UPDATE STATUS'),
                      onPressed: _showUpdateStatusDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('SHARE INVOICE'),
                      onPressed: _onShareInvoice,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_orderDetails!['payment_status'] == 'Unpaid')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.message),
                          label: const Text('SEND PAYMENT REMINDER'),
                          onPressed: _sendPaymentReminder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
