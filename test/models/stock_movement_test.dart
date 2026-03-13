import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/models/stock_movement.dart';

void main() {
  group('StockMovement', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 'm1',
        'product_id': 'p1',
        'from_location_id': 'loc1',
        'to_location_id': 'loc2',
        'type': 'transfer',
        'quantity': 5.0,
        'reason': 'Restock',
        'notes': 'Note',
        'user_id': 'u1',
        'timestamp': '2024-01-15T10:00:00.000Z',
        'batch_number': 'B001',
      };
      final m = StockMovement.fromMap(map);
      expect(m.id, 'm1');
      expect(m.productId, 'p1');
      expect(m.type, MovementType.transfer);
      expect(m.quantity, 5.0);
      expect(m.userId, 'u1');
      expect(m.batchNumber, 'B001');

      final out = m.toMap();
      expect(out['type'], 'transfer');
      expect(out['quantity'], 5.0);
    });

    test('fromMap parses all movement types', () {
      for (final type in MovementType.values) {
        final m = StockMovement.fromMap({
          'product_id': 'p1',
          'type': type.name,
          'quantity': 1.0,
          'user_id': 'u1',
          'timestamp': '2024-01-01T00:00:00.000Z',
        });
        expect(m.type, type);
      }
    });

    test('typeLabel returns correct labels', () {
      expect(StockMovement(productId: 'p', type: MovementType.addition, quantity: 1, userId: 'u', timestamp: DateTime.now()).typeLabel, 'Addition');
      expect(StockMovement(productId: 'p', type: MovementType.reduction, quantity: 1, userId: 'u', timestamp: DateTime.now()).typeLabel, 'Reduction');
      expect(StockMovement(productId: 'p', type: MovementType.adjustment, quantity: 1, userId: 'u', timestamp: DateTime.now()).typeLabel, 'Adjustment');
      expect(StockMovement(productId: 'p', type: MovementType.transfer, quantity: 1, userId: 'u', timestamp: DateTime.now()).typeLabel, 'Transfer');
    });

    test('fromMap handles numeric ids as int from JSON', () {
      final m = StockMovement.fromMap({
        'id': 123,
        'product_id': 456,
        'type': 'addition',
        'quantity': 2.0,
        'user_id': 789,
        'timestamp': '2024-01-01T00:00:00.000Z',
      });
      expect(m.id, '123');
      expect(m.productId, '456');
      expect(m.userId, '789');
    });
  });
}
