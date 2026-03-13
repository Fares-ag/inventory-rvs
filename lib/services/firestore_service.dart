import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();

  // Collection references
  CollectionReference get _productsCollection => _firestore.collection('products');
  CollectionReference get _stockCollection => _firestore.collection('stock');
  CollectionReference get _locationsCollection => _firestore.collection('locations');
  CollectionReference get _movementsCollection => _firestore.collection('stock_movements');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get usersCollection => _usersCollection; // Public accessor
  // CollectionReference get _variantsCollection => _firestore.collection('product_variants');

  // Helper method to convert Firestore document to Map
  Map<String, dynamic> _docToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return data;
  }

  // Helper method to convert Timestamp to DateTime
  // DateTime? _timestampToDateTime(dynamic timestamp) {
  //   if (timestamp == null) return null;
  //   if (timestamp is Timestamp) return timestamp.toDate();
  //   if (timestamp is String) return DateTime.parse(timestamp);
  //   return null;
  // }

  // Helper method to convert DateTime to Timestamp
  Timestamp? _dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }

  // Products
  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      // Remove id if present (Firestore generates it)
      productData.remove('id');
      final docRef = await _productsCollection.add(productData);
      return docRef.id;
    } catch (e) {
      developer.log('Error adding product', error: e);
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      productData.remove('id');
      await _productsCollection.doc(id).update(productData);
    } catch (e) {
      developer.log('Error updating product', error: e);
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productsCollection.doc(id).delete();
    } catch (e) {
      developer.log('Error deleting product', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      final doc = await _productsCollection.doc(id).get();
      if (!doc.exists) return null;
      return _docToMap(doc);
    } catch (e) {
      developer.log('Error getting product', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProductBySku(String sku) async {
    try {
      final query = await _productsCollection.where('sku', isEqualTo: sku).limit(1).get();
      if (query.docs.isEmpty) return null;
      return _docToMap(query.docs.first);
    } catch (e) {
      developer.log('Error getting product by SKU', error: e);
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _productsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToMap(doc)).toList());
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final snapshot = await _productsCollection.orderBy('name').get();
      return snapshot.docs.map((doc) => _docToMap(doc)).toList();
    } catch (e) {
      developer.log('Error getting all products', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final searchTerm = query.toLowerCase();
      final snapshot = await _productsCollection.get();
      return snapshot.docs
          .map((doc) => _docToMap(doc))
          .where((product) {
            final name = (product['name'] ?? '').toString().toLowerCase();
            final sku = (product['sku'] ?? '').toString().toLowerCase();
            final category = (product['category'] ?? '').toString().toLowerCase();
            final description = (product['description'] ?? '').toString().toLowerCase();
            return name.contains(searchTerm) ||
                sku.contains(searchTerm) ||
                category.contains(searchTerm) ||
                description.contains(searchTerm);
          })
          .toList();
    } catch (e) {
      developer.log('Error searching products', error: e);
      rethrow;
    }
  }

  // Stock
  Future<String> addStock(Map<String, dynamic> stockData) async {
    try {
      stockData.remove('id');
      final docRef = await _stockCollection.add(stockData);
      return docRef.id;
    } catch (e) {
      developer.log('Error adding stock', error: e);
      rethrow;
    }
  }

  Future<void> updateStock(String id, Map<String, dynamic> stockData) async {
    try {
      stockData.remove('id');
      await _stockCollection.doc(id).update(stockData);
    } catch (e) {
      developer.log('Error updating stock', error: e);
      rethrow;
    }
  }

  Future<void> deleteStock(String id) async {
    try {
      await _stockCollection.doc(id).delete();
    } catch (e) {
      developer.log('Error deleting stock', error: e);
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getStockStream() {
    return _stockCollection.snapshots().map((snapshot) => snapshot.docs.map((doc) => _docToMap(doc)).toList());
  }

  Future<List<Map<String, dynamic>>> getAllStock() async {
    try {
      final snapshot = await _stockCollection.get();
      return snapshot.docs.map((doc) => _docToMap(doc)).toList();
    } catch (e) {
      developer.log('Error getting all stock', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStockByProduct(String productId) async {
    try {
      final snapshot = await _stockCollection.where('product_id', isEqualTo: productId).get();
      return snapshot.docs.map((doc) => _docToMap(doc)).toList();
    } catch (e) {
      developer.log('Error getting stock by product', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStockByLocation(String locationId) async {
    try {
      final snapshot = await _stockCollection.where('location_id', isEqualTo: locationId).get();
      return snapshot.docs.map((doc) => _docToMap(doc)).toList();
    } catch (e) {
      developer.log('Error getting stock by location', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getStock(String productId, String locationId, {String? batchNumber}) async {
    try {
      Query query = _stockCollection
          .where('product_id', isEqualTo: productId)
          .where('location_id', isEqualTo: locationId);

      if (batchNumber != null && batchNumber.isNotEmpty) {
        query = query.where('batch_number', isEqualTo: batchNumber);
      } else {
        query = query.where('batch_number', isNull: true);
      }

      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return _docToMap(snapshot.docs.first);
    } catch (e) {
      developer.log('Error getting stock', error: e);
      rethrow;
    }
  }

  // Locations
  Future<String> addLocation(Map<String, dynamic> locationData) async {
    try {
      locationData.remove('id');
      final docRef = await _locationsCollection.add(locationData);
      return docRef.id;
    } catch (e) {
      developer.log('Error adding location', error: e);
      rethrow;
    }
  }

  Future<void> updateLocation(String id, Map<String, dynamic> locationData) async {
    try {
      locationData.remove('id');
      await _locationsCollection.doc(id).update(locationData);
    } catch (e) {
      developer.log('Error updating location', error: e);
      rethrow;
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _locationsCollection.doc(id).delete();
    } catch (e) {
      developer.log('Error deleting location', error: e);
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getLocationsStream() {
    return _locationsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _docToMap(doc)).toList());
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    try {
      final snapshot = await _locationsCollection.orderBy('name').get();
      return snapshot.docs.map((doc) => _docToMap(doc)).toList();
    } catch (e) {
      developer.log('Error getting all locations', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getLocationById(String id) async {
    try {
      final doc = await _locationsCollection.doc(id).get();
      if (!doc.exists) return null;
      return _docToMap(doc);
    } catch (e) {
      developer.log('Error getting location', error: e);
      rethrow;
    }
  }

  // Stock Movements
  Future<String> addStockMovement(Map<String, dynamic> movementData) async {
    try {
      movementData.remove('id');
      // Convert DateTime to Timestamp
      if (movementData['timestamp'] is DateTime) {
        movementData['timestamp'] = _dateTimeToTimestamp(movementData['timestamp']);
      }
      final docRef = await _movementsCollection.add(movementData);
      return docRef.id;
    } catch (e) {
      developer.log('Error adding stock movement', error: e);
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getMovementsStream() {
    return _movementsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = _docToMap(doc);
        // Convert Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAllStockMovements() async {
    try {
      final snapshot = await _movementsCollection.orderBy('timestamp', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = _docToMap(doc);
        // Convert Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      developer.log('Error getting all stock movements', error: e);
      rethrow;
    }
  }

  Future<void> deleteStockMovement(String id) async {
    try {
      await _movementsCollection.doc(id).delete();
    } catch (e) {
      developer.log('Error deleting stock movement', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStockMovementsByProduct(String productId) async {
    try {
      final snapshot = await _movementsCollection
          .where('product_id', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = _docToMap(doc);
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      developer.log('Error getting stock movements by product', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStockMovementsByLocation(String locationId) async {
    try {
      final snapshot = await _movementsCollection
          .where('from_location_id', isEqualTo: locationId)
          .orderBy('timestamp', descending: true)
          .get();
      final snapshot2 = await _movementsCollection
          .where('to_location_id', isEqualTo: locationId)
          .orderBy('timestamp', descending: true)
          .get();
      
      final allDocs = [...snapshot.docs, ...snapshot2.docs];
      return allDocs.map((doc) {
        final data = _docToMap(doc);
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      developer.log('Error getting stock movements by location', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStockMovementsByUser(String userId) async {
    try {
      final snapshot = await _movementsCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = _docToMap(doc);
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      developer.log('Error getting stock movements by user', error: e);
      rethrow;
    }
  }

  // Batch operations for transactions
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();
      for (final op in operations) {
        final type = op['type'] as String;
        final collection = op['collection'] as String;
        final data = Map<String, dynamic>.from(op['data'] as Map<String, dynamic>);
        final id = op['id'] as String?;

        switch (type) {
          case 'add':
            // Remove 'id' field for new documents (Firestore generates it)
            data.remove('id');
            // Convert DateTime to Timestamp if present
            if (data['timestamp'] is DateTime) {
              data['timestamp'] = _dateTimeToTimestamp(data['timestamp']);
            }
            final ref = _firestore.collection(collection).doc();
            batch.set(ref, data);
            break;
          case 'update':
            if (id != null) {
              // Remove 'id' field from update data
              data.remove('id');
              // Convert DateTime to Timestamp if present
              if (data['timestamp'] is DateTime) {
                data['timestamp'] = _dateTimeToTimestamp(data['timestamp']);
              }
              batch.update(_firestore.collection(collection).doc(id), data);
            }
            break;
          case 'delete':
            if (id != null) {
              batch.delete(_firestore.collection(collection).doc(id));
            }
            break;
        }
      }
      await batch.commit();
    } catch (e) {
      developer.log('Error in batch write', error: e);
      rethrow;
    }
  }
}

