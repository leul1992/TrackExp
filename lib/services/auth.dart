import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trackexp/provider/login_state_provider.dart';
import 'package:trackexp/models/user_model.dart'; // Adjust the path as necessary

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User canceled the login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        Fluttertoast.showToast(
          msg: 'Login Failed',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Check if the account is scheduled for deletion
      final shouldReactivate = await _checkForScheduledDeletion(user, context);
      if (shouldReactivate) {
        await _reactivateAccount(user);
      } else {
        return; // User chose not to reactivate, so do not log them in
      }

      await _backupUserData(user);

      final customUser = CustomUser(
        email: user.email,
        displayName: user.displayName,
      );
      Provider.of<LoginStateProvider>(context, listen: false).logIn(customUser);

      Fluttertoast.showToast(
        msg: 'Login Successful',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
        msg: 'An error occurred',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<bool> _checkForScheduledDeletion(
      User user, BuildContext context) async {
    final idToken = await user.getIdToken();
    final response = await http.get(
      Uri.parse('http://192.168.1.4:8000/api/check_scheduled_deletion/'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isScheduledForDeletion = data['scheduled_for_deletion'] ?? false;

      if (isScheduledForDeletion) {
        final shouldReactivate = await _showReactivationDialog(context);
        return shouldReactivate;
      }
    }
    return true; // No deletion scheduled, proceed with login
  }

  Future<void> _reactivateAccount(User user) async {
    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.4:8000/api/reactivate_account/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'email': user.email,
      }),
    );

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Account reactivated successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to reactivate account',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _backupUserData(User? user) async {
    if (user == null) return;

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.4:8000/api/backup_user_data/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'email': user.email,
        'displayName': user.displayName,
      }),
    );

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'User data backed up successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to back up user data',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<bool> _showReactivationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Reactivate Account'),
              content: const Text(
                  'Your account is scheduled for deletion. Would you like to reactivate it?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> scheduleAccountDeletion(CustomUser user) async {
    final response = await http.post(
      Uri.parse('http://your-backend-url/schedule_account_deletion/'),
      headers: {
        'Content-Type': 'application/json',
        // Add any necessary authorization headers here
      },
      body: {
        'email': user.email,
      },
    );

    if (response.statusCode == 200) {
      // Account deletion scheduled successfully
      print('Account deletion scheduled for ${user.email}');
    } else {
      // Handle errors here
      print('Failed to schedule account deletion for ${user.email}');
    }
  }
}
