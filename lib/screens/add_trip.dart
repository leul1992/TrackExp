import 'package:flutter/material.dart';
import 'package:trackexp/services/database_helper.dart';
import 'package:intl/intl.dart';

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
              title: const Text("Trip Start Date"),
              subtitle: startDate == null
                  ? const Text("Select date")
                  : Text(DateFormat('yyyy-MM-dd').format(startDate!)),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != startDate) {
                  setState(() {
                    startDate = pickedDate;
                  });
                }
              },
            ),
            ListTile(
              title: const Text("Trip End Date"),
              subtitle: endDate == null
                  ? const Text("Select date")
                  : Text(DateFormat('yyyy-MM-dd').format(endDate!)),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != endDate) {
                  setState(() {
                    endDate = pickedDate;
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
                  final double totalMoney = double.parse(moneyController.text);

                  // Format the start date and end date
                  final DateFormat formatter = DateFormat('yyyy-MM-dd');
                  final String startDateString =
                      startDate != null ? formatter.format(startDate!) : '';
                  final String endDateString =
                      endDate != null ? formatter.format(endDate!) : '';

                  final int insertedId =
                      await DatabaseHelper.instance.insertTrip({
                    DatabaseHelper.columnTripName: name,
                    DatabaseHelper.columnTripTotalMoney: totalMoney,
                    DatabaseHelper.columnTripStartDate: startDateString,
                    DatabaseHelper.columnTripEndDate: endDateString,
                  });

                  if (insertedId > 0) {
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip added successfully!'),
                      ),
                    );
                    // Update the state to rerender the widget
                    widget.refreshTrips();

                    // Close the form
                    Navigator.of(context).pop();
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error adding trip!'),
                      ),
                    );
                  }
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
