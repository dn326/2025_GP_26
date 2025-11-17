import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';

import '../services/elan_storage.dart';
import '../services/firebase_service_dev.dart' show useMocks;

class FeqImagePickerService {
  static Future<ImagePickResult?> pickAndUploadImage({
    required String userId,
    required String storagePath, // e.g., 'profiles', 'posts', etc.
    int imageQuality = 85,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: imageQuality);

      if (pickedFile == null) return null;

      // Determine extension
      final extension = _getExtension(pickedFile);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'image_$timestamp.$extension';

      // Check if using mocks
      bool shouldUseMocks = useMocks;

      if (shouldUseMocks) {
        // Mock mode: store image locally, create a mock URL
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          // Create a data URL for mocks
          final imageUrl = 'data:image/$extension;base64,${base64Encode(bytes)}';
          debugPrint('Mock mode: Image stored locally, URL: $imageUrl');
          return ImagePickResult(downloadUrl: imageUrl, bytes: bytes, file: null);
        } else {
          final file = File(pickedFile.path);
          // Use file path as mock URL
          final imageUrl = 'file://${file.path}';
          debugPrint('Mock mode: Image stored locally, URL: $imageUrl');
          return ImagePickResult(downloadUrl: imageUrl, file: file, bytes: null);
        }
      } else {
        // Real Firebase Storage mode
        final storage = await ElanStorage.storage;
        final ref = storage.ref().child(storagePath).child(userId).child(fileName);

        final contentType = _getContentType(extension);
        final metadata = SettableMetadata(contentType: contentType, cacheControl: 'public, max-age=3600');

        String downloadUrl;

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          await ref.putData(bytes, metadata);
          downloadUrl = await ref.getDownloadURL();
          return ImagePickResult(downloadUrl: downloadUrl, bytes: bytes, file: null);
        } else {
          final file = File(pickedFile.path);
          await ref.putFile(file, metadata);
          downloadUrl = await ref.getDownloadURL();
          return ImagePickResult(downloadUrl: downloadUrl, file: file, bytes: null);
        }
      }
    } catch (e) {
      debugPrint('Image pick/upload error: $e');
      rethrow;
    }
  }

  static String _getExtension(XFile file) {
    final mimeType = file.mimeType;
    final path = file.path;

    if (mimeType != null) {
      if (mimeType.contains('png')) return 'png';
      if (mimeType.contains('webp')) return 'webp';
      if (mimeType.contains('gif')) return 'gif';
      if (mimeType.contains('jpeg') || mimeType.contains('jpg')) return 'jpg';
    }

    if (path.isNotEmpty) {
      final parts = path.split('.');
      if (parts.length > 1) {
        final ext = parts.last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
          return ext == 'jpeg' ? 'jpg' : ext;
        }
      }
    }

    return 'jpg';
  }

  static String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}

class ImagePickResult {
  final String downloadUrl;
  final File? file;
  final Uint8List? bytes;

  ImagePickResult({required this.downloadUrl, this.file, this.bytes});
}
