import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackexp/services/hive_services.dart';
import 'package:trackexp/models/trip.dart';

class EditTripDialog extends StatefulWidget {
  final Trip trip;
  final Function() refreshExpenses;

  const EditTripDialog(
      {super.key, required this.trip, required this.refreshExpenses});

  @override
  _EditTripDialogState createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController totalMoneyController = TextEditingController();
  late DateTime startDate;
  late DateTime endDate;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    nameController.text = widget.trip.name;
    totalMoneyController.text = widget.trip.totalMoney.toString();
    startDate = DateTime.parse(widget.trip.startDate);
    endDate = DateTime.parse(widget.trip.endDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Trip'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Trip Name',
            ),
          ),
          TextFormField(
            controller: totalMoneyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Money',
            ),
          ),
          ListTile(
            title: const Text("Start Date"),
            subtitle: Text(formatter.format(startDate)),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  startDate = pickedDate;
                });
              }
            },
          ),
          ListTile(
            title: const Text("End Date"),
            subtitle: Text(formatter.format(endDate)),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                setState(() {
                  endDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            final updatedTrip = Trip(
              id: widget.trip.id,
              name: nameController.text,
              totalMoney: double.tryParse(totalMoneyController.text) ?? 0,
              startDate: startDate.toString(),
              endDate: endDate.toString(),
            );

            // Update trip in Hive
            await HiveService.updateTrip(updatedTrip);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip updated successfully')),
            );
            widget.refreshExpenses();
            // Close the dialog
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
