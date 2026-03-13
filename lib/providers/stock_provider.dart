// NOTE: This is LEGACY SQLite code - NOT USED with Firebase
// The app now uses StockProviderFirebase instead
// This file is kept for reference but has type errors (int vs String IDs)
// These errors don't affect the app since this provider is not imported anywhere

import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/stock.dart';
import '../models/stock_movement.dart';
import '../database/database_helper.dart';

class StockProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Stock> _stock = [];
  List<StockMovement> _movements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Stock> get stock => _stock;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadStock() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _stock = await _db.getAllStock();
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
      _movements = await _db.getAllStockMovements();
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
      await _db.insertStock(stock);
      // Sync product quantity
      await _syncProductQuantity(stock.productId);
      await loadStock();
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
      await _db.updateStock(stock);
      // Sync product quantity
      await _syncProductQuantity(stock.productId);
      await loadStock();
      return true;
    } catch (e, stackTrace) {
      developer.log('Error updating stock', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to update stock: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStock(int id) async {
    try {
      // Get stock item to sync product quantity after deletion
      final stockItem = _stock.firstWhere((s) => s.id == id, orElse: () => throw Exception('Stock not found'));
      final productId = stockItem.productId;
      
      await _db.deleteStock(id);
      // Sync product quantity after deletion
      await _syncProductQuantity(productId);
      await loadStock();
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
      
      // Use transaction to ensure atomicity
      await _db.transaction((txn) async {
        developer.log('Transaction started');
        
        // Insert movement record
        final movementId = await txn.insert('stock_movements', movement.toMap());
        developer.log('Movement record inserted with ID: $movementId');
        
        // Helper function to get stock within transaction
        Future<Stock?> getStockInTransaction(int productId, int locationId, {String? batchNumber}) async {
          try {
            List<Map<String, dynamic>> maps;
            if (batchNumber == null || batchNumber.isEmpty) {
              // Query for NULL batch numbers
              maps = await txn.query(
                'stock',
                where: 'product_id = ? AND location_id = ? AND batch_number IS NULL',
                whereArgs: [productId, locationId],
              );
            } else {
              // Query for specific batch number
              maps = await txn.query(
                'stock',
                where: 'product_id = ? AND location_id = ? AND batch_number = ?',
                whereArgs: [productId, locationId, batchNumber],
              );
            }
            if (maps.isEmpty) return null;
            return Stock.fromMap(maps.first);
          } catch (e) {
            developer.log('Error in getStockInTransaction', error: e);
            rethrow;
          }
        }
        
        // Update stock based on movement type
        if (movement.type == MovementType.addition && movement.toLocationId != null) {
          developer.log('Processing addition movement to location ${movement.toLocationId}');
          final existingStock = await getStockInTransaction(
            movement.productId,
            movement.toLocationId!,
            batchNumber: movement.batchNumber,
          );
          
          if (existingStock != null) {
            developer.log('Updating existing stock: ${existingStock.id}, new quantity: ${existingStock.quantity + movement.quantity}');
            await txn.update(
              'stock',
              existingStock.copyWith(
                quantity: existingStock.quantity + movement.quantity,
              ).toMap(),
              where: 'id = ?',
              whereArgs: [existingStock.id],
            );
          } else {
            developer.log('Creating new stock record');
            await txn.insert('stock', Stock(
              productId: movement.productId,
              locationId: movement.toLocationId!,
              quantity: movement.quantity,
              batchNumber: movement.batchNumber,
            ).toMap());
          }
        } else if (movement.type == MovementType.reduction && movement.fromLocationId != null) {
          developer.log('Processing reduction movement from location ${movement.fromLocationId}');
          final existingStock = await getStockInTransaction(
            movement.productId,
            movement.fromLocationId!,
            batchNumber: movement.batchNumber,
          );
          
          if (existingStock != null) {
            final newQuantity = existingStock.quantity - movement.quantity;
            if (newQuantity > 0) {
              await txn.update(
                'stock',
                existingStock.copyWith(quantity: newQuantity).toMap(),
                where: 'id = ?',
                whereArgs: [existingStock.id],
              );
            } else {
              await txn.delete('stock', where: 'id = ?', whereArgs: [existingStock.id]);
            }
          }
        } else if (movement.type == MovementType.adjustment) {
          developer.log('Processing adjustment movement');
          if (movement.toLocationId != null) {
            final existingStock = await getStockInTransaction(
              movement.productId,
              movement.toLocationId!,
              batchNumber: movement.batchNumber,
            );
            
            if (existingStock != null) {
              developer.log('Updating stock quantity to ${movement.quantity}');
              await txn.update(
                'stock',
                existingStock.copyWith(quantity: movement.quantity).toMap(),
                where: 'id = ?',
                whereArgs: [existingStock.id],
              );
            } else {
              developer.log('Creating new stock record for adjustment');
              await txn.insert('stock', Stock(
                productId: movement.productId,
                locationId: movement.toLocationId!,
                quantity: movement.quantity,
                batchNumber: movement.batchNumber,
              ).toMap());
            }
          }
        } else if (movement.type == MovementType.transfer) {
          developer.log('Processing transfer movement from ${movement.fromLocationId} to ${movement.toLocationId}');
          // Reduce from source location
          if (movement.fromLocationId != null) {
            final fromStock = await getStockInTransaction(
              movement.productId,
              movement.fromLocationId!,
              batchNumber: movement.batchNumber,
            );
            
            if (fromStock != null) {
              final newQuantity = fromStock.quantity - movement.quantity;
              if (newQuantity > 0) {
                await txn.update(
                  'stock',
                  fromStock.copyWith(quantity: newQuantity).toMap(),
                  where: 'id = ?',
                  whereArgs: [fromStock.id],
                );
              } else {
                await txn.delete('stock', where: 'id = ?', whereArgs: [fromStock.id]);
              }
            }
          }
          
          // Add to destination location
          if (movement.toLocationId != null) {
            final toStock = await getStockInTransaction(
              movement.productId,
              movement.toLocationId!,
              batchNumber: movement.batchNumber,
            );
            
            if (toStock != null) {
              await txn.update(
                'stock',
                toStock.copyWith(
                  quantity: toStock.quantity + movement.quantity,
                ).toMap(),
                where: 'id = ?',
                whereArgs: [toStock.id],
              );
            } else {
              await txn.insert('stock', Stock(
                productId: movement.productId,
                locationId: movement.toLocationId!,
                quantity: movement.quantity,
                batchNumber: movement.batchNumber,
              ).toMap());
            }
          }
        }
        
        developer.log('Transaction completed successfully');
      });
      
      developer.log('Updating product quantity');
      // Update product's currentQuantity to reflect total stock across all locations
      await _syncProductQuantity(movement.productId);
      
      developer.log('Reloading stock and movements');
      await loadStock();
      await loadMovements();
      
      developer.log('Movement recording completed successfully');
      return true;
    } catch (e, stackTrace) {
      developer.log('Error recording movement', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to record movement: ${e.toString()}';
      notifyListeners();
      return false;
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

  List<Stock> getStockByLocation(int locationId) {
    return _stock.where((s) => s.locationId == locationId).toList();
  }

  List<Stock> getStockByProduct(int productId) {
    return _stock.where((s) => s.productId == productId).toList();
  }

  // Calculate total stock quantity across all locations
  double get totalStockQuantity {
    return _stock.fold<double>(0, (sum, stock) => sum + stock.quantity);
  }

  // Get unique products with low stock (not individual stock records)
  List<int> getLowStockProductIds() {
    final lowStockItems = getLowStockItems();
    return lowStockItems.map((s) => s.productId).toSet().toList();
  }

  // Get unique products expiring soon (not individual stock records)
  List<int> getExpiringSoonProductIds() {
    final expiringItems = getExpiringSoonItems();
    return expiringItems.map((s) => s.productId).toSet().toList();
  }

  // Sync product's currentQuantity with actual stock totals
  Future<void> _syncProductQuantity(int productId) async {
    try {
      // Get all stock for this product
      final stockItems = await _db.getStockByProduct(productId);
      final totalQuantity = stockItems.fold<double>(0, (sum, stock) => sum + stock.quantity);
      
      // Get the product
      final product = await _db.getProductById(productId);
      if (product != null) {
        // Update product's currentQuantity
        final updatedProduct = product.copyWith(currentQuantity: totalQuantity);
        await _db.updateProduct(updatedProduct);
      }
    } catch (e, stackTrace) {
      developer.log('Error syncing product quantity', error: e, stackTrace: stackTrace);
      // Don't throw - this is a background sync operation
    }
  }
}

