import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/modern_card.dart';
import 'location_form_screen.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, _) {
        return Scaffold(
          body: locationProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : locationProvider.locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No locations yet',
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
                                  builder: (_) => const LocationFormScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Location'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => locationProvider.loadLocations(),
                      child: ListView.builder(
                        padding: Responsive.getScreenPadding(context),
                        itemCount: locationProvider.locations.length,
                        itemBuilder: (context, index) {
                          final location = locationProvider.locations[index];
                          return ModernCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationFormScreen(location: location),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: AppTheme.secondaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (location.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          location.description!,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (location.address != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.place_outlined,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                location.address!,
                                                style: Theme.of(context).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
                                          builder: (_) => LocationFormScreen(location: location),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: const Text('Delete Location'),
                                          content: const Text(
                                            'Are you sure you want to delete this location? This action cannot be undone.',
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
                                        await locationProvider.deleteLocation(location.id!);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.white),
                                                  SizedBox(width: 12),
                                                  Text('Location deleted successfully'),
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
          floatingActionButton: Responsive.isMobile(context)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocationFormScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Location'),
                )
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LocationFormScreen(),
                      ),
                    );
                  },
                  tooltip: 'Add Location',
                  child: const Icon(Icons.add_rounded),
                ),
        );
      },
    );
  }
}
