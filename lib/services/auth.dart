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

  // Sign in with Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut(); // Ensure user starts fresh

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled login

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
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Check if the account is scheduled for deletion
      final shouldReactivate = await _checkForScheduledDeletion(user, context);
      if (shouldReactivate) {
        await _reactivateAccount(user); // Reactivate account
      } else {
        return; // User opted not to reactivate; cancel login
      }

      // Backup user data after successful login and reactivation
      await _backupUserData(user);

      final customUser = CustomUser(
        email: user.email,
        displayName: user.displayName,
      );
      Provider.of<LoginStateProvider>(context, listen: false).logIn(customUser);

      Fluttertoast.showToast(
        msg: 'Login Successful',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Check if account is scheduled for deletion
  Future<bool> _checkForScheduledDeletion(
      User user, BuildContext context) async {
    final idToken = await user.getIdToken();
    final response = await http.get(
      Uri.parse('http://192.168.1.7:8000/api/check_scheduled_deletion/'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isScheduledForDeletion = data['scheduled_for_deletion'] ?? false;
      final daysRemaining = data['days_remaining'] ?? 0;

      if (isScheduledForDeletion) {
        final shouldReactivate =
            await _showReactivationDialog(context, daysRemaining);
        return shouldReactivate;
      }
    }
    return true; // No deletion scheduled, proceed with login
  }

  // Reactivate user account if scheduled for deletion
  Future<void> _reactivateAccount(User user) async {
    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.7:8000/api/check_and_reactivate_account/'),
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
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to reactivate account',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Backup user data to the backend
  Future<void> _backupUserData(User? user) async {
    if (user == null) return;

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.7:8000/api/backup_user_data/'),
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
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to back up user data',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Show a dialog asking if the user wants to reactivate their account
  Future<bool> _showReactivationDialog(
      BuildContext context, int daysRemaining) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Reactivate Account'),
              content: Text(
                'Your account is scheduled for deletion in $daysRemaining days. Would you like to reactivate it?',
              ),
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

  // Schedule account deletion for 30 days
  Future<void> scheduleAccountDeletion(CustomUser user) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final idToken = await firebaseUser?.getIdToken();
    final response = await http.post(
      Uri.parse('http://192.168.1.7:8000/api/schedule_account_deletion/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        // Add any necessary authorization headers here
      },
      body: jsonEncode({
        'email': user.email,
      }),
    );

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: 'Account deletion scheduled successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to schedule account deletion',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
