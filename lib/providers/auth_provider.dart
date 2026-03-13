import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../database/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final DatabaseHelper _db = DatabaseHelper.instance;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _errorMessage = null;
    try {
      final user = await _db.getUserByUsername(username);
      if (user != null && user.passwordHash == password) {
        _currentUser = user;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Invalid username or password';
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      developer.log('Error during login', error: e, stackTrace: stackTrace);
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> createUser(User user) async {
    try {
      await _db.insertUser(user);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log('Error creating user', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to create user: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      return await _db.getAllUsers();
    } catch (e, stackTrace) {
      developer.log('Error getting users', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      await _db.updateUser(user);
      if (user.id == _currentUser?.id) {
        _currentUser = user;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log('Error updating user', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to update user: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _db.deleteUser(id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      developer.log('Error deleting user', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to delete user: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

