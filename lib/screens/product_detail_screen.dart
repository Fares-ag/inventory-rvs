import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';
import 'product_form_screen.dart';
import 'stock_form_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        // Get the latest product data from provider
        final updatedProduct = product.id != null
            ? productProvider.getProductById(product.id!)
            : product;
        final currentProduct = updatedProduct ?? product;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(currentProduct.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormScreen(product: currentProduct),
                      ),
                    );
                    // Reload products to get latest data
                    if (context.mounted) {
                      productProvider.loadProducts();
                    }
                  },
                  tooltip: 'Edit Product',
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.info_outline_rounded), text: 'Details'),
                  Tab(icon: Icon(Icons.warehouse_outlined), text: 'Stock'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ProductDetailsTab(product: currentProduct),
                _ProductStockTab(product: currentProduct),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductDetailsTab extends StatefulWidget {
  final Product product;

  const _ProductDetailsTab({required this.product});

  @override
  State<_ProductDetailsTab> createState() => _ProductDetailsTabState();
}

class _ProductDetailsTabState extends State<_ProductDetailsTab> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Images Gallery
          _buildImageGallery(context),
          // Basic Information
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(context, 'Item Name', widget.product.name),
                _buildInfoRow(context, 'SKU', widget.product.sku),
                if (widget.product.category != null)
                  _buildInfoRow(context, 'Category', widget.product.category!),
                _buildInfoRow(context, 'Unit', widget.product.unitOfMeasurement),
                if (widget.product.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          // Identification
          const SizedBox(height: 16),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identification',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                if (widget.product.partNumber != null)
                  _buildInfoRow(context, 'Part Number', widget.product.partNumber!),
                if (widget.product.manufacturer != null)
                  _buildInfoRow(context, 'Manufacturer', widget.product.manufacturer!),
                if (widget.product.supplier != null)
                  _buildInfoRow(context, 'Supplier', widget.product.supplier!),
              ],
            ),
          ),
          // Stock & Costs
          Consumer<firebase_stock.StockProvider>(
            builder: (context, stockProvider, _) {
              final stockItems = stockProvider.getStockByProduct(widget.product.id ?? '');
              final totalQuantity = stockItems.fold<double>(0, (sum, stock) => sum + stock.quantity);
              final hasStockInfo = totalQuantity > 0 || widget.product.unitCost != null || widget.product.minimumStock != null || widget.product.maximumStock != null;
              
              if (!hasStockInfo) return const SizedBox.shrink();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock & Costs',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        // Show calculated quantity from Stock table
                        _buildInfoRow(
                          context,
                          'Current Quantity',
                          '${totalQuantity.toStringAsFixed(0)} ${widget.product.unitOfMeasurement}',
                        ),
                        if (widget.product.unitCost != null)
                          _buildInfoRow(
                            context,
                            'Unit Cost',
                            'QAR ${widget.product.unitCost!.toStringAsFixed(2)}',
                          ),
                        if (widget.product.minimumStock != null)
                          _buildInfoRow(
                            context,
                            'Minimum Stock',
                            '${widget.product.minimumStock!.toStringAsFixed(0)} ${widget.product.unitOfMeasurement}',
                          ),
                        if (widget.product.maximumStock != null)
                          _buildInfoRow(
                            context,
                            'Maximum Stock',
                            '${widget.product.maximumStock!.toStringAsFixed(0)} ${widget.product.unitOfMeasurement}',
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Location
          if (widget.product.locationId != null) ...[
            const SizedBox(height: 16),
            Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                final location = locationProvider.getLocationById(widget.product.locationId ?? '');
                return ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        'Location',
                        location?.name ?? 'Unknown',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          // Additional Information
          if (widget.product.warranty != null || widget.product.notes != null) ...[
            const SizedBox(height: 16),
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.product.warranty != null)
                    _buildInfoRow(context, 'Warranty', widget.product.warranty!),
                  if (widget.product.notes != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    final images = widget.product.allImages;
    
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    
    if (images.length == 1) {
      // Single image - show large
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernCard(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (images.first.startsWith('http://') || images.first.startsWith('https://'))
                  ? Image.network(
                      images.first,
                      fit: BoxFit.cover,
                      height: 300,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    )
                  : Image.file(
                      File(images.first),
                      fit: BoxFit.cover,
                      height: 300,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
    
    // Multiple images - show carousel
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product Images',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${images.length} images',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imagePath = images[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (imagePath.startsWith('http://') || imagePath.startsWith('https://'))
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey.shade400),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey.shade400),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Image indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductStockTab extends StatelessWidget {
  final Product product;

  const _ProductStockTab({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer2<firebase_stock.StockProvider, LocationProvider>(
      builder: (context, stockProvider, locationProvider, _) {
        final stockItems = stockProvider.getStockByProduct(product.id ?? '');

        return Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              color: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate optimal aspect ratio based on available width
                  final screenWidth = MediaQuery.of(context).size.width;
                  final padding = 8.0 * 2; // Left and right padding
                  final spacing = 8.0; // Grid spacing between cards
                  final cardWidth = (screenWidth - padding - spacing) / 2;
                  // Use a taller height multiplier to make cards take less vertical space
                  final cardHeight = cardWidth * 0.7; // Shorter height to take less space
                  final aspectRatio = cardWidth / cardHeight;
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: aspectRatio,
                    children: [
                      _buildSummaryCard(
                        context,
                        'Total Stock',
                        stockItems.fold<double>(
                          0,
                          (sum, stock) => sum + stock.quantity,
                        ).toStringAsFixed(0),
                        AppTheme.primaryColor,
                        Icons.inventory_2_rounded,
                      ),
                      _buildSummaryCard(
                        context,
                        'Locations',
                        stockItems.length.toString(),
                        AppTheme.secondaryColor,
                        Icons.location_on_rounded,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Stock List
            Expanded(
              child: stockItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warehouse_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No stock records for this product',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StockFormScreen(
                                    initialProductId: product.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Stock'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => stockProvider.loadStock(),
                      child: ListView.builder(
                        padding: Responsive.getScreenPadding(context),
                        itemCount: stockItems.length,
                        itemBuilder: (context, index) {
                          final stock = stockItems[index];
                          final location = locationProvider.getLocationById(stock.locationId);

                          Color? statusColor;
                          IconData? statusIcon;
                          String? statusText;
                          if (stock.isLowStock) {
                            statusColor = AppTheme.warningColor;
                            statusIcon = Icons.warning_rounded;
                            statusText = 'Low Stock';
                          } else if (stock.isOverstock) {
                            statusColor = AppTheme.primaryColor;
                            statusIcon = Icons.trending_up_rounded;
                            statusText = 'Overstock';
                          } else if (stock.isExpiringSoon) {
                            statusColor = AppTheme.errorColor;
                            statusIcon = Icons.schedule_rounded;
                            statusText = 'Expiring Soon';
                          }

                          return ModernCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => StockFormScreen(stock: stock),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: (statusColor ?? AppTheme.primaryColor)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                statusIcon ?? Icons.warehouse_rounded,
                                                color: statusColor ?? AppTheme.primaryColor,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    location?.name ?? 'Unknown Location',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${stock.quantity} ${product.unitOfMeasurement}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (statusText != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor!.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
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
                                              builder: (_) => StockFormScreen(stock: stock),
                                            ),
                                          );
                                        } else if (value == 'delete') {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              title: const Text('Delete Stock'),
                                              content: const Text(
                                                'Are you sure you want to delete this stock record? This action cannot be undone.',
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
                                            await stockProvider.deleteStock(stock.id ?? '');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Row(
                                                    children: [
                                                      Icon(Icons.check_circle, color: Colors.white),
                                                      SizedBox(width: 12),
                                                      Text('Stock deleted successfully'),
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
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (stock.batchNumber != null) ...[
                                      Expanded(
                                        child: _buildInfoChip(
                                          context,
                                          'Batch',
                                          stock.batchNumber!,
                                          AppTheme.secondaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (stock.expiryDate != null)
                                      Expanded(
                                        child: _buildInfoChip(
                                          context,
                                          'Expires',
                                          DateFormat('MMM dd, yyyy')
                                              .format(stock.expiryDate!),
                                          AppTheme.errorColor,
                                        ),
                                      ),
                                  ],
                                ),
                                if (stock.minimumThreshold != null ||
                                    stock.maximumThreshold != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (stock.minimumThreshold != null)
                                        Expanded(
                                          child: _buildInfoChip(
                                            context,
                                            'Min',
                                            stock.minimumThreshold.toString(),
                                            AppTheme.warningColor,
                                          ),
                                        ),
                                      if (stock.minimumThreshold != null &&
                                          stock.maximumThreshold != null)
                                        const SizedBox(width: 8),
                                      if (stock.maximumThreshold != null)
                                        Expanded(
                                          child: _buildInfoChip(
                                            context,
                                            'Max',
                                            stock.maximumThreshold.toString(),
                                            AppTheme.primaryColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
