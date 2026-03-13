import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_movement.dart';
import '../providers/product_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';

class MovementHistoryReport extends StatelessWidget {
  final List<StockMovement> movements;
  final ProductProvider productProvider;
  final LocationProvider locationProvider;

  const MovementHistoryReport({
    super.key,
    required this.movements,
    required this.productProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No movement history available',
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
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product?.name ?? 'Unknown Product',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            movement.typeLabel,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${movement.quantity.toStringAsFixed(0)} ${product?.unitOfMeasurement ?? ''}',
                        style: TextStyle(
                          color: color,
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
                        'From',
                        fromLocation?.name ?? 'N/A',
                        Icons.location_on_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'To',
                        toLocation?.name ?? 'N/A',
                        Icons.location_on_outlined,
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
                        'Date',
                        DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(movement.timestamp),
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    if (movement.batchNumber != null)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Batch',
                          movement.batchNumber!,
                          Icons.qr_code_outlined,
                        ),
                      ),
                  ],
                ),
                if (movement.reason != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    context,
                    'Reason',
                    movement.reason!,
                    Icons.info_outline_rounded,
                  ),
                ],
                if (movement.notes != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    context,
                    'Notes',
                    movement.notes!,
                    Icons.note_outlined,
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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
