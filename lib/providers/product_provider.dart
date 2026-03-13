import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/product.dart';
import '../services/firestore_service.dart';
import 'dart:convert';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    // Listen to real-time updates
    _firestore.getProductsStream().listen((productsData) {
      _products = productsData.map((data) => Product.fromMap(data)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      developer.log('Error in products stream', error: e);
      _errorMessage = 'Failed to load products: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final productsData = await _firestore.getAllProducts();
      _products = productsData.map((data) => Product.fromMap(data)).toList();
      _errorMessage = null;
    } catch (e, stackTrace) {
      developer.log('Error loading products', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to load products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      final productData = product.toMap();
      // Handle imagePaths - convert List to JSON string if needed
      if (productData['image_paths'] != null && productData['image_paths'] is List) {
        productData['image_paths'] = jsonEncode(productData['image_paths']);
      }
      await _firestore.addProduct(productData);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error adding product', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to add product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      if (product.id == null) return false;
      final productData = product.toMap();
      // Handle imagePaths - convert List to JSON string if needed
      if (productData['image_paths'] != null && productData['image_paths'] is List) {
        productData['image_paths'] = jsonEncode(productData['image_paths']);
      }
      await _firestore.updateProduct(product.id!, productData);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error updating product', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to update product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _firestore.deleteProduct(id);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error deleting product', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to delete product: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final productsData = await _firestore.searchProducts(query);
      return productsData.map((data) => Product.fromMap(data)).toList();
    } catch (e, stackTrace) {
      developer.log('Error searching products', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  List<Product> filterProducts({
    String? category,
  }) {
    var filtered = _products;

    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((p) => p.category?.toLowerCase().contains(category.toLowerCase()) ?? false).toList();
    }

    return filtered;
  }

  List<String> getCategories() {
    final categories = _products
        .where((p) => p.category != null && p.category!.isNotEmpty)
        .map((p) => p.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

