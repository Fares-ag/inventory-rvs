import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/models/stock.dart';

void main() {
  group('Stock', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 's1',
        'product_id': 'p1',
        'location_id': 'loc1',
        'quantity': 25.0,
        'minimum_threshold': 5.0,
        'maximum_threshold': 100.0,
        'batch_number': 'B1',
        'expiry_date': '2025-12-31T00:00:00.000Z',
      };
      final stock = Stock.fromMap(map);
      expect(stock.id, 's1');
      expect(stock.productId, 'p1');
      expect(stock.locationId, 'loc1');
      expect(stock.quantity, 25.0);
      expect(stock.batchNumber, 'B1');
      expect(stock.expiryDate, DateTime.utc(2025, 12, 31));

      final out = stock.toMap();
      expect(out['quantity'], 25.0);
    });

    test('fromMap handles quantity as int from JSON', () {
      final stock = Stock.fromMap({
        'product_id': 'p1',
        'location_id': 'loc1',
        'quantity': 10, // int
      });
      expect(stock.quantity, 10.0);
    });

    test('isLowStock and isOverstock', () {
      final low = Stock(productId: 'p', locationId: 'l', quantity: 3, minimumThreshold: 5);
      final ok = Stock(productId: 'p', locationId: 'l', quantity: 10, minimumThreshold: 5, maximumThreshold: 100);
      final over = Stock(productId: 'p', locationId: 'l', quantity: 100, maximumThreshold: 50);
      expect(low.isLowStock, true);
      expect(ok.isLowStock, false);
      expect(ok.isOverstock, false);
      expect(over.isOverstock, true);
    });

    test('copyWith', () {
      final s = Stock(id: '1', productId: 'p', locationId: 'l', quantity: 10);
      final s2 = s.copyWith(quantity: 20);
      expect(s2.id, '1');
      expect(s2.quantity, 20);
    });
  });
}
