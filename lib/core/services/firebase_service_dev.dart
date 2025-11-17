// lib/core/services/firebase_service_dev.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../firebase_options.dart';

final getIt = GetIt.instance;

// Flag to force mock usage (set to true to always use mocks, regardless of platform)
const bool useMocks = false; // Change to true to force mocks on all platforms

Future<void> setupFirebase() async {
  bool shouldUseMocks = useMocks || (!kIsWeb && Platform.isLinux);

  if (!shouldUseMocks) {
    // Use real Firebase for non-Linux platforms (when useMocks is false)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
    getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);
    getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  } else {
    // Use mocks for Linux or when useMocks flag is true
    getIt.registerSingleton<FirebaseAuth>(MockFirebaseAuth());
    getIt.registerSingleton<FirebaseStorage>(MockFirebaseStorage());
    getIt.registerSingleton<FirebaseFirestore>(FakeFirebaseFirestore());
  }
}
