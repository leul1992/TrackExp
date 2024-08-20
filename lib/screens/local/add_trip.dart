import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/services/hive_services.dart';
import 'package:uuid/uuid.dart';

class AddTripForm extends StatefulWidget {
  final Future<void> Function() refreshTrips;

  const AddTripForm({super.key, required this.refreshTrips});

  @override
  State<AddTripForm> createState() => _AddTripFormState();
}

class _AddTripFormState extends State<AddTripForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController moneyController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Trip',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Trip Name',
              ),
              controller: nameController,
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Allocated Money',
              ),
              controller: moneyController,
              keyboardType: TextInputType.number,
            ),
            ListTile(
              title: const Text("Trip Dates"),
              subtitle: startDate == null || endDate == null
                  ? const Text("Select date range")
                  : Text(
                      "${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}"),
              onTap: () async {
                final DateTimeRange? pickedRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  initialDateRange: startDate != null && endDate != null
                      ? DateTimeRange(start: startDate!, end: endDate!)
                      : null,
                );

                if (pickedRange != null) {
                  setState(() {
                    startDate = pickedRange.start;
                    endDate = pickedRange.end;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    const Color(0xFF58B7B1),
                  ),
                ),
                onPressed: () async {
                  final String name = nameController.text;
                  final double totalMoney =
                      double.tryParse(moneyController.text) ?? 0.0;

                  // Format the start date and end date
                  final DateFormat formatter = DateFormat('yyyy-MM-dd');
                  final String startDateString =
                      startDate != null ? formatter.format(startDate!) : '';
                  final String endDateString =
                      endDate != null ? formatter.format(endDate!) : '';

                  if (name.isEmpty ||
                      startDateString.isEmpty ||
                      endDateString.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields'),
                      ),
                    );
                    return;
                  }

                  // Create a new trip
                  final trip = Trip(
                    id: const Uuid().v4(),
                    name: name,
                    totalMoney: totalMoney,
                    startDate: startDateString,
                    endDate: endDateString,
                  );

                  // Insert the trip using HiveService
                  await HiveService.insertTrip(trip);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip added successfully!'),
                    ),
                  );

                  Navigator.pop(
                      context, true); // Close the form and signal to refresh
                  await widget.refreshTrips(); // Refresh the trips after adding
                },
                child: const Text(
                  'Add',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
