import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_firebase.dart' as firebase_auth;
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';
import '../widgets/stat_card.dart';
import 'products_screen.dart';
import 'locations_screen.dart';
import 'movements_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';
import 'stock_movement_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final stockProvider = Provider.of<firebase_stock.StockProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    await Future.wait([
      stockProvider.loadStock(),
      stockProvider.loadMovements(),
      productProvider.loadProducts(),
      locationProvider.loadLocations(),
    ]);
  }

  List<Widget> get _screens => const [
    DashboardHome(),
    ProductsScreen(),
    LocationsScreen(),
    MovementsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              const Text('Inventory Management'),
            ],
          ],
        ),
        actions: [
          // Show "Record Movement" button when Movements tab is selected
          if (_selectedIndex == 3)
            Consumer<firebase_auth.AuthProvider>(
              builder: (context, authProvider, _) {
                return IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Record Movement',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StockMovementFormScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          Consumer<firebase_auth.AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  if (authProvider.currentUser?.canManageUsers ?? false)
                    PopupMenuItem(
                      value: 'users',
                      child: const Row(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Manage Users'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 20, color: AppTheme.errorColor),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  } else if (value == 'users') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersScreen()),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      authProvider.currentUser?.username[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Responsive.isMobile(context)
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              elevation: 8,
              height: 70,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on_rounded),
                  label: 'Locations',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_horiz_outlined),
                  selectedIcon: Icon(Icons.swap_horiz_rounded),
                  label: 'Movements',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics_rounded),
                  label: 'Reports',
                ),
              ],
            )
          : null,
      drawer: Responsive.isMobile(context) ? null : _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inventory Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            Icons.dashboard_rounded,
            'Dashboard',
            0,
          ),
          _buildDrawerItem(
            context,
            Icons.inventory_2_rounded,
            'Products',
            1,
          ),
          _buildDrawerItem(
            context,
            Icons.location_on_rounded,
            'Locations',
            2,
          ),
          _buildDrawerItem(
            context,
            Icons.swap_horiz_rounded,
            'Movements',
            3,
          ),
          _buildDrawerItem(
            context,
            Icons.analytics_rounded,
            'Reports',
            4,
          ),
          const Divider(),
          Consumer<firebase_auth.AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.currentUser?.canManageUsers ?? false) {
                return ListTile(
                  leading: const Icon(Icons.people_outline_rounded),
                  title: const Text('Manage Users'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersScreen()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
            title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
            onTap: () {
              final authProvider = Provider.of<firebase_auth.AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<firebase_stock.StockProvider, ProductProvider, LocationProvider>(
      builder: (context, stockProvider, productProvider, locationProvider, _) {
        final lowStockItems = stockProvider.getLowStockItems();
        final expiringSoonItems = stockProvider.getExpiringSoonItems();

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
                  'Overview',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
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
                          title: 'Locations',
                          value: locationProvider.locations.length.toString(),
                          icon: Icons.location_on_rounded,
                          color: AppTheme.secondaryColor,
                        ),
                        StatCard(
                          title: 'Total Stock',
                          value: stockProvider.totalStockQuantity.toStringAsFixed(0),
                          icon: Icons.warehouse_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        StatCard(
                          title: 'Total Movements',
                          value: stockProvider.movements.length.toString(),
                          icon: Icons.swap_horiz_rounded,
                          color: AppTheme.accentColor,
                        ),
                        StatCard(
                          title: 'Low Stock Products',
                          value: stockProvider.getLowStockProductIds().length.toString(),
                          icon: Icons.warning_rounded,
                          color: AppTheme.warningColor,
                        ),
                        StatCard(
                          title: 'Expiring Products',
                          value: stockProvider.getExpiringSoonProductIds().length.toString(),
                          icon: Icons.schedule_rounded,
                          color: AppTheme.errorColor,
                        ),
                      ],
                    );
                  },
                ),
                if (lowStockItems.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Low Stock Alerts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to stock screen with filter
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...lowStockItems.take(5).map((stock) {
                    final product = productProvider.getProductById(stock.productId);
                    final location = locationProvider.getLocationById(stock.locationId);
                    return ModernCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
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
                        title: Text(
                          product?.name ?? 'Unknown Product',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${location?.name ?? 'Unknown'} • ${stock.quantity} ${product?.unitOfMeasurement ?? ''}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Min: ${stock.minimumThreshold}',
                            style: const TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                if (expiringSoonItems.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expiring Soon',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to reports
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...expiringSoonItems.take(5).map((stock) {
                    final product = productProvider.getProductById(stock.productId);
                    final location = locationProvider.getLocationById(stock.locationId);
                    final daysUntilExpiry = stock.expiryDate!.difference(DateTime.now()).inDays;
                    return ModernCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          product?.name ?? 'Unknown Product',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${location?.name ?? 'Unknown'} • ${stock.batchNumber ?? 'N/A'}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: daysUntilExpiry <= 7
                                ? AppTheme.errorColor.withOpacity(0.1)
                                : AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$daysUntilExpiry days',
                            style: TextStyle(
                              color: daysUntilExpiry <= 7
                                  ? AppTheme.errorColor
                                  : AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
