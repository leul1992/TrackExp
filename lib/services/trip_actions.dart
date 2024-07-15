import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackexp/services/database_helper.dart';
import 'package:trackexp/screens/edit_trip_dialog.dart';

class TripActions {
  static Future<void> editTrip(BuildContext context, int tripId, {required Function() refreshExpenses}) async {
    // Fetch trip details
    final trip = await DatabaseHelper.instance.getTrip(tripId);
    if (trip == null) {
      // Handle error: Trip not found
      return;
    }

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return EditTripDialog(
            trip: trip,
            refreshExpenses: refreshExpenses);
        });
  }

  static Future<void> deleteTrip(BuildContext context, int tripId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this trip?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Delete trip and associated expenses
                await DatabaseHelper.instance
                    .deleteTripAndAssociatedExpenses(tripId);
                // Show success message or navigate to previous screen
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(); // Assuming you're navigating back to the previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip deleted successfully')),
                );
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
