import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/stock_provider_firebase.dart' as firebase_stock;
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider_firebase.dart' as firebase_auth;
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';
import '../widgets/search_bar.dart';
import '../models/stock_movement.dart';
import 'stock_movement_form_screen.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MovementType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<firebase_stock.StockProvider, ProductProvider, LocationProvider, firebase_auth.AuthProvider>(
      builder: (context, stockProvider, productProvider, locationProvider, authProvider, _) {
        var movements = stockProvider.movements;

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          movements = movements.where((movement) {
            final product = productProvider.getProductById(movement.productId);
            final nameMatch = product?.name.toLowerCase().contains(query) ?? false;
            final skuMatch = product?.sku.toLowerCase().contains(query) ?? false;
            final reasonMatch = movement.reason?.toLowerCase().contains(query) ?? false;
            final notesMatch = movement.notes?.toLowerCase().contains(query) ?? false;
            return nameMatch || skuMatch || reasonMatch || notesMatch;
          }).toList();
        }

        if (_selectedType != null) {
          final selectedType = _selectedType;
          movements = movements.where((m) => m.type == selectedType).toList();
        }

        return Scaffold(
          body: Column(
            children: [
              ModernSearchBar(
                controller: _searchController,
                hintText: 'Search movements by product, reason, notes...',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
                filters: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PopupMenuButton<MovementType?>(
                      child: FilterChip(
                        label: Text(_getTypeLabel(_selectedType) ?? 'Type'),
                        selected: _selectedType != null,
                        onSelected: (selected) {
                          if (!selected && _selectedType != null) {
                            setState(() => _selectedType = null);
                          }
                        },
                        avatar: _selectedType != null
                            ? const Icon(Icons.close, size: 16)
                            : const Icon(Icons.filter_list, size: 16),
                      ),
                      onSelected: (type) {
                        setState(() => _selectedType = type);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<MovementType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<MovementType?>(
                          value: MovementType.addition,
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_rounded, size: 20, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Addition'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<MovementType?>(
                          value: MovementType.reduction,
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_rounded, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Reduction'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<MovementType?>(
                          value: MovementType.adjustment,
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Adjustment'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<MovementType?>(
                          value: MovementType.transfer,
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 20, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Transfer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Chip(
                          label: Text('Type: ${_getTypeLabel(_selectedType)}'),
                          onDeleted: () => setState(() => _selectedType = null),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: stockProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : movements.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horiz_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedType != null
                                      ? 'No movements match your search'
                                      : 'No stock movements yet',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => stockProvider.loadMovements(),
                            child: ListView.builder(
                              padding: Responsive.getScreenPadding(context),
                              itemCount: movements.length,
                              itemBuilder: (context, index) {
                                final movement = movements[index];
                                final product = productProvider.getProductById(movement.productId);
                                final fromLocation = movement.fromLocationId != null
                                    ? locationProvider.getLocationById(movement.fromLocationId!)
                                    : null;
                                final toLocation = movement.toLocationId != null
                                    ? locationProvider.getLocationById(movement.toLocationId!)
                                    : null;

                                IconData icon;
                                Color color;
                                switch (movement.type) {
                                  case MovementType.addition:
                                    icon = Icons.add_circle_rounded;
                                    color = AppTheme.successColor;
                                    break;
                                  case MovementType.reduction:
                                    icon = Icons.remove_circle_rounded;
                                    color = AppTheme.errorColor;
                                    break;
                                  case MovementType.adjustment:
                                    icon = Icons.edit_rounded;
                                    color = AppTheme.primaryColor;
                                    break;
                                  case MovementType.transfer:
                                    icon = Icons.swap_horiz_rounded;
                                    color = AppTheme.warningColor;
                                    break;
                                }

                                return ModernCard(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(icon, color: color, size: 24),
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
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    movement.typeLabel,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                              '${movement.quantity} ${product?.unitOfMeasurement ?? ''}',
                                              color,
                                            ),
                                          ),
                                          if (movement.batchNumber != null) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildInfoChip(
                                                context,
                                                'Batch',
                                                movement.batchNumber!,
                                                AppTheme.secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (fromLocation != null || toLocation != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (fromLocation != null)
                                              Expanded(
                                                child: _buildInfoChip(
                                                  context,
                                                  'From',
                                                  fromLocation.name,
                                                  AppTheme.textSecondary,
                                                ),
                                              ),
                                            if (fromLocation != null && toLocation != null)
                                              const SizedBox(width: 8),
                                            if (toLocation != null)
                                              Expanded(
                                                child: _buildInfoChip(
                                                  context,
                                                  'To',
                                                  toLocation.name,
                                                  AppTheme.primaryColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                      if (movement.reason != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  movement.reason!,
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('MMM dd, yyyy • HH:mm').format(movement.timestamp),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (movement.notes != null)
                                                IconButton(
                                                  icon: const Icon(Icons.note_outlined, size: 20),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        title: const Text('Notes'),
                                                        content: Text(movement.notes!),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('Close'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                  tooltip: 'View Notes',
                                                ),
                                              if (authProvider.currentUser?.canEdit ?? false)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20),
                                                  color: Colors.red.shade400,
                                                  onPressed: () => _showDeleteDialog(context, movement, stockProvider),
                                                  tooltip: 'Delete Movement',
                                                ),
                                            ],
                                          ),
                                        ],
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
          floatingActionButton: authProvider.currentUser?.canEdit ?? false
              ? (Responsive.isMobile(context)
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StockMovementFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Record Movement'),
                    )
                  : FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StockMovementFormScreen(),
                          ),
                        );
                      },
                      tooltip: 'Record Movement',
                      child: const Icon(Icons.add_rounded),
                    ))
              : null,
        );
      },
    );
  }

  String? _getTypeLabel(MovementType? type) {
    if (type == null) return null;
    switch (type) {
      case MovementType.addition:
        return 'Addition';
      case MovementType.reduction:
        return 'Reduction';
      case MovementType.adjustment:
        return 'Adjustment';
      case MovementType.transfer:
        return 'Transfer';
    }
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

  void _showDeleteDialog(BuildContext context, StockMovement movement, firebase_stock.StockProvider stockProvider) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.getProductById(movement.productId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Movement?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this ${movement.typeLabel.toLowerCase()}?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product: ${product?.name ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text('Quantity: ${movement.quantity} ${product?.unitOfMeasurement ?? ''}'),
                  Text('Type: ${movement.typeLabel}'),
                  if (movement.reason != null) ...[
                    const SizedBox(height: 4),
                    Text('Reason: ${movement.reason}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will reverse the stock changes made by this movement.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading indicator
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
              }
              
              bool success = false;
              String? errorMessage;
              
              try {
                success = await stockProvider.deleteMovement(movement.id ?? '');
                if (!success) {
                  errorMessage = stockProvider.errorMessage ?? 'Unknown error occurred';
                }
              } catch (e) {
                errorMessage = e.toString();
              } finally {
                if (context.mounted) {
                  Navigator.pop(context); // Dismiss loading dialog
                }
              }
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Movement deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting movement: ${errorMessage ?? "Unknown error"}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
