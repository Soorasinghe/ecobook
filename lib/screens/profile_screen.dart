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
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
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
                  _buildProfileDetail('Full Name', _profileData!['full_name']),
                  _buildProfileDetail('Email', _profileData!['email']),
                  const Divider(height: 32),
                  _buildProfileDetail(
                    'First Name',
                    _profileData!['first_name'],
                  ),
                  _buildProfileDetail('Last Name', _profileData!['last_name']),
                  _buildProfileDetail('NIC', _profileData!['nic']),
                  _buildProfileDetail('Mobile', _profileData!['mobile_number']),
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

  Widget _buildProfileDetail(String label, String? value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(
        value ?? 'Not set',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
