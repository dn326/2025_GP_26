// lib/core/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

// Conditional import based on build type
import 'firebase_service_dev.dart'
    if (dart.library.js_util) 'firebase_service_prod.dart'
    as firebase_impl;

final getIt = GetIt.instance;

class FeqFirebaseService {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await firebase_impl.setupFirebase();
  }
}

// Easy access getters
FirebaseAuth get firebaseAuth => getIt<FirebaseAuth>();

FirebaseStorage get firebaseStorage => getIt<FirebaseStorage>();

FirebaseFirestore get firebaseFirestore => getIt<FirebaseFirestore>();
