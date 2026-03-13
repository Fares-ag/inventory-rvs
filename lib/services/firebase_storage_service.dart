import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class FirebaseStorageService {
  static final FirebaseStorageService instance = FirebaseStorageService._init();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseStorageService._init();

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Upload a single image
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      // Check authentication before upload
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to upload images. Please log in first.');
      }

      // Verify file exists and has content
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty (0 bytes)');
      }

      developer.log('Uploading image: ${imageFile.path}, size: $fileSize bytes');

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      developer.log('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      developer.log('Firebase Storage error uploading image', error: e);
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception('Permission denied. Please ensure you are logged in and Storage security rules are deployed.');
      }
      rethrow;
    } catch (e) {
      developer.log('Error uploading image', error: e);
      rethrow;
    }
  }

  // Upload image from bytes (for web)
  Future<String> uploadImageFromBytes(Uint8List bytes, String path) async {
    try {
      // Check authentication before upload
      if (!isAuthenticated) {
        throw Exception('User must be authenticated to upload images. Please log in first.');
      }

      // Verify bytes are not empty
      if (bytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }

      developer.log('Uploading image from bytes: ${bytes.length} bytes');

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      developer.log('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      developer.log('Firebase Storage error uploading image from bytes', error: e);
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception('Permission denied. Please ensure you are logged in and Storage security rules are deployed.');
      }
      rethrow;
    } catch (e) {
      developer.log('Error uploading image from bytes', error: e);
      rethrow;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles, String basePath) async {
    try {
      final List<String> urls = [];
      for (int i = 0; i < imageFiles.length; i++) {
        final path = '$basePath/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await uploadImage(imageFiles[i], path);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      developer.log('Error uploading images', error: e);
      rethrow;
    }
  }

  // Upload multiple images from bytes (for web)
  Future<List<String>> uploadImagesFromBytes(List<Uint8List> imageBytes, String basePath) async {
    try {
      final List<String> urls = [];
      for (int i = 0; i < imageBytes.length; i++) {
        final path = '$basePath/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await uploadImageFromBytes(imageBytes[i], path);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      developer.log('Error uploading images from bytes', error: e);
      rethrow;
    }
  }

  // Delete an image
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      developer.log('Error deleting image', error: e);
      // Don't rethrow - image might already be deleted
    }
  }

  // Delete multiple images
  Future<void> deleteImages(List<String> urls) async {
    try {
      for (final url in urls) {
        await deleteImage(url);
      }
    } catch (e) {
      developer.log('Error deleting images', error: e);
      // Don't rethrow - continue deleting others
    }
  }

  // Get download URL from path
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      developer.log('Error getting download URL', error: e);
      rethrow;
    }
  }
}


