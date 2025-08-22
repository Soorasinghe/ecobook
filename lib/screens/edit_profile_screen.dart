// lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // V-- Controllers for ALL fields --V
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _nicController;
  late TextEditingController _mobileController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _paymentDetailsController;

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profileData['first_name'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.profileData['last_name'] ?? '',
    );
    _nicController = TextEditingController(
      text: widget.profileData['nic'] ?? '',
    );
    _mobileController = TextEditingController(
      text: widget.profileData['mobile_number'] ?? '',
    );
    // V-- Initialize ALL new controllers --V
    _districtController = TextEditingController(
      text: widget.profileData['district'] ?? '',
    );
    _provinceController = TextEditingController(
      text: widget.profileData['province'] ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.profileData['postal_code'] ?? '',
    );
    _paymentDetailsController = TextEditingController(
      text: widget.profileData['payment_details'] ?? '',
    );
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicController.dispose();
    _mobileController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _paymentDetailsController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;

      // V-- Add ALL fields to the data map sent to the API --V
      final updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'nic': _nicController.text,
        'mobileNumber': _mobileController.text,
        'district': _districtController.text,
        'province': _provinceController.text,
        'postalCode': _postalCodeController.text,
        'paymentDetails': _paymentDetailsController.text,
      };

      await _apiService.updateUserProfile(updatedData, token);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            title: const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                'Edit Profile',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Personal Details
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicController,
              decoration: const InputDecoration(
                labelText: 'NIC',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),

            const Divider(height: 32, thickness: 1),

            // Address Details
            TextField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _provinceController,
              decoration: const InputDecoration(
                labelText: 'Province',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Postal Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const Divider(height: 32, thickness: 1),

            // Payment Details
            TextField(
              controller: _paymentDetailsController,
              decoration: const InputDecoration(
                labelText: 'Payment QR Details (e.g., Bank Acc, UPI)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SAVE CHANGES'),
            ),
          ],
        ),
      ),
    );
  }
}
