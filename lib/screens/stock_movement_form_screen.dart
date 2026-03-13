import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth_package;
import 'dart:developer' as developer;
import '../models/stock_movement.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider_firebase.dart' as firebase_auth;

class StockMovementFormScreen extends StatefulWidget {
  final String? productId;
  final String? locationId;

  const StockMovementFormScreen({
    super.key,
    this.productId,
    this.locationId,
  });

  @override
  State<StockMovementFormScreen> createState() => _StockMovementFormScreenState();
}

class _StockMovementFormScreenState extends State<StockMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  MovementType _selectedType = MovementType.addition;
  String? _selectedProductId;
  String? _selectedFromLocationId;
  String? _selectedToLocationId;
  late TextEditingController _quantityController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late TextEditingController _batchController;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.productId;
    _selectedToLocationId = widget.locationId;
    _quantityController = TextEditingController();
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
    _batchController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    final authProvider = Provider.of<firebase_auth.AuthProvider>(context, listen: false);
    
    // Check both currentUser and Firebase Auth
    String userId;
    if (authProvider.currentUser != null && authProvider.currentUser!.id != null) {
      userId = authProvider.currentUser!.id!;
    } else {
      // Fallback to Firebase Auth UID if Firestore user not loaded
      final firebaseAuth = firebase_auth_package.FirebaseAuth.instance;
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated. Please log in again.')),
        );
        return;
      }
    }

    // Validate location requirements based on movement type
    if (_selectedType == MovementType.reduction && _selectedFromLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a from location')),
      );
      return;
    }
    
    if (_selectedType == MovementType.addition && _selectedToLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a to location')),
      );
      return;
    }
    
    if (_selectedType == MovementType.transfer && 
        (_selectedFromLocationId == null || _selectedToLocationId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both from and to locations')),
      );
      return;
    }
    
    if (_selectedType == MovementType.adjustment && _selectedToLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a to location')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity greater than 0')),
      );
      return;
    }

    final movement = StockMovement(
      productId: _selectedProductId!,
      fromLocationId: _selectedFromLocationId,
      toLocationId: _selectedToLocationId,
      type: _selectedType,
      quantity: quantity,
      reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      userId: userId, // Use the userId we determined above
      timestamp: DateTime.now(),
      batchNumber: _batchController.text.isEmpty ? null : _batchController.text,
    );

    final stockProvider = Provider.of<firebase_stock.StockProvider>(context, listen: false);
    
    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    
    bool success = false;
    String? errorMessage;
    
    try {
      success = await stockProvider.recordMovement(movement);
      if (!success) {
        errorMessage = stockProvider.errorMessage ?? 'Unknown error occurred';
      }
    } catch (e) {
      errorMessage = e.toString();
      developer.log('Error in _save', error: e);
    } finally {
      // Always hide loading indicator
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
      }
    }

    if (success && mounted) {
      Navigator.pop(context); // Close the form screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movement recorded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording movement: ${errorMessage ?? "Unknown error"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final product = _selectedProductId != null
        ? productProvider.getProductById(_selectedProductId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Stock Movement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<MovementType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Movement Type *',
                  border: OutlineInputBorder(),
                ),
                items: MovementType.values.map((type) {
                  String label;
                  switch (type) {
                    case MovementType.addition:
                      label = 'Addition (Stock Received)';
                      break;
                    case MovementType.reduction:
                      label = 'Reduction (Usage/Wastage)';
                      break;
                    case MovementType.adjustment:
                      label = 'Adjustment (Manual Correction)';
                      break;
                    case MovementType.transfer:
                      label = 'Transfer (Between Locations)';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _selectedFromLocationId = null;
                    _selectedToLocationId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Product *',
                  border: OutlineInputBorder(),
                ),
                items: productProvider.products.map((product) {
                  return DropdownMenuItem<String?>(
                    value: product.id,
                    child: Text('${product.name} (${product.sku})'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedProductId = value),
                validator: (value) {
                  if (value == null) return 'Please select a product';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == MovementType.reduction ||
                  _selectedType == MovementType.transfer ||
                  _selectedType == MovementType.adjustment)
                DropdownButtonFormField<String?>(
                  initialValue: _selectedFromLocationId,
                  decoration: const InputDecoration(
                    labelText: 'From Location *',
                    border: OutlineInputBorder(),
                  ),
                  items: locationProvider.locations.map((location) {
                    return DropdownMenuItem<String?>(
                      value: location.id,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedFromLocationId = value),
                  validator: (value) {
                    if ((_selectedType == MovementType.reduction ||
                            _selectedType == MovementType.transfer ||
                            _selectedType == MovementType.adjustment) &&
                        value == null) {
                      return 'Please select from location';
                    }
                    return null;
                  },
                ),
              if (_selectedType == MovementType.reduction ||
                  _selectedType == MovementType.transfer ||
                  _selectedType == MovementType.adjustment)
                const SizedBox(height: 16),
              if (_selectedType == MovementType.addition ||
                  _selectedType == MovementType.transfer ||
                  _selectedType == MovementType.adjustment)
                DropdownButtonFormField<String?>(
                  initialValue: _selectedToLocationId,
                  decoration: const InputDecoration(
                    labelText: 'To Location *',
                    border: OutlineInputBorder(),
                  ),
                  items: locationProvider.locations.map((location) {
                    return DropdownMenuItem<String?>(
                      value: location.id,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedToLocationId = value),
                  validator: (value) {
                    if ((_selectedType == MovementType.addition ||
                            _selectedType == MovementType.transfer ||
                            _selectedType == MovementType.adjustment) &&
                        value == null) {
                      return 'Please select to location';
                    }
                    return null;
                  },
                ),
              if (_selectedType == MovementType.addition ||
                  _selectedType == MovementType.transfer ||
                  _selectedType == MovementType.adjustment)
                const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity *',
                  border: const OutlineInputBorder(),
                  suffixText: product?.unitOfMeasurement,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch/Lot Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  helperText: 'e.g., Supplier delivery, Internal usage',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Record Movement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

