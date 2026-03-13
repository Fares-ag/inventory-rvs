import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';
import '../widgets/search_bar.dart';
import 'stock_form_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String? _selectedLocationId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<firebase_stock.StockProvider, LocationProvider, ProductProvider>(
      builder: (context, stockProvider, locationProvider, productProvider, _) {
        var displayStock = _selectedLocationId == null
            ? stockProvider.stock
            : stockProvider.getStockByLocation(_selectedLocationId!);

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          displayStock = displayStock.where((stock) {
            final product = productProvider.getProductById(stock.productId);
            final nameMatch = product?.name.toLowerCase().contains(query) ?? false;
            final skuMatch = product?.sku.toLowerCase().contains(query) ?? false;
            final batchMatch = stock.batchNumber?.toLowerCase().contains(query) ?? false;
            return nameMatch || skuMatch || batchMatch;
          }).toList();
        }

        return Scaffold(
          body: Column(
            children: [
              ModernSearchBar(
                controller: _searchController,
                hintText: 'Search stock by product name, SKU, batch...',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
              ),
              if (locationProvider.locations.isNotEmpty)
                Container(
                  padding: Responsive.getHorizontalPadding(context).copyWith(top: 8, bottom: 8),
                  color: Colors.white,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedLocationId,
                    decoration: InputDecoration(
                      labelText: 'Filter by Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Locations'),
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
                  ),
                ),
              Expanded(
                child: stockProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayStock.isEmpty
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
                                  _searchQuery.isNotEmpty
                                      ? 'No stock matches your search'
                                      : 'No stock records',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => stockProvider.loadStock(),
                            child: ListView.builder(
                              padding: Responsive.getScreenPadding(context),
                              itemCount: displayStock.length,
                              itemBuilder: (context, index) {
                                final stock = displayStock[index];
                                final product = productProvider.getProductById(stock.productId);
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
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StockFormScreen(stock: stock),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: (statusColor ?? AppTheme.primaryColor).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              statusIcon ?? Icons.inventory_2_rounded,
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
                                                  product?.name ?? 'Unknown Product',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  location?.name ?? 'Unknown Location',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (statusText != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoChip(
                                              context,
                                              'Quantity',
                                              '${stock.quantity} ${product?.unitOfMeasurement ?? ''}',
                                              AppTheme.primaryColor,
                                            ),
                                          ),
                                          if (stock.batchNumber != null) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildInfoChip(
                                                context,
                                                'Batch',
                                                stock.batchNumber!,
                                                AppTheme.secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (stock.expiryDate != null) ...[
                                        const SizedBox(height: 8),
                                        _buildInfoChip(
                                          context,
                                          'Expires',
                                          stock.expiryDate!.toString().split(' ')[0],
                                          AppTheme.errorColor,
                                        ),
                                      ],
                                      if (stock.minimumThreshold != null || stock.maximumThreshold != null) ...[
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
                                            if (stock.minimumThreshold != null && stock.maximumThreshold != null)
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
          ),
          floatingActionButton: Responsive.isMobile(context)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StockFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Stock'),
                )
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StockFormScreen(),
                      ),
                    );
                  },
                  tooltip: 'Add Stock',
                  child: const Icon(Icons.add_rounded),
                ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, Color color) {
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
