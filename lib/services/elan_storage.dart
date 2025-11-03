// lib/services/elan_storage.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class ElanStorage {
  static const String _bucket = 'elan-storage-23c27.firebasestorage.app';

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'AIzaSyAdF_LX1W3DA5AgvKqxzLXX_OlBeyteVA4',
    appId: '1:200438609885:web:91caf1fb7b5326f5332834',
    messagingSenderId: '200438609885',
    projectId: 'elan-storage-23c27',
    storageBucket: _bucket,
    authDomain: 'elan-storage-23c27.firebaseapp.com',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyBZbSS2hLrFU1o5T0fbars3q59emrYwrU',
    appId: '1:200438609885:android:44a6e0378b5fefa2332834',
    messagingSenderId: '200438609885',
    projectId: 'elan-storage-23c27',
    storageBucket: _bucket,
  );

  static FirebaseOptions get _opts => kIsWeb ? _web : _android;

  static const String _name = 'storageApp';
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;

  static Future<FirebaseApp> _ensureApp() async {
    _app ??= (Firebase.apps.any((a) => a.name == _name)
        ? Firebase.app(_name)
        : await Firebase.initializeApp(name: _name, options: _opts));
    _auth ??= FirebaseAuth.instanceFor(app: _app!);
    return _app!;
  }

  static Future<void> _ensureSignedIn() async {
    if (_auth == null) await _ensureApp();

    final mainUser = FirebaseAuth.instance.currentUser;
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
    final app = await _ensureApp();
    await _ensureSignedIn();

    _storage = FirebaseStorage.instanceFor(app: app, bucket: 'gs://$_bucket');

    print('ElanStorage using bucket: gs://$_bucket  (kIsWeb=$kIsWeb)');
    return _storage!;
  }

  static Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final s = await storage;
      final ref = s.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
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
