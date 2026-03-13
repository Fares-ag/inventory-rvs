import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_system/utils/image_helper.dart';

void main() {
  group('ImageHelper', () {
    test('isUrl returns true for http and https', () {
      expect(ImageHelper.isUrl('https://example.com/img.jpg'), true);
      expect(ImageHelper.isUrl('http://example.com/img.jpg'), true);
    });
    test('isUrl returns false for null or non-URL', () {
      expect(ImageHelper.isUrl(null), false);
      expect(ImageHelper.isUrl(''), false);
      expect(ImageHelper.isUrl('/local/path.jpg'), false);
      expect(ImageHelper.isUrl('file:///path'), false);
    });
  });
}
