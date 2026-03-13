import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/models/product.dart';

void main() {
  group('Product', () {
    test('fromMap and toMap round-trip', () {
      final map = {
        'id': 'p1',
        'name': 'Widget A',
        'category': 'Electronics',
        'unit_of_measurement': 'piece',
        'description': 'A widget',
        'sku': 'SKU-001',
        'part_number': 'PN-001',
        'manufacturer': 'Acme',
        'supplier': 'Supplier Co',
        'current_quantity': 10.0,
        'unit_cost': 5.99,
        'minimum_stock': 2.0,
        'maximum_stock': 100.0,
        'location_id': 'loc1',
        'warranty': '1 year',
        'notes': 'Test',
        'image_path': null,
        'image_paths': ['https://example.com/1.jpg'],
      };
      final product = Product.fromMap(map);
      expect(product.id, 'p1');
      expect(product.name, 'Widget A');
      expect(product.sku, 'SKU-001');
      expect(product.currentQuantity, 10.0);
      expect(product.imagePaths, ['https://example.com/1.jpg']);

      final out = product.toMap();
      expect(out['name'], 'Widget A');
      expect(out['sku'], 'SKU-001');
      expect(out['image_paths'], ['https://example.com/1.jpg']);
    });

    test('fromMap handles numeric quantity as int from JSON', () {
      final map = {
        'name': 'Item',
        'sku': 'S1',
        'unit_of_measurement': 'piece',
        'current_quantity': 5, // int from JSON
      };
      final product = Product.fromMap(map);
      expect(product.currentQuantity, 5.0);
    });

    test('copyWith preserves unchanged fields', () {
      final p = Product(
        id: 'x',
        name: 'Original',
        unitOfMeasurement: 'piece',
        sku: 'SKU-X',
        currentQuantity: 10,
      );
      final p2 = p.copyWith(name: 'Updated');
      expect(p2.id, 'x');
      expect(p2.name, 'Updated');
      expect(p2.sku, 'SKU-X');
      expect(p2.currentQuantity, 10);
    });

    test('firstImage returns first of imagePaths', () {
      final p = Product(
        name: 'P',
        unitOfMeasurement: 'piece',
        sku: 'S',
        imagePaths: ['a.jpg', 'b.jpg'],
      );
      expect(p.firstImage, 'a.jpg');
    });

    test('firstImage falls back to imagePath', () {
      final p = Product(
        name: 'P',
        unitOfMeasurement: 'piece',
        sku: 'S',
        imagePath: 'legacy.jpg',
      );
      expect(p.firstImage, 'legacy.jpg');
    });

    test('allImages returns imagePaths or single imagePath', () {
      expect(
        Product(name: 'P', unitOfMeasurement: 'piece', sku: 'S', imagePaths: ['a', 'b']).allImages,
        ['a', 'b'],
      );
      expect(
        Product(name: 'P', unitOfMeasurement: 'piece', sku: 'S', imagePath: 'x').allImages,
        ['x'],
      );
      expect(
        Product(name: 'P', unitOfMeasurement: 'piece', sku: 'S').allImages,
        [],
      );
    });
  });
}
