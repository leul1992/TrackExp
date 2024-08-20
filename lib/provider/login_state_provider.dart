import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackexp/models/user_model.dart'; // Adjust the path as necessary

class LoginStateProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  CustomUser? _user;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool get isLoggedIn => _isLoggedIn;
  CustomUser? get user => _user;

  LoginStateProvider() {
    _loadUserData();
  }

  void logIn(CustomUser user) async {
    _isLoggedIn = true;
    _user = user;
    notifyListeners();
    await _saveUserData(user);
  }

  void logOut() async {
    _isLoggedIn = false;
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
    await _clearUserData();
    // Navigate to the home page
  }

  Future<void> _saveUserData(CustomUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email ?? '');
    await prefs.setString('user_display_name', user.displayName ?? '');
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final displayName = prefs.getString('user_display_name');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn && email != null && displayName != null) {
      _isLoggedIn = true;
      _user = CustomUser(email: email, displayName: displayName);
      notifyListeners();
    }
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_display_name');
    await prefs.remove('is_logged_in');
  }
}
