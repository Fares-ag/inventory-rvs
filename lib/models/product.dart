import 'dart:convert';

class Product {
  final String? id; // Changed to String for Firestore compatibility
  final String name;
  final String? category;
  final String unitOfMeasurement;
  final String? description;
  final String sku;
  final String? partNumber;
  final String? manufacturer;
  final String? supplier;
  final double? currentQuantity;
  final double? unitCost;
  final double? minimumStock;
  final double? maximumStock;
  final String? locationId; // Changed to String for Firestore compatibility
  final String? warranty;
  final String? notes;
  final String? imagePath; // Legacy support
  final List<String>? imagePaths; // Multiple images

  Product({
    this.id,
    required this.name,
    this.category,
    required this.unitOfMeasurement,
    this.description,
    required this.sku,
    this.partNumber,
    this.manufacturer,
    this.supplier,
    this.currentQuantity,
    this.unitCost,
    this.minimumStock,
    this.maximumStock,
    this.locationId,
    this.warranty,
    this.notes,
    this.imagePath,
    this.imagePaths,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit_of_measurement': unitOfMeasurement,
      'description': description,
      'sku': sku,
      'part_number': partNumber,
      'manufacturer': manufacturer,
      'supplier': supplier,
      'current_quantity': currentQuantity,
      'unit_cost': unitCost,
      'minimum_stock': minimumStock,
      'maximum_stock': maximumStock,
      'location_id': locationId?.toString(),
      'warranty': warranty,
      'notes': notes,
      'image_path': imagePath,
      'image_paths': imagePaths,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    // Handle image_paths - can be List, String (JSON), or null
    List<String>? imagePaths;
    if (map['image_paths'] != null) {
      if (map['image_paths'] is List) {
        imagePaths = List<String>.from(map['image_paths']);
      } else if (map['image_paths'] is String) {
        try {
          // Try to parse as JSON array
          final decoded = (map['image_paths'] as String);
          if (decoded.startsWith('[') && decoded.endsWith(']')) {
            // It's a JSON string, parse it
            imagePaths = List<String>.from(jsonDecode(decoded));
          } else {
            // Single string, convert to list
            imagePaths = [decoded];
          }
        } catch (e) {
          // If parsing fails, treat as single string
          imagePaths = [map['image_paths'] as String];
        }
      }
    }

    return Product(
      id: map['id']?.toString(), // Handle both int and String IDs
      name: map['name'] as String,
      category: map['category'] as String?,
      unitOfMeasurement: map['unit_of_measurement'] as String? ?? 'piece',
      description: map['description'] as String?,
      sku: map['sku'] as String,
      partNumber: map['part_number'] as String?,
      manufacturer: map['manufacturer'] as String?,
      supplier: map['supplier'] as String?,
      currentQuantity: map['current_quantity'] != null
          ? (map['current_quantity'] is double
              ? map['current_quantity'] as double
              : (map['current_quantity'] as num).toDouble())
          : null,
      unitCost: map['unit_cost'] != null
          ? (map['unit_cost'] is double
              ? map['unit_cost'] as double
              : (map['unit_cost'] as num).toDouble())
          : null,
      minimumStock: map['minimum_stock'] != null
          ? (map['minimum_stock'] is double
              ? map['minimum_stock'] as double
              : (map['minimum_stock'] as num).toDouble())
          : null,
      maximumStock: map['maximum_stock'] != null
          ? (map['maximum_stock'] is double
              ? map['maximum_stock'] as double
              : (map['maximum_stock'] as num).toDouble())
          : null,
      locationId: map['location_id']?.toString(),
      warranty: map['warranty'] as String?,
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      imagePaths: imagePaths,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? unitOfMeasurement,
    String? description,
    String? sku,
    String? partNumber,
    String? manufacturer,
    String? supplier,
    double? currentQuantity,
    double? unitCost,
    double? minimumStock,
    double? maximumStock,
    String? locationId,
    String? warranty,
    String? notes,
    String? imagePath,
    List<String>? imagePaths,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unitOfMeasurement: unitOfMeasurement ?? this.unitOfMeasurement,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      partNumber: partNumber ?? this.partNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      supplier: supplier ?? this.supplier,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      unitCost: unitCost ?? this.unitCost,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      locationId: locationId ?? this.locationId,
      warranty: warranty ?? this.warranty,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  // Getter for first image (for backward compatibility)
  String? get firstImage {
    if (imagePaths != null && imagePaths!.isNotEmpty) {
      return imagePaths!.first;
    }
    return imagePath;
  }

  // Getter for all images
  List<String> get allImages {
    if (imagePaths != null && imagePaths!.isNotEmpty) {
      return imagePaths!;
    }
    if (imagePath != null) {
      return [imagePath!];
    }
    return [];
  }
}
