import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:developer' as developer;
import '../models/user.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService.instance;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserFromFirestore(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final userDoc = await _firestore.usersCollection.doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        data['id'] = uid;
        _currentUser = User.fromMap(data);
        notifyListeners();
      } else {
        // User document doesn't exist in Firestore, create a default one
        developer.log('User document not found in Firestore, creating default user');
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          // Create a default user with admin role
          final defaultUser = User(
            id: uid,
            username: firebaseUser.email?.split('@')[0] ?? 'user',
            email: firebaseUser.email ?? '',
            passwordHash: '', // Not needed for Firebase Auth users
            role: UserRole.admin, // Default to admin for now
            fullName: firebaseUser.displayName,
          );
          final userData = defaultUser.toMap();
          userData.remove('id');
          await _firestore.usersCollection.doc(uid).set(userData);
          _currentUser = defaultUser;
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error loading user from Firestore', error: e, stackTrace: stackTrace);
      // If Firestore fails, still try to use Firebase Auth user
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final defaultUser = User(
          id: uid,
          username: firebaseUser.email?.split('@')[0] ?? 'user',
          email: firebaseUser.email ?? '',
          passwordHash: '',
          role: UserRole.admin,
          fullName: firebaseUser.displayName,
        );
        _currentUser = defaultUser;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      // Sign in directly with email/password using Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _loadUserFromFirestore(credential.user!.uid);
        return true;
      }

      _errorMessage = 'Invalid email or password';
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Firebase Auth error during login', error: e);
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many failed attempts. Please try again later';
          break;
        default:
          _errorMessage = 'Login failed: ${e.message ?? e.code}';
      }
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      developer.log('Error during login', error: e, stackTrace: stackTrace);
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void logout() async {
    await _auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> createUser(User user) async {
    try {
      // Create Firebase Auth user first
      final credential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.passwordHash,
      );

      // Add user to Firestore
      final userData = user.toMap();
      userData.remove('id');
      userData['firebase_uid'] = credential.user!.uid;
      await _firestore.usersCollection.doc(credential.user!.uid).set(userData);

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
      final snapshot = await _firestore.usersCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return User.fromMap(data);
      }).toList();
    } catch (e, stackTrace) {
      developer.log('Error getting users', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      if (user.id == null) return false;
      final userData = user.toMap();
      userData.remove('id');
      await _firestore.usersCollection.doc(user.id!).update(userData);
      
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

  Future<bool> deleteUser(String id) async {
    try {
      await _firestore.usersCollection.doc(id).delete();
      // Optionally delete Firebase Auth user
      try {
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null && firebaseUser.uid == id) {
          await firebaseUser.delete();
        }
      } catch (e) {
        developer.log('Error deleting Firebase Auth user', error: e);
      }
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

