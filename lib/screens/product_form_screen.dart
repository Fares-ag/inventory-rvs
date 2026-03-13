import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/image_helper.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _partNumberController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _currentQuantityController = TextEditingController();
  final TextEditingController _unitCostController = TextEditingController();
  final TextEditingController _minimumStockController = TextEditingController();
  final TextEditingController _maximumStockController = TextEditingController();
  final TextEditingController _warrantyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCategory;
  String? _selectedUnit;
  String? _selectedLocationId;
  String? _imagePath; // Legacy support
  List<String> _imagePaths = []; // Multiple images

  static const List<String> _categories = [
    'Spare Parts',
    'Consumables',
    'Tools',
    'Safety Equipment',
    'Cleaning Supplies',
    'Office Supplies',
    'Electrical',
    'Mechanical',
    'Other',
  ];

  static const List<String> _units = [
    'pieces',
    'kg',
    'litres',
    'meters',
    'boxes',
    'packs',
    'rolls',
    'sheets',
    'units',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController.text = p?.name ?? '';
    _selectedCategory = p?.category;
    _selectedUnit = p?.unitOfMeasurement ?? 'pieces';
    _descriptionController.text = p?.description ?? '';
    _skuController.text = p?.sku ?? '';
    _partNumberController.text = p?.partNumber ?? '';
    _manufacturerController.text = p?.manufacturer ?? '';
    _supplierController.text = p?.supplier ?? '';
    _currentQuantityController.text = p?.currentQuantity?.toString() ?? '';
    _unitCostController.text = p?.unitCost?.toString() ?? '';
    _minimumStockController.text = p?.minimumStock?.toString() ?? '';
    _maximumStockController.text = p?.maximumStock?.toString() ?? '';
    _selectedLocationId = p?.locationId; // Already String?
    _warrantyController.text = p?.warranty ?? '';
    _notesController.text = p?.notes ?? '';
    _imagePath = p?.imagePath; // Legacy
    _imagePaths = p?.imagePaths ?? (p?.imagePath != null ? [p!.imagePath!] : []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _partNumberController.dispose();
    _manufacturerController.dispose();
    _supplierController.dispose();
    _currentQuantityController.dispose();
    _unitCostController.dispose();
    _minimumStockController.dispose();
    _maximumStockController.dispose();
    _warrantyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      unitOfMeasurement: _selectedUnit!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sku: _skuController.text.trim(),
      partNumber: _partNumberController.text.trim().isEmpty
          ? null
          : _partNumberController.text.trim(),
      manufacturer: _manufacturerController.text.trim().isEmpty
          ? null
          : _manufacturerController.text.trim(),
      supplier: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
      // currentQuantity is now auto-calculated from Stock table, so we don't set it here
      // It will be synced automatically when stock is added/updated
      currentQuantity: null,
      unitCost: _unitCostController.text.isEmpty
          ? null
          : double.tryParse(_unitCostController.text),
      minimumStock: _minimumStockController.text.isEmpty
          ? null
          : double.tryParse(_minimumStockController.text),
      maximumStock: _maximumStockController.text.isEmpty
          ? null
          : double.tryParse(_maximumStockController.text),
      locationId: _selectedLocationId,
      warranty: _warrantyController.text.trim().isEmpty
          ? null
          : _warrantyController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      imagePath: _imagePath, // Keep for backward compatibility
      imagePaths: _imagePaths.isNotEmpty ? _imagePaths : null,
    );

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final success = widget.product == null
        ? await productProvider.addProduct(product)
        : await productProvider.updateProduct(product);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(widget.product == null
                  ? 'Product added successfully'
                  : 'Product updated successfully'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Error saving product'),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: Responsive.getScreenPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              // Product Images Gallery
              _buildImageGallerySection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'Enter product name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Select category',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit *',
                  hintText: 'Select unit',
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select unit';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() => _selectedUnit = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Identification
              _buildSectionHeader('Identification'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU *',
                  hintText: 'Enter SKU',
                ),
                enabled: widget.product == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter SKU';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partNumberController,
                decoration: const InputDecoration(
                  labelText: 'Part Number',
                  hintText: 'Enter part number',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer',
                  hintText: 'Enter manufacturer name',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  hintText: 'Enter supplier name',
                ),
              ),
              const SizedBox(height: 24),
              // Stock & Costs
              _buildSectionHeader('Stock & Costs'),
              const SizedBox(height: 16),
              // Current Quantity is auto-calculated from Stock table
              Builder(
                builder: (context) {
                  if (widget.product?.id == null) {
                    return TextFormField(
                      controller: _currentQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Initial Quantity (Optional)',
                        hintText: 'Will be calculated from stock movements',
                        helperText: 'This field is optional. Quantity will be calculated from stock movements.',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: false, // Disabled - calculated from stock
                    );
                  }
                  
                  return Consumer<firebase_stock.StockProvider>(
                    builder: (context, stockProvider, _) {
                      final productId = widget.product?.id;
                      if (productId == null) {
                        return TextFormField(
                          controller: _currentQuantityController,
                          decoration: const InputDecoration(
                            labelText: 'Initial Quantity (Optional)',
                            hintText: 'Will be calculated from stock movements',
                            helperText: 'This field is optional. Quantity will be calculated from stock movements.',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: false,
                        );
                      }
                      final stockItems = stockProvider.getStockByProduct(productId);
                      final totalQuantity = stockItems.fold<double>(0, (sum, stock) => sum + stock.quantity);
                      
                      return TextFormField(
                        controller: TextEditingController(text: totalQuantity.toStringAsFixed(0)),
                        decoration: InputDecoration(
                          labelText: 'Current Quantity (Auto-calculated)',
                          helperText: 'Calculated from stock across all locations',
                          suffixIcon: Icon(Icons.calculate, color: Colors.grey.shade400),
                        ),
                        enabled: false, // Read-only - calculated from stock
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitCostController,
                decoration: const InputDecoration(
                  labelText: 'Unit Cost (QAR)',
                  hintText: 'Enter unit cost in QAR',
                  prefixText: 'QAR ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (Responsive.isMobile(context)) {
                    return Column(
                      children: [
                        TextFormField(
                          controller: _minimumStockController,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Stock',
                            hintText: 'Min',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _maximumStockController,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Stock',
                            hintText: 'Max',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minimumStockController,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Stock',
                            hintText: 'Min',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _maximumStockController,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Stock',
                            hintText: 'Max',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Location Section
              _buildSectionHeader('Location'),
              const SizedBox(height: 16),
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Select location',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No location'),
                      ),
                      ...locationProvider.locations.map((location) {
                        return DropdownMenuItem<String?>(
                          value: location.id,
                          child: Text(location.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedLocationId = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              // Additional Information
              _buildSectionHeader('Additional Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _warrantyController,
                decoration: const InputDecoration(
                  labelText: 'Warranty',
                  hintText: 'Enter warranty information',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Enter any additional notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: Responsive.getButtonHeight(context),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.product == null ? 'Create Product' : 'Update Product',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Product Images',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${_imagePaths.length} image${_imagePaths.length != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Image Grid
        if (_imagePaths.isEmpty)
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildImagePlaceholder(),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _imagePaths.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == _imagePaths.length) {
                // Add image button
                return GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey.shade600),
                        const SizedBox(height: 4),
                        Text(
                          'Add',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final imagePath = _imagePaths[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:                     (imagePath.startsWith('http://') || imagePath.startsWith('https://'))
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                              );
                            },
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                              );
                            },
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImageAt(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
            if (_imagePaths.isNotEmpty)
              TextButton.icon(
                onPressed: _clearAllImages,
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                label: const Text('Clear All', style: TextStyle(color: AppTheme.errorColor)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add product photo',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final imagePath = await ImageHelper.pickAndSaveImage();
      if (imagePath != null && mounted) {
        setState(() {
          _imagePaths.add(imagePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imagePath = await ImageHelper.takePhoto();
      if (imagePath != null && mounted) {
        setState(() {
          _imagePaths.add(imagePath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _clearAllImages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Images'),
        content: const Text('Are you sure you want to remove all images?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _imagePaths.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
