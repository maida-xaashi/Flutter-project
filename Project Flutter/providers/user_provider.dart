import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  // Keeping fallback users for demo/admin if API fails or for mixed mode, 
  // but strictly speaking we should rely on API.
  // The original code had hardcoded users. We will ignore them and usage API.
  
  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<User> _users = [];
  List<User> get users => [..._users];

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('login', {
      'email': email,
      'password': password
    });

    if (response['status'] == true) {
      final data = response['user'];
      _currentUser = User(
        id: data['id'].toString(),
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        role: data['role'] == 'admin' ? UserRole.admin : UserRole.user,
        hashedPassword: '', // Not needed on client
        createdAt: data['created_at'] ?? '',
      );
      notifyListeners();
    }
    return response;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, {String? phone}) async {
     final response = await ApiService.post('register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': 'user' // Default
    });
    
    return response;
  }

  void logout() {
    _currentUser = null;
    _users.clear(); // Clear cached admin data on logout
    notifyListeners();
  }

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    
    final response = await ApiService.get('users');
    if (response['status'] == true && response['data'] != null) {
      final List<dynamic> data = response['data'];
      _users.clear();
      _users.addAll(data.map((u) => User(
        id: u['id'].toString(),
        name: u['name'],
        email: u['email'],
        phone: u['phone'],
        role: u['role'] == 'admin' ? UserRole.admin : UserRole.user,
        hashedPassword: u['password'] ?? '', // API returns 'password' (hash) for admins to mask
        createdAt: u['created_at'] ?? '',
      )));
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addUser(String name, String email, String phone, String password, UserRole role) async {
    final response = await ApiService.post('register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role == UserRole.admin ? 'admin' : 'user'
    });
    if (response['status'] == true) {
      fetchAllUsers();
      return true;
    }
    return false;
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    final response = await ApiService.put('users', id, data);
    if (response['status'] == true) {
      fetchAllUsers();
      return true;
    }
    return false;
  }

  Future<bool> deleteUser(String id) async {
    final response = await ApiService.delete('users', id);
    if (response['status'] == true) {
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateProfile(String name, String email) {
    // API call placeholder
  }
}
