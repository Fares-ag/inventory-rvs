import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../utils/responsive.dart';

class StockFormScreen extends StatefulWidget {
  final Stock? stock;
  final String? initialProductId;

  const StockFormScreen({super.key, this.stock, this.initialProductId});

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  String? _selectedLocationId;
  late TextEditingController _quantityController;
  late TextEditingController _minThresholdController;
  late TextEditingController _maxThresholdController;
  late TextEditingController _batchController;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.stock?.quantity.toString() ?? '',
    );
    _minThresholdController = TextEditingController(
      text: widget.stock?.minimumThreshold?.toString() ?? '',
    );
    _maxThresholdController = TextEditingController(
      text: widget.stock?.maximumThreshold?.toString() ?? '',
    );
    _batchController = TextEditingController(
      text: widget.stock?.batchNumber ?? '',
    );
    _selectedProductId = widget.stock?.productId ?? widget.initialProductId;
    _selectedLocationId = widget.stock?.locationId;
    _expiryDate = widget.stock?.expiryDate;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _minThresholdController.dispose();
    _maxThresholdController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select product and location')),
      );
      return;
    }

    final stock = Stock(
      id: widget.stock?.id,
      productId: _selectedProductId!,
      locationId: _selectedLocationId!,
      quantity: double.parse(_quantityController.text),
      minimumThreshold: _minThresholdController.text.isEmpty
          ? null
          : double.parse(_minThresholdController.text),
      maximumThreshold: _maxThresholdController.text.isEmpty
          ? null
          : double.parse(_maxThresholdController.text),
      batchNumber: _batchController.text.isEmpty ? null : _batchController.text,
      expiryDate: _expiryDate,
    );

    final stockProvider = Provider.of<firebase_stock.StockProvider>(context, listen: false);
    final success = widget.stock == null
        ? await stockProvider.addStock(stock)
        : await stockProvider.updateStock(stock);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.stock == null ? 'Stock added' : 'Stock updated'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving stock')),
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
        title: Text(widget.stock == null ? 'Add Stock' : 'Edit Stock'),
      ),
      body: SingleChildScrollView(
        padding: Responsive.getScreenPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                onChanged: widget.stock == null
                    ? (value) => setState(() => _selectedProductId = value)
                    : null,
                validator: (value) {
                  if (value == null) return 'Please select a product';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedLocationId,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                ),
                items: locationProvider.locations.map((location) {
                  return DropdownMenuItem<String?>(
                    value: location.id,
                    child: Text(location.name),
                  );
                }).toList(),
                onChanged: widget.stock == null
                    ? (value) => setState(() => _selectedLocationId = value)
                    : null,
                validator: (value) {
                  if (value == null) return 'Please select a location';
                  return null;
                },
              ),
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
                controller: _minThresholdController,
                decoration: InputDecoration(
                  labelText: 'Minimum Threshold',
                  border: const OutlineInputBorder(),
                  suffixText: product?.unitOfMeasurement,
                  helperText: 'Alert when stock falls below this',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxThresholdController,
                decoration: InputDecoration(
                  labelText: 'Maximum Threshold',
                  border: const OutlineInputBorder(),
                  suffixText: product?.unitOfMeasurement,
                  helperText: 'Alert when stock exceeds this',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date (Optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _expiryDate == null
                        ? 'Select expiry date'
                        : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Stock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

