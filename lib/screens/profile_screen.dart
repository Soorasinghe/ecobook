// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final data = await _apiService.getUserProfile(token);
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToEdit() async {
    if (_profileData == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profileData: _profileData!),
      ),
    );
    if (result == true) {
      _fetchProfile();
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
                'My Profile',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
          ? const Center(child: Text('Could not load profile.'))
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProfileCard(
                    'Full Name',
                    _profileData!['full_name'],
                    Icons.person,
                  ),
                  _buildProfileCard(
                    'Email',
                    _profileData!['email'],
                    Icons.email,
                  ),
                  _buildProfileCard(
                    'First Name',
                    _profileData!['first_name'],
                    Icons.account_circle,
                  ),
                  _buildProfileCard(
                    'Last Name',
                    _profileData!['last_name'],
                    Icons.account_circle_outlined,
                  ),
                  _buildProfileCard('NIC', _profileData!['nic'], Icons.badge),
                  _buildProfileCard(
                    'Mobile',
                    _profileData!['mobile_number'],
                    Icons.phone,
                  ),
                  _buildProfileCard(
                    'District',
                    _profileData!['district'],
                    Icons.location_city,
                  ),
                  _buildProfileCard(
                    'Province',
                    _profileData!['province'],
                    Icons.map,
                  ),
                  _buildProfileCard(
                    'Postal Code',
                    _profileData!['postal_code'],
                    Icons.markunread_mailbox,
                  ),
                  _buildProfileCard(
                    'Payment Details',
                    _profileData!['payment_details'],
                    Icons.qr_code,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    onPressed: _navigateToEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(String label, String? value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7C3AED),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(
          (value == null || value.isEmpty) ? 'Not set' : value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
    );
  }
}
