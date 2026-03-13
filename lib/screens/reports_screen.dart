import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';
import '../widgets/stat_card.dart';
import 'reports_screen_movement.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<firebase_stock.StockProvider, ProductProvider, LocationProvider>(
      builder: (context, stockProvider, productProvider, locationProvider, _) {
        final lowStockItems = stockProvider.getLowStockItems();
        final overstockItems = stockProvider.getOverstockItems();
        final expiringSoonItems = stockProvider.getExpiringSoonItems();

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Reports & Analytics'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () async {
                    await Future.wait([
                      stockProvider.loadStock(),
                      stockProvider.loadMovements(),
                      productProvider.loadProducts(),
                      locationProvider.loadLocations(),
                    ]);
                  },
                  tooltip: 'Refresh',
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: Icon(Icons.dashboard_rounded), text: 'Summary'),
                  Tab(icon: Icon(Icons.warehouse_rounded), text: 'Current Stock'),
                  Tab(icon: Icon(Icons.warning_rounded), text: 'Low Stock'),
                  Tab(icon: Icon(Icons.trending_up_rounded), text: 'Overstock'),
                  Tab(icon: Icon(Icons.schedule_rounded), text: 'Expiring'),
                  Tab(icon: Icon(Icons.history_rounded), text: 'Movements'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _SummaryReport(
                  stockProvider: stockProvider,
                  productProvider: productProvider,
                  locationProvider: locationProvider,
                  lowStockItems: lowStockItems,
                  overstockItems: overstockItems,
                  expiringSoonItems: expiringSoonItems,
                ),
                _CurrentStockReport(
                  stock: stockProvider.stock,
                  productProvider: productProvider,
                  locationProvider: locationProvider,
                ),
                _LowStockReport(
                  items: lowStockItems,
                  productProvider: productProvider,
                  locationProvider: locationProvider,
                ),
                _OverstockReport(
                  items: overstockItems,
                  productProvider: productProvider,
                  locationProvider: locationProvider,
                ),
                _ExpiringReport(
                  items: expiringSoonItems,
                  productProvider: productProvider,
                  locationProvider: locationProvider,
                ),
                MovementHistoryReport(
                  movements: stockProvider.movements,
                  productProvider: productProvider,
                  locationProvider: locationProvider,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryReport extends StatelessWidget {
  final firebase_stock.StockProvider stockProvider;
  final ProductProvider productProvider;
  final LocationProvider locationProvider;
  final List<Stock> lowStockItems;
  final List<Stock> overstockItems;
  final List<Stock> expiringSoonItems;

  const _SummaryReport({
    required this.stockProvider,
    required this.productProvider,
    required this.locationProvider,
    required this.lowStockItems,
    required this.overstockItems,
    required this.expiringSoonItems,
  });

  @override
  Widget build(BuildContext context) {
    final totalStockValue = stockProvider.stock.fold<double>(
      0,
      (sum, stock) {
        final product = productProvider.getProductById(stock.productId);
        final unitCost = product?.unitCost ?? 0;
        return sum + (stock.quantity * unitCost);
      },
    );

    final lowStockValue = lowStockItems.fold<double>(
      0,
      (sum, stock) {
        final product = productProvider.getProductById(stock.productId);
        final unitCost = product?.unitCost ?? 0;
        return sum + (stock.quantity * unitCost);
      },
    );

    final expiringValue = expiringSoonItems.fold<double>(
      0,
      (sum, stock) {
        final product = productProvider.getProductById(stock.productId);
        final unitCost = product?.unitCost ?? 0;
        return sum + (stock.quantity * unitCost);
      },
    );

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          stockProvider.loadStock(),
          productProvider.loadProducts(),
          locationProvider.loadLocations(),
        ]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview Statistics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate optimal aspect ratio based on available width
                final screenWidth = MediaQuery.of(context).size.width;
                final padding = 8.0 * 2; // Left and right padding (minimal for maximum width)
                final spacing = 8.0; // Grid spacing between cards (minimal for maximum width)
                final cardWidth = (screenWidth - padding - spacing) / 2;
                // Use a shorter height multiplier to make cards wider
                final cardHeight = cardWidth * 1.0; // Even shorter height for wider appearance
                final aspectRatio = cardWidth / cardHeight;
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: aspectRatio,
                  children: [
                    StatCard(
                      title: 'Total Products',
                      value: productProvider.products.length.toString(),
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    StatCard(
                      title: 'Total Stock',
                      value: stockProvider.totalStockQuantity.toStringAsFixed(0),
                      icon: Icons.warehouse_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    StatCard(
                      title: 'Total Value',
                      value: 'QAR ${totalStockValue.toStringAsFixed(2)}',
                      icon: Icons.attach_money_rounded,
                      color: AppTheme.successColor,
                    ),
                    StatCard(
                      title: 'Locations',
                      value: locationProvider.locations.length.toString(),
                      icon: Icons.location_on_rounded,
                      color: AppTheme.secondaryColor,
                    ),
                    StatCard(
                      title: 'Low Stock Alerts',
                      value: stockProvider.getLowStockProductIds().length.toString(),
                      icon: Icons.warning_rounded,
                      color: AppTheme.warningColor,
                    ),
                    StatCard(
                      title: 'Low Stock Value',
                      value: 'QAR ${lowStockValue.toStringAsFixed(2)}',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                    ),
                    StatCard(
                      title: 'Overstock Items',
                      value: overstockItems.length.toString(),
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.infoColor,
                    ),
                    StatCard(
                      title: 'Expiring Items',
                      value: stockProvider.getExpiringSoonProductIds().length.toString(),
                      icon: Icons.schedule_rounded,
                      color: AppTheme.errorColor,
                    ),
                    StatCard(
                      title: 'Expiring Value',
                      value: 'QAR ${expiringValue.toStringAsFixed(2)}',
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.errorColor,
                    ),
                    StatCard(
                      title: 'Total Movements',
                      value: stockProvider.movements.length.toString(),
                      icon: Icons.swap_horiz_rounded,
                      color: AppTheme.accentColor,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentStockReport extends StatelessWidget {
  final List<Stock> stock;
  final ProductProvider productProvider;
  final LocationProvider locationProvider;

  const _CurrentStockReport({
    required this.stock,
    required this.productProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (stock.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No stock data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Group stock by product
    final Map<String, List<Stock>> stockByProduct = {};
    for (final s in stock) {
      stockByProduct.putIfAbsent(s.productId, () => []).add(s);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView.builder(
        padding: Responsive.getScreenPadding(context),
        itemCount: stockByProduct.length,
        itemBuilder: (context, index) {
          final productId = stockByProduct.keys.elementAt(index);
          final productStocks = stockByProduct[productId]!;
          final product = productProvider.getProductById(productId);
          final totalQuantity = productStocks.fold<double>(
            0,
            (sum, stock) => sum + stock.quantity,
          );

          return ModernCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product?.name ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${totalQuantity.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (product?.sku != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${product!.sku}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                ...productStocks.map((s) {
                  final location = locationProvider.getLocationById(s.locationId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location?.name ?? 'Unknown Location',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${s.quantity.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (s.batchNumber != null) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('Batch: ${s.batchNumber}'),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LowStockReport extends StatelessWidget {
  final List<Stock> items;
  final ProductProvider productProvider;
  final LocationProvider locationProvider;

  const _LowStockReport({
    required this.items,
    required this.productProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No low stock alerts',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView.builder(
        padding: Responsive.getScreenPadding(context),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final stock = items[index];
          final product = productProvider.getProductById(stock.productId);
          final location = locationProvider.getLocationById(stock.locationId);
          final deficit = (stock.minimumThreshold ?? 0) - stock.quantity;

          return ModernCard(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppTheme.warningColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product?.name ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Location',
                        location?.name ?? 'Unknown',
                        Icons.location_on_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Current',
                        '${stock.quantity.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Minimum',
                        '${stock.minimumThreshold?.toStringAsFixed(0) ?? 'N/A'} ${product?.unitOfMeasurement ?? ''}',
                        Icons.trending_down_outlined,
                      ),
                    ),
                    if (deficit > 0)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Deficit',
                          '${deficit.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                          Icons.remove_circle_outline,
                          color: AppTheme.errorColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _OverstockReport extends StatelessWidget {
  final List<Stock> items;
  final ProductProvider productProvider;
  final LocationProvider locationProvider;

  const _OverstockReport({
    required this.items,
    required this.productProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No overstock alerts',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView.builder(
        padding: Responsive.getScreenPadding(context),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final stock = items[index];
          final product = productProvider.getProductById(stock.productId);
          final location = locationProvider.getLocationById(stock.locationId);
          final excess = stock.quantity - (stock.maximumThreshold ?? 0);

          return ModernCard(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppTheme.infoColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: AppTheme.infoColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product?.name ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Location',
                        location?.name ?? 'Unknown',
                        Icons.location_on_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Current',
                        '${stock.quantity.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Maximum',
                        '${stock.maximumThreshold?.toStringAsFixed(0) ?? 'N/A'} ${product?.unitOfMeasurement ?? ''}',
                        Icons.trending_up_outlined,
                      ),
                    ),
                    if (excess > 0)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Excess',
                          '${excess.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                          Icons.add_circle_outline,
                          color: AppTheme.warningColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _ExpiringReport extends StatelessWidget {
  final List<Stock> items;
  final ProductProvider productProvider;
  final LocationProvider locationProvider;

  const _ExpiringReport({
    required this.items,
    required this.productProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No items expiring soon',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Sort by expiry date (soonest first)
    final sortedItems = List<Stock>.from(items)
      ..sort((a, b) {
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView.builder(
        padding: Responsive.getScreenPadding(context),
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          final stock = sortedItems[index];
          final product = productProvider.getProductById(stock.productId);
          final location = locationProvider.getLocationById(stock.locationId);
          final daysUntilExpiry = stock.expiryDate!.difference(DateTime.now()).inDays;
          final isUrgent = daysUntilExpiry <= 7;

          return ModernCard(
            margin: const EdgeInsets.only(bottom: 16),
            color: isUrgent
                ? AppTheme.errorColor.withOpacity(0.05)
                : AppTheme.warningColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isUrgent ? AppTheme.errorColor : AppTheme.warningColor)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: isUrgent ? AppTheme.errorColor : AppTheme.warningColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product?.name ?? 'Unknown Product',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isUrgent ? AppTheme.errorColor : AppTheme.warningColor)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$daysUntilExpiry days',
                        style: TextStyle(
                          color: isUrgent ? AppTheme.errorColor : AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Location',
                        location?.name ?? 'Unknown',
                        Icons.location_on_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Quantity',
                        '${stock.quantity.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                        Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  context,
                  'Expiry Date',
                  DateFormat('yyyy-MM-dd').format(stock.expiryDate!),
                  Icons.calendar_today_outlined,
                  color: isUrgent ? AppTheme.errorColor : AppTheme.warningColor,
                ),
                if (stock.batchNumber != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    context,
                    'Batch Number',
                    stock.batchNumber!,
                    Icons.qr_code_outlined,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
