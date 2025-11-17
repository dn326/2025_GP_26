// lib/services/elan_storage.dart
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import 'firebase_service.dart';
import 'firebase_service_dev.dart' show useMocks;

class ElanStorage {
  static const String _bucket = 'elan-storage-23c27.firebasestorage.app';

  static const String _name = 'storageApp';
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;

  static Future<bool> _ensureInit() async {
    // Check if we're using mocks (Linux or useMocks flag)
    bool shouldUseMocks = useMocks || (!kIsWeb && Platform.isLinux);

    if (shouldUseMocks) {
      // For mocks, just use the service locator auth (no separate app needed)
      _auth = firebaseAuth;
      debugPrint('ElanStorage: Using mock auth from service locator');
    } else {
      // For real Firebase, initialize separate app instance
      if (_app == null) {
        if (Firebase.apps.any((a) => a.name == _name)) {
          _app = Firebase.app(_name);
        } else {
          _app = await Firebase.initializeApp(
            name: _name,
            options: _getOptions(),
          );
        }
        _auth = FirebaseAuth.instanceFor(app: _app!);
      }
    }
    return _auth != null;
  }

  static FirebaseOptions _getOptions() {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyAdF_LX1W3DA5AgvKqxzLXX_OlBeyteVA4',
        appId: '1:200438609885:web:91caf1fb7b5326f5332834',
        messagingSenderId: '200438609885',
        projectId: 'elan-storage-23c27',
        storageBucket: _bucket,
        authDomain: 'elan-storage-23c27.firebaseapp.com',
      );
    } else {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBZbSS2hLrFU1o5T0fbars3q59emrYwrU',
        appId: '1:200438609885:android:44a6e0378b5fefa2332834',
        messagingSenderId: '200438609885',
        projectId: 'elan-storage-23c27',
        storageBucket: _bucket,
      );
    }
  }

  static Future<void> _ensureSignedIn() async {
    if (_auth == null) await _ensureInit();

    // Use the service locator to get the main auth instance
    final mainUser = firebaseAuth.currentUser;
    if (mainUser == null) {
      throw Exception(
        'User must be signed in to main app before using storage',
      );
    }

    if (_auth!.currentUser == null) {
      final idToken = await mainUser.getIdToken();
      if (idToken != null) {
        try {
          await _auth!.signInWithCustomToken(idToken);
        } catch (e) {
          await _auth!.signInAnonymously();
        }
      } else {
        await _auth!.signInAnonymously();
      }
    }
  }

  static Future<FirebaseStorage> get storage async {
    if (_storage != null) return _storage!;
    await _ensureSignedIn();
    // Check if we're using mocks (Linux or useMocks flag)
    bool shouldUseMocks = useMocks || (!kIsWeb && Platform.isLinux);

    if (shouldUseMocks) {
      _storage = firebaseStorage;
    } else {
      _storage = FirebaseStorage.instanceFor(app: _app, bucket: 'gs://$_bucket');
      debugPrint('ElanStorage using bucket: gs://$_bucket  (kIsWeb=$kIsWeb)');
    }
    return _storage!;
  }

  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final s = await storage;
      final ref = s.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Fix image URL to use correct storage bucket with properly encoded path
  static String fixImageUrl(String url) {
    if (url.isEmpty) return url;

    try {
      final uri = Uri.parse(url);

      // If it's already a properly formatted firebasestorage.googleapis.com URL, return as-is
      if (uri.host == 'firebasestorage.googleapis.com' &&
          uri.path.contains('/o/')) {
        return url;
      }

      final pathSegments = uri.pathSegments;

      debugPrint('Original URL: $url');
      debugPrint('Path segments: $pathSegments');

      // Find ALL indices of 'o'
      final oIndices = <int>[];
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'o') oIndices.add(i);
      }

      if (oIndices.isEmpty) {
        debugPrint('No "o" found in path, returning original URL');
        return url;
      }

      // Use the LAST 'o' index to handle duplicated URLs
      final lastOIndex = oIndices.last;
      if (lastOIndex + 1 >= pathSegments.length) {
        debugPrint('No path after last "o", returning original URL');
        return url;
      }

      // Extract object path after the LAST 'o' and join with '/'
      final objectPathSegments = pathSegments.sublist(lastOIndex + 1);
      final objectPath = objectPathSegments.join('/');

      // URL encode the entire path (this will convert / to %2F)
      final encodedPath = Uri.encodeComponent(objectPath);

      debugPrint('Extracted object path: $objectPath');
      debugPrint('Encoded path: $encodedPath');

      // Build the URL manually with encoded path
      final queryParams = {'alt': 'media', ...uri.queryParameters};

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final fixedUrl =
          'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/$encodedPath?$queryString';

      debugPrint('Fixed URL: $fixedUrl');
      return fixedUrl;
    } catch (e) {
      debugPrint('fixImageUrl failed: $e');
      return url;
    }
  }
}
