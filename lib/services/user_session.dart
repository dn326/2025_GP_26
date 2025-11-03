import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  // Get current user ID
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Get user type from SharedPreferences
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  // Get account status
  static Future<String?> getAccountStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('account_status');
  }

  // Logout
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data
  }
}
