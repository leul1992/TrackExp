import 'package:flutter/material.dart';
import 'package:trackexp/screens/local/edit_trip_dialog.dart';
import 'package:trackexp/services/hive_services.dart';

class TripActions {
  static Future<void> editTrip(BuildContext context, String tripId,
      {required Function() refreshExpenses}) async {
    // Fetch trip details
    final tripBox = HiveService.getTripBox();
    final trip = tripBox.get(tripId);
    if (trip == null) {
      // Handle error: Trip not found
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditTripDialog(
          trip: trip,
          refreshExpenses: refreshExpenses,
        );
      },
    );
  }

  static Future<void> deleteTrip(BuildContext context, String tripId) async {
    print("another one");
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
                await HiveService.deleteTripAndAssociatedExpenses(tripId);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip deleted successfully')),
                );
                Navigator.pop(context, true); // Close dialog and signal refresh
                Navigator.pop(
                    context, true); // Close detail page and signal refresh
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context, false); // Close dialog without refreshing
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
