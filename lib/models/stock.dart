class Stock {
  final String? id; // Changed to String for Firestore compatibility
  final String productId; // Changed to String for Firestore compatibility
  final String locationId; // Changed to String for Firestore compatibility
  final double quantity;
  final double? minimumThreshold;
  final double? maximumThreshold;
  final String? batchNumber;
  final DateTime? expiryDate;

  Stock({
    this.id,
    required this.productId,
    required this.locationId,
    required this.quantity,
    this.minimumThreshold,
    this.maximumThreshold,
    this.batchNumber,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId.toString(),
      'location_id': locationId.toString(),
      'quantity': quantity,
      'minimum_threshold': minimumThreshold,
      'maximum_threshold': maximumThreshold,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      id: map['id']?.toString(), // Handle both int and String IDs
      productId: map['product_id']?.toString() ?? '', // Handle both int and String IDs
      locationId: map['location_id']?.toString() ?? '', // Handle both int and String IDs
      quantity: map['quantity'] != null
          ? (map['quantity'] is double
              ? map['quantity'] as double
              : (map['quantity'] as num).toDouble())
          : 0.0,
      minimumThreshold: map['minimum_threshold'] as double?,
      maximumThreshold: map['maximum_threshold'] as double?,
      batchNumber: map['batch_number'] as String?,
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
    );
  }

  Stock copyWith({
    String? id,
    String? productId,
    String? locationId,
    double? quantity,
    double? minimumThreshold,
    double? maximumThreshold,
    String? batchNumber,
    DateTime? expiryDate,
  }) {
    return Stock(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      locationId: locationId ?? this.locationId,
      quantity: quantity ?? this.quantity,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      maximumThreshold: maximumThreshold ?? this.maximumThreshold,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  bool get isLowStock {
    if (minimumThreshold == null) return false;
    return quantity <= minimumThreshold!;
  }

  bool get isOverstock {
    if (maximumThreshold == null) return false;
    return quantity >= maximumThreshold!;
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }
}

