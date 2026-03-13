import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/stock.dart';
import '../models/stock_movement.dart';
import '../services/firestore_service.dart';

class StockProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Stock> _stock = [];
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Stock> get stock => _stock;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StockProvider() {
    // Listen to real-time updates for stock
    _firestore.getStockStream().listen((stockData) {
      _stock = stockData.map((data) => Stock.fromMap(data)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      developer.log('Error in stock stream', error: e);
      _errorMessage = 'Failed to load stock: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    });

    // Listen to real-time updates for movements
    _firestore.getMovementsStream().listen((movementsData) {
      _movements = movementsData.map((data) => StockMovement.fromMap(data)).toList();
      notifyListeners();
    }, onError: (e) {
      developer.log('Error in movements stream', error: e);
    });
  }

  Future<void> loadStock() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final stockData = await _firestore.getAllStock();
      _stock = stockData.map((data) => Stock.fromMap(data)).toList();
      _errorMessage = null;
    } catch (e, stackTrace) {
      developer.log('Error loading stock', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to load stock: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMovements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final movementsData = await _firestore.getAllStockMovements();
      _movements = movementsData.map((data) => StockMovement.fromMap(data)).toList();
      _errorMessage = null;
    } catch (e, stackTrace) {
      developer.log('Error loading movements', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to load movements: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStock(Stock stock) async {
    try {
      final stockData = stock.toMap();
      await _firestore.addStock(stockData);
      // Sync product quantity
      await _syncProductQuantity(stock.productId);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error adding stock', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to add stock: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStock(Stock stock) async {
    try {
      if (stock.id == null) return false;
      final stockData = stock.toMap();
      await _firestore.updateStock(stock.id!, stockData);
      // Sync product quantity
      await _syncProductQuantity(stock.productId);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error updating stock', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to update stock: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStock(String id) async {
    try {
      // Get stock item to sync product quantity after deletion
      final stockItem = _stock.firstWhere((s) => s.id == id, orElse: () => throw Exception('Stock not found'));
      final productId = stockItem.productId;
      
      await _firestore.deleteStock(id);
      // Sync product quantity after deletion
      await _syncProductQuantity(productId);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error deleting stock', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to delete stock: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordMovement(StockMovement movement) async {
    try {
      developer.log('Starting movement recording: ${movement.type.name}, Product: ${movement.productId}');
      
      // Get existing stock before making changes
      Stock? existingStock;
      if (movement.type == MovementType.addition && movement.toLocationId != null) {
        existingStock = await _getStock(movement.productId, movement.toLocationId!, movement.batchNumber);
      } else if (movement.type == MovementType.reduction && movement.fromLocationId != null) {
        existingStock = await _getStock(movement.productId, movement.fromLocationId!, movement.batchNumber);
      } else if (movement.type == MovementType.adjustment && movement.toLocationId != null) {
        existingStock = await _getStock(movement.productId, movement.toLocationId!, movement.batchNumber);
      }

      // Prepare batch operations
      final List<Map<String, dynamic>> batchOps = [];
      
      // Add movement record
      batchOps.add({
        'type': 'add',
        'collection': 'stock_movements',
        'data': movement.toMap(),
      });

      // Update stock based on movement type
      if (movement.type == MovementType.addition && movement.toLocationId != null) {
        if (existingStock != null && existingStock.id != null) {
          batchOps.add({
            'type': 'update',
            'collection': 'stock',
            'id': existingStock.id,
            'data': existingStock.copyWith(
              quantity: existingStock.quantity + movement.quantity,
            ).toMap(),
          });
        } else {
          batchOps.add({
            'type': 'add',
            'collection': 'stock',
            'data': Stock(
              productId: movement.productId,
              locationId: movement.toLocationId!,
              quantity: movement.quantity,
              batchNumber: movement.batchNumber,
            ).toMap(),
          });
        }
      } else if (movement.type == MovementType.reduction && movement.fromLocationId != null) {
        if (existingStock != null && existingStock.id != null) {
          // Check if there's enough stock to reduce
          if (existingStock.quantity < movement.quantity) {
            throw Exception('Insufficient stock. Available: ${existingStock.quantity}, Requested: ${movement.quantity}');
          }
          final newQuantity = existingStock.quantity - movement.quantity;
          if (newQuantity > 0) {
            batchOps.add({
              'type': 'update',
              'collection': 'stock',
              'id': existingStock.id,
              'data': existingStock.copyWith(quantity: newQuantity).toMap(),
            });
          } else {
            batchOps.add({
              'type': 'delete',
              'collection': 'stock',
              'id': existingStock.id,
            });
          }
        } else {
          throw Exception('No stock found at the specified location to reduce from');
        }
      } else if (movement.type == MovementType.adjustment && movement.toLocationId != null) {
        if (existingStock != null && existingStock.id != null) {
          batchOps.add({
            'type': 'update',
            'collection': 'stock',
            'id': existingStock.id,
            'data': existingStock.copyWith(quantity: movement.quantity).toMap(),
          });
        } else {
          batchOps.add({
            'type': 'add',
            'collection': 'stock',
            'data': Stock(
              productId: movement.productId,
              locationId: movement.toLocationId!,
              quantity: movement.quantity,
              batchNumber: movement.batchNumber,
            ).toMap(),
          });
        }
      } else if (movement.type == MovementType.transfer) {
        // Get both stocks for transfer
        Stock? fromStock;
        Stock? toStock;
        
        if (movement.fromLocationId != null) {
          fromStock = await _getStock(movement.productId, movement.fromLocationId!, movement.batchNumber);
        }
        if (movement.toLocationId != null) {
          toStock = await _getStock(movement.productId, movement.toLocationId!, movement.batchNumber);
        }

        // Reduce from source
        if (fromStock != null && fromStock.id != null) {
          // Check if there's enough stock to transfer
          if (fromStock.quantity < movement.quantity) {
            throw Exception('Insufficient stock to transfer. Available: ${fromStock.quantity}, Requested: ${movement.quantity}');
          }
          final newQuantity = fromStock.quantity - movement.quantity;
          if (newQuantity > 0) {
            batchOps.add({
              'type': 'update',
              'collection': 'stock',
              'id': fromStock.id,
              'data': fromStock.copyWith(quantity: newQuantity).toMap(),
            });
          } else {
            batchOps.add({
              'type': 'delete',
              'collection': 'stock',
              'id': fromStock.id,
            });
          }
        } else {
          throw Exception('No stock found at the source location to transfer from');
        }

        // Add to destination
        if (toStock != null && toStock.id != null) {
          batchOps.add({
            'type': 'update',
            'collection': 'stock',
            'id': toStock.id,
            'data': toStock.copyWith(
              quantity: toStock.quantity + movement.quantity,
            ).toMap(),
          });
        } else if (movement.toLocationId != null) {
          batchOps.add({
            'type': 'add',
            'collection': 'stock',
            'data': Stock(
              productId: movement.productId,
              locationId: movement.toLocationId!,
              quantity: movement.quantity,
              batchNumber: movement.batchNumber,
            ).toMap(),
          });
        }
      }

      // Execute batch write
      await _firestore.batchWrite(batchOps);
      
      // Sync product quantity
      await _syncProductQuantity(movement.productId);
      
      developer.log('Movement recording completed successfully');
      return true;
    } catch (e, stackTrace) {
      developer.log('Error recording movement', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to record movement: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMovement(String movementId) async {
    try {
      // Get the movement to reverse its effects
      final movement = _movements.firstWhere(
        (m) => m.id == movementId,
        orElse: () => throw Exception('Movement not found'),
      );

      developer.log('Deleting movement: ${movement.type.name}, Product: ${movement.productId}');

      // Prepare batch operations to reverse the movement
      final List<Map<String, dynamic>> batchOps = [];

      // Reverse stock changes based on movement type
      if (movement.type == MovementType.addition && movement.toLocationId != null) {
        // Reverse: reduce from destination
        final existingStock = await _getStock(movement.productId, movement.toLocationId!, movement.batchNumber);
        if (existingStock != null && existingStock.id != null) {
          final newQuantity = existingStock.quantity - movement.quantity;
          if (newQuantity > 0) {
            batchOps.add({
              'type': 'update',
              'collection': 'stock',
              'id': existingStock.id,
              'data': existingStock.copyWith(quantity: newQuantity).toMap(),
            });
          } else {
            batchOps.add({
              'type': 'delete',
              'collection': 'stock',
              'id': existingStock.id,
            });
          }
        }
      } else if (movement.type == MovementType.reduction && movement.fromLocationId != null) {
        // Reverse: add back to source
        final existingStock = await _getStock(movement.productId, movement.fromLocationId!, movement.batchNumber);
        if (existingStock != null && existingStock.id != null) {
          batchOps.add({
            'type': 'update',
            'collection': 'stock',
            'id': existingStock.id,
            'data': existingStock.copyWith(
              quantity: existingStock.quantity + movement.quantity,
            ).toMap(),
          });
        } else {
          batchOps.add({
            'type': 'add',
            'collection': 'stock',
            'data': Stock(
              productId: movement.productId,
              locationId: movement.fromLocationId!,
              quantity: movement.quantity,
              batchNumber: movement.batchNumber,
            ).toMap(),
          });
        }
      } else if (movement.type == MovementType.adjustment && movement.toLocationId != null) {
        // For adjustment, we need to restore previous quantity
        // Since we don't store previous quantity, we'll need to recalculate from other movements
        // For now, we'll delete the stock if it exists (user should manually adjust)
        final existingStock = await _getStock(movement.productId, movement.toLocationId!, movement.batchNumber);
        if (existingStock != null && existingStock.id != null) {
          // Delete the stock - user will need to manually adjust
          batchOps.add({
            'type': 'delete',
            'collection': 'stock',
            'id': existingStock.id,
          });
        }
      } else if (movement.type == MovementType.transfer) {
        // Reverse: move back from destination to source
        Stock? fromStock;
        Stock? toStock;
        
        if (movement.fromLocationId != null) {
          fromStock = await _getStock(movement.productId, movement.fromLocationId!, movement.batchNumber);
        }
        if (movement.toLocationId != null) {
          toStock = await _getStock(movement.productId, movement.toLocationId!, movement.batchNumber);
        }

        // Add back to source
        if (fromStock != null && fromStock.id != null) {
          batchOps.add({
            'type': 'update',
            'collection': 'stock',
            'id': fromStock.id,
            'data': fromStock.copyWith(
              quantity: fromStock.quantity + movement.quantity,
            ).toMap(),
          });
        } else if (movement.fromLocationId != null) {
          batchOps.add({
            'type': 'add',
            'collection': 'stock',
            'data': Stock(
              productId: movement.productId,
              locationId: movement.fromLocationId!,
              quantity: movement.quantity,
              batchNumber: movement.batchNumber,
            ).toMap(),
          });
        }

        // Reduce from destination
        if (toStock != null && toStock.id != null) {
          final newQuantity = toStock.quantity - movement.quantity;
          if (newQuantity > 0) {
            batchOps.add({
              'type': 'update',
              'collection': 'stock',
              'id': toStock.id,
              'data': toStock.copyWith(quantity: newQuantity).toMap(),
            });
          } else {
            batchOps.add({
              'type': 'delete',
              'collection': 'stock',
              'id': toStock.id,
            });
          }
        }
      }

      // Delete the movement record
      batchOps.add({
        'type': 'delete',
        'collection': 'stock_movements',
        'id': movementId,
      });

      // Execute batch write
      await _firestore.batchWrite(batchOps);
      
      // Sync product quantity
      await _syncProductQuantity(movement.productId);
      
      developer.log('Movement deletion completed successfully');
      return true;
    } catch (e, stackTrace) {
      developer.log('Error deleting movement', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to delete movement: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<Stock?> _getStock(String productId, String locationId, String? batchNumber) async {
    try {
      final stockData = await _firestore.getStock(productId, locationId, batchNumber: batchNumber);
      if (stockData == null) return null;
      return Stock.fromMap(stockData);
    } catch (e) {
      developer.log('Error getting stock', error: e);
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<Stock> getLowStockItems() {
    return _stock.where((s) => s.isLowStock).toList();
  }

  List<Stock> getOverstockItems() {
    return _stock.where((s) => s.isOverstock).toList();
  }

  List<Stock> getExpiringSoonItems() {
    return _stock.where((s) => s.isExpiringSoon).toList();
  }

  List<Stock> getStockByLocation(String locationId) {
    return _stock.where((s) => s.locationId == locationId).toList();
  }

  List<Stock> getStockByProduct(String productId) {
    return _stock.where((s) => s.productId == productId).toList();
  }

  // Calculate total stock quantity across all locations
  double get totalStockQuantity {
    return _stock.fold<double>(0, (sum, stock) => sum + stock.quantity);
  }

  // Get unique products with low stock (not individual stock records)
  List<String> getLowStockProductIds() {
    final lowStockItems = getLowStockItems();
    return lowStockItems.map((s) => s.productId).toSet().toList();
  }

  // Get unique products expiring soon (not individual stock records)
  List<String> getExpiringSoonProductIds() {
    final expiringItems = getExpiringSoonItems();
    return expiringItems.map((s) => s.productId).toSet().toList();
  }

  // Sync product's currentQuantity with actual stock totals
  Future<void> _syncProductQuantity(String productId) async {
    try {
      // Get all stock for this product
      final stockItems = await _firestore.getStockByProduct(productId);
      final totalQuantity = stockItems.fold<double>(0, (sum, stockData) {
        final stock = Stock.fromMap(stockData);
        return sum + stock.quantity;
      });
      
      // Get the product
      final productData = await _firestore.getProductById(productId);
      if (productData != null) {
        // Update product's currentQuantity
        final updatedProductData = Map<String, dynamic>.from(productData);
        updatedProductData['current_quantity'] = totalQuantity;
        await _firestore.updateProduct(productId, updatedProductData);
      }
    } catch (e, stackTrace) {
      developer.log('Error syncing product quantity', error: e, stackTrace: stackTrace);
      // Don't throw - this is a background sync operation
    }
  }
}

