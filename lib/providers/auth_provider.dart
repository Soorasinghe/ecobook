// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;

  bool get isAuth {
    return _token != null;
  }

  String? get token {
    return _token;
  }

  Future<void> login(String token) async {
    _token = token;
    notifyListeners(); // Notify all listening widgets that the state has changed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token); // Save token to device
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authToken')) {
      return false;
    }
    _token = prefs.getString('authToken');
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }
}
