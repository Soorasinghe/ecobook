// lib/providers/business_provider.dart
import 'package:flutter/material.dart';

class BusinessProvider with ChangeNotifier {
  Map<String, dynamic>? _selectedBusiness;

  Map<String, dynamic>? get selectedBusiness => _selectedBusiness;

  void selectBusiness(Map<String, dynamic> business) {
    _selectedBusiness = business;
    notifyListeners(); // This tells other screens that the selection has changed
  }

  void clearBusiness() {
    _selectedBusiness = null;
    notifyListeners();
  }
}
