enum MovementType {
  addition,
  reduction,
  adjustment,
  transfer,
}

class StockMovement {
  final String? id; // Changed to String for Firestore compatibility
  final String productId; // Changed to String for Firestore compatibility
  final String? fromLocationId; // Changed to String for Firestore compatibility
  final String? toLocationId; // Changed to String for Firestore compatibility
  final MovementType type;
  final double quantity;
  final String? reason;
  final String? notes;
  final String userId; // Changed to String for Firestore compatibility
  final DateTime timestamp;
  final String? batchNumber;

  StockMovement({
    this.id,
    required this.productId,
    this.fromLocationId,
    this.toLocationId,
    required this.type,
    required this.quantity,
    this.reason,
    this.notes,
    required this.userId,
    required this.timestamp,
    this.batchNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId.toString(),
      'from_location_id': fromLocationId?.toString(),
      'to_location_id': toLocationId?.toString(),
      'type': type.name,
      'quantity': quantity,
      'reason': reason,
      'notes': notes,
      'user_id': userId.toString(), // Already String
      'timestamp': timestamp.toIso8601String(),
      'batch_number': batchNumber,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id']?.toString(), // Handle both int and String IDs
      productId: map['product_id']?.toString() ?? '', // Handle both int and String IDs
      fromLocationId: map['from_location_id']?.toString(), // Handle both int and String IDs
      toLocationId: map['to_location_id']?.toString(), // Handle both int and String IDs
      type: MovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MovementType.adjustment,
      ),
      quantity: map['quantity'] != null
          ? (map['quantity'] is double
              ? map['quantity'] as double
              : (map['quantity'] as num).toDouble())
          : 0.0,
      reason: map['reason'] as String?,
      notes: map['notes'] as String?,
      userId: map['user_id']?.toString() ?? '', // Handle both int and String IDs
      timestamp: DateTime.parse(map['timestamp'] as String),
      batchNumber: map['batch_number'] as String?,
    );
  }

  String get typeLabel {
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
}

