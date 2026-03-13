import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/location.dart';
import '../services/firestore_service.dart';

class LocationProvider with ChangeNotifier {
  final FirestoreService _firestore = FirestoreService.instance;
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LocationProvider() {
    // Listen to real-time updates
    _firestore.getLocationsStream().listen((locationsData) {
      _locations = locationsData.map((data) => Location.fromMap(data)).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      developer.log('Error in locations stream', error: e);
      _errorMessage = 'Failed to load locations: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> loadLocations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final locationsData = await _firestore.getAllLocations();
      _locations = locationsData.map((data) => Location.fromMap(data)).toList();
      _errorMessage = null;
    } catch (e, stackTrace) {
      developer.log('Error loading locations', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to load locations: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addLocation(Location location) async {
    try {
      final locationData = location.toMap();
      await _firestore.addLocation(locationData);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error adding location', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to add location: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLocation(Location location) async {
    try {
      if (location.id == null) return false;
      final locationData = location.toMap();
      await _firestore.updateLocation(location.id!, locationData);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error updating location', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to update location: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLocation(String id) async {
    try {
      await _firestore.deleteLocation(id);
      return true;
    } catch (e, stackTrace) {
      developer.log('Error deleting location', error: e, stackTrace: stackTrace);
      _errorMessage = 'Failed to delete location: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Location? getLocationById(String id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }
}

