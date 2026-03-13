import 'package:flutter/material.dart';
import '../models/product_variant.dart';
import '../database/database_helper.dart';

class ProductVariantsScreen extends StatefulWidget {
  final int productId;

  const ProductVariantsScreen({super.key, required this.productId});

  @override
  State<ProductVariantsScreen> createState() => _ProductVariantsScreenState();
}

class _ProductVariantsScreenState extends State<ProductVariantsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<ProductVariant> _variants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    setState(() => _isLoading = true);
    _variants = await _db.getProductVariants(widget.productId);
    setState(() => _isLoading = false);
  }

  Future<void> _addVariant() async {
    final variant = await showDialog<ProductVariant>(
      context: context,
      builder: (context) => _VariantFormDialog(productId: widget.productId),
    );

    if (variant != null) {
      await _db.insertProductVariant(variant);
      await _loadVariants();
    }
  }

  Future<void> _editVariant(ProductVariant variant) async {
    final updated = await showDialog<ProductVariant>(
      context: context,
      builder: (context) => _VariantFormDialog(variant: variant),
    );

    if (updated != null) {
      await _db.updateProductVariant(updated);
      await _loadVariants();
    }
  }

  Future<void> _deleteVariant(ProductVariant variant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Variant'),
        content: const Text('Are you sure you want to delete this variant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteProductVariant(variant.id!);
      await _loadVariants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Variants'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _variants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.style, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No variants yet'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addVariant,
                        child: const Text('Add First Variant'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _variants.length,
                  itemBuilder: (context, index) {
                    final variant = _variants[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        title: Text(variant.displayName),
                        subtitle: variant.variantSku != null
                            ? Text('SKU: ${variant.variantSku}')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editVariant(variant),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteVariant(variant),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVariant,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VariantFormDialog extends StatefulWidget {
  final int? productId;
  final ProductVariant? variant;

  const _VariantFormDialog({this.productId, this.variant});

  @override
  State<_VariantFormDialog> createState() => _VariantFormDialogState();
}

class _VariantFormDialogState extends State<_VariantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _sizeController;
  late TextEditingController _colorController;
  late TextEditingController _materialController;
  late TextEditingController _styleController;
  late TextEditingController _skuController;

  @override
  void initState() {
    super.initState();
    final v = widget.variant;
    _sizeController = TextEditingController(text: v?.size ?? '');
    _colorController = TextEditingController(text: v?.color ?? '');
    _materialController = TextEditingController(text: v?.material ?? '');
    _styleController = TextEditingController(text: v?.style ?? '');
    _skuController = TextEditingController(text: v?.variantSku ?? '');
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    _styleController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final variant = ProductVariant(
      id: widget.variant?.id,
      productId: widget.productId ?? widget.variant!.productId,
      size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
      color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      material: _materialController.text.trim().isEmpty
          ? null
          : _materialController.text.trim(),
      style: _styleController.text.trim().isEmpty ? null : _styleController.text.trim(),
      variantSku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
    );

    Navigator.pop(context, variant);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.variant == null ? 'Add Variant' : 'Edit Variant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _styleController,
                decoration: const InputDecoration(
                  labelText: 'Style',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'Variant SKU (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

