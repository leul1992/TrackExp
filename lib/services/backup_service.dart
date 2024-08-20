import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trackexp/services/hive_services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:trackexp/provider/login_state_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackupService {
  static Future<void> triggerBackup(BuildContext context) async {
    await HiveService.openBoxes();
    final trips = await HiveService.getTrips();
    final expenses =
        trips.expand((trip) => HiveService.getExpenses(trip.id)).toList();

    final tripsJson = trips.map((trip) => trip.toJson()).toList();
    final expensesJson = expenses.map((expense) => expense.toJson()).toList();
    print("trip json $tripsJson");
    final user = Provider.of<LoginStateProvider>(context, listen: false).user;

    if (user != null) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final idToken = await firebaseUser?.getIdToken();

      final response = await http.post(
        Uri.parse('http://192.168.188.101:8000/api/backup/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'trips': tripsJson,
          'expenses': expensesJson,
        }),
      );

      if (response.statusCode == 200) {
        // Backup successful
        Fluttertoast.showToast(
          msg: 'Backup successful',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        // Backup failed
        Fluttertoast.showToast(
          msg: 'Backup Failed',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } else {
      // User is not logged in
      Fluttertoast.showToast(
        msg: 'User is not logged in',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  static Future<Map<String, dynamic>> fetchData(BuildContext context) async {
    final user = Provider.of<LoginStateProvider>(context, listen: false).user;

    if (user != null) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final idToken = await firebaseUser?.getIdToken();

      final response = await http.get(
        Uri.parse('http://192.168.188.101:8000/api/fetch/'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        print('Backed up data from server: ${response.body}');
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('User is not logged in');
    }
  }

  static Future<bool> deleteData(
      BuildContext context, String dataType, String dataId) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final idToken = await firebaseUser?.getIdToken();

    final response = await http.delete(
      Uri.parse(
          'http://192.168.188.101:8000/api/delete_data/$dataType/$dataId/'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> updateData(
      String dataType, Map<String, dynamic> data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final idToken = await firebaseUser?.getIdToken();

    final response = await http.put(
      Uri.parse(
          'http://192.168.188.101:8000/api/update_data/$dataType/${data['_id']}/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }

  static Future<bool> addData(
      String dataType, Map<String, dynamic> data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final idToken = await firebaseUser?.getIdToken();

    if (data['_id'] == null || data['_id'].isEmpty) {
      data.remove('_id');
    }
    print('data upload $data');
    print('data type: ' + dataType);
    final response = await http.post(
      Uri.parse('http://192.168.188.101:8000/api/backup/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'trips': dataType == 'trips' ? [data] : [],
        'expenses': dataType == 'expenses' ? [data] : [],
      }),
    );

    return response.statusCode == 200;
  }
}
