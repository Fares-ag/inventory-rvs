import 'image_helper_io.dart' if (dart.library.html) 'image_helper_stub.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorageService _storage = FirebaseStorageService.instance;

  static Future<String?> pickAndSaveImage({String? productId}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'product_images/${productId ?? 'temp'}/image_$timestamp.jpg';
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Selected image is empty or could not be read');
        }
        final url = await _storage.uploadImageFromBytes(bytes, path);
        return url;
      } else {
        // On Android, use XFile.readAsBytes() to handle content URIs properly
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Selected image is empty or could not be read');
        }
        debugPrint('Image read successfully: ${bytes.length} bytes');
        final url = await _storage.uploadImageFromBytes(bytes, path);
        return url;
      }
    } catch (e) {
      debugPrint('Error picking and uploading image: $e');
      rethrow;
    }
  }

  static Future<String?> takePhoto({String? productId}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'product_images/${productId ?? 'temp'}/image_$timestamp.jpg';
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Camera image is empty or could not be read');
        }
        final url = await _storage.uploadImageFromBytes(bytes, path);
        return url;
      } else {
        // On Android, use XFile.readAsBytes() to handle content URIs properly
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Camera image is empty or could not be read');
        }
        debugPrint('Camera image read successfully: ${bytes.length} bytes');
        final url = await _storage.uploadImageFromBytes(bytes, path);
        return url;
      }
    } catch (e) {
      debugPrint('Error taking and uploading photo: $e');
      rethrow;
    }
  }

  static Future<List<String>> pickMultipleImages({String? productId}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return [];

      final List<String> urls = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      for (int i = 0; i < images.length; i++) {
        final path = 'product_images/${productId ?? 'temp'}/image_${timestamp}_$i.jpg';
        
        if (kIsWeb) {
          final bytes = await images[i].readAsBytes();
          if (bytes.isEmpty) {
            debugPrint('Skipping empty image at index $i');
            continue;
          }
          final url = await _storage.uploadImageFromBytes(bytes, path);
          urls.add(url);
        } else {
          // On Android, use XFile.readAsBytes() to handle content URIs properly
          final bytes = await images[i].readAsBytes();
          if (bytes.isEmpty) {
            debugPrint('Skipping empty image at index $i');
            continue;
          }
          debugPrint('Image $i read successfully: ${bytes.length} bytes');
          final url = await _storage.uploadImageFromBytes(bytes, path);
          urls.add(url);
        }
      }
      
      return urls;
    } catch (e) {
      debugPrint('Error picking and uploading multiple images: $e');
      rethrow;
    }
  }

  static Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null) return;
    
    try {
      // Check if it's a Firebase Storage URL
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        await _storage.deleteImage(imageUrl);
      } else {
        // Legacy local file path - try to delete if it exists (only on non-web)
        if (!kIsWeb) {
          try {
            await io.deleteLocalFile(imageUrl);
          } catch (e) {
            // Ignore errors for local files
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't rethrow - image might already be deleted
    }
  }

  static Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }

  // Helper to check if image path is a URL or local file
  static bool isUrl(String? imagePath) {
    if (imagePath == null) return false;
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  // Helper widget to display image (handles both URLs and local files)
  static Widget buildImageWidget(String? imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (imagePath == null || imagePath.isEmpty) {
      return placeholder ?? Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image, color: Colors.grey.shade400),
      );
    }

    if (isUrl(imagePath)) {
      // Firebase Storage URL - use Image.network
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ?? (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: Icon(Icons.broken_image, color: Colors.grey.shade400),
          );
        },
      );
    } else {
      // Local file path - use Image.file (only on non-web)
      if (kIsWeb) {
        // On web, try as network if it's a relative path
        return Image.network(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder ?? (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, color: Colors.grey.shade400),
            );
          },
        );
      } else {
        return io.buildLocalFileWidget(
          imagePath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      }
    }
  }
}

