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
import '../widgets/modern_card.dart';
import '../widgets/search_bar.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Load stock data when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProvider = Provider.of<firebase_stock.StockProvider>(context, listen: false);
      stockProvider.loadStock();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredProducts {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      return productProvider.products;
    }

    var filtered = productProvider.products;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.sku.toLowerCase().contains(query) ||
            (product.category?.toLowerCase().contains(query) ?? false) ||
            (product.description?.toLowerCase().contains(query) ?? false) ||
            (product.partNumber?.toLowerCase().contains(query) ?? false) ||
            (product.manufacturer?.toLowerCase().contains(query) ?? false) ||
            (product.supplier?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, firebase_stock.StockProvider, LocationProvider>(
      builder: (context, productProvider, stockProvider, locationProvider, _) {
        final filteredProducts = _filteredProducts;
        final categories = productProvider.getCategories();

        return Scaffold(
          body: Column(
            children: [
              ModernSearchBar(
                controller: _searchController,
                hintText: 'Search products by name, SKU, category...',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
                filters: [
                  if (categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_selectedCategory ?? 'Category'),
                        selected: _selectedCategory != null,
                        onSelected: (selected) {
                          if (!selected) {
                            setState(() => _selectedCategory = null);
                          }
                        },
                        avatar: _selectedCategory != null
                            ? const Icon(Icons.close, size: 16)
                            : null,
                      ),
                    ),
                ],
              ),
              if (_selectedCategory != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (_selectedCategory != null)
                              Chip(
                                label: Text('Category: $_selectedCategory'),
                                onDeleted: () => setState(() => _selectedCategory = null),
                                deleteIcon: const Icon(Icons.close, size: 16),
                              ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: productProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedCategory != null
                                      ? 'No products match your search'
                                      : 'No products yet',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                                if (_searchQuery.isEmpty && _selectedCategory == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const ProductFormScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add First Product'),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => productProvider.loadProducts(),
                            child: ListView.builder(
                              padding: Responsive.getScreenPadding(context),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ModernCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(product: product),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      // Product Image/Icon
                                      _buildProductImage(context, product),
                                      const SizedBox(width: 16),
                                      // Product Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'SKU: ${product.sku}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            const SizedBox(height: 4),
                                            _buildStockInfo(context, product, stockProvider, locationProvider),
                                            if (product.category != null) ...[
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  if (product.category != null)
                                                    Chip(
                                                      label: Text(
                                                        product.category!,
                                                        style: const TextStyle(fontSize: 11),
                                                      ),
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      visualDensity: VisualDensity.compact,
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 20),
                                                SizedBox(width: 12),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                                                SizedBox(width: 12),
                                                Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProductFormScreen(product: product),
                                              ),
                                            );
                                          } else if (value == 'delete') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                title: const Text('Delete Product'),
                                                content: const Text(
                                                  'Are you sure you want to delete this product? This action cannot be undone.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppTheme.errorColor,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && context.mounted) {
                                              await productProvider.deleteProduct(product.id!);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Row(
                                                      children: [
                                                        Icon(Icons.check_circle, color: Colors.white),
                                                        SizedBox(width: 12),
                                                        Text('Product deleted successfully'),
                                                      ],
                                                    ),
                                                    backgroundColor: AppTheme.successColor,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: Responsive.isMobile(context)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Product'),
                )
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductFormScreen(),
                      ),
                    );
                  },
                  tooltip: 'Add Product',
                  child: const Icon(Icons.add_rounded),
                ),
        );
      },
    );
  }

  Widget _buildProductImage(BuildContext context, Product product) {
    final firstImage = product.firstImage;
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: firstImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  (firstImage.startsWith('http://') || firstImage.startsWith('https://'))
                      ? Image.network(
                          firstImage,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderIcon();
                          },
                        )
                      : Image.file(
                          File(firstImage),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderIcon();
                          },
                        ),
                  // Show badge if multiple images
                  if (product.allImages.length > 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.allImages.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildStockInfo(
    BuildContext context,
    dynamic product,
    firebase_stock.StockProvider stockProvider,
    LocationProvider locationProvider,
  ) {
    if (product.id == null) return const SizedBox.shrink();
    
    final stockItems = stockProvider.getStockByProduct(product.id!);
    if (stockItems.isEmpty) {
      return Row(
        children: [
          Icon(Icons.warehouse_outlined, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            'No stock',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      );
    }

    final totalStock = stockItems.fold<double>(0, (sum, stock) => sum + stock.quantity);
    final lowStockCount = stockItems.where((s) => s.isLowStock).length;
    final expiringCount = stockItems.where((s) => s.isExpiringSoon).length;

    return Row(
      children: [
        Icon(Icons.warehouse_rounded, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Text(
          '${totalStock.toStringAsFixed(0)} ${product.unitOfMeasurement}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (stockItems.length > 1) ...[
          const SizedBox(width: 8),
          Text(
            'in ${stockItems.length} locations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
        if (lowStockCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_rounded, size: 12, color: AppTheme.warningColor),
                const SizedBox(width: 2),
                Text(
                  '$lowStockCount low',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (expiringCount > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 12, color: AppTheme.errorColor),
                const SizedBox(width: 2),
                Text(
                  '$expiringCount expiring',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
