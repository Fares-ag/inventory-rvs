import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/models/location.dart';

void main() {
  group('Location', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 'loc1',
        'name': 'Warehouse A',
        'description': 'Main warehouse',
        'address': '123 Main St',
      };
      final loc = Location.fromMap(map);
      expect(loc.id, 'loc1');
      expect(loc.name, 'Warehouse A');
      expect(loc.description, 'Main warehouse');
      expect(loc.address, '123 Main St');

      final out = loc.toMap();
      expect(out['name'], 'Warehouse A');
    });

    test('copyWith', () {
      final loc = Location(id: '1', name: 'A', description: 'd', address: 'addr');
      final loc2 = loc.copyWith(name: 'B');
      expect(loc2.id, '1');
      expect(loc2.name, 'B');
      expect(loc2.description, 'd');
    });
  });
}
