class SignUpFlowController {
  // Selected user type: "business" or "influencer"
  static String? userType;

  // Temporary email for later pages
  static String? email;

  // Call this to clear all temporary signup data (e.g. when user exits mid-flow).
  static void reset() {
    userType = null;
    email = null;
  }
}
