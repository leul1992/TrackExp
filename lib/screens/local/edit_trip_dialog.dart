import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/services/hive_services.dart';

class EditTripDialog extends StatefulWidget {
  final Trip trip;
  final Function() refreshExpenses;

  const EditTripDialog({
    super.key,
    required this.trip,
    required this.refreshExpenses,
  });

  @override
  _EditTripDialogState createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<EditTripDialog> {
  late TextEditingController nameController;
  late TextEditingController totalMoneyController;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.trip.name);
    totalMoneyController = TextEditingController(text: widget.trip.totalMoney.toString());
    selectedDateRange = DateTimeRange(
      start: DateTime.parse(widget.trip.startDate),
      end: DateTime.parse(widget.trip.endDate),
    );
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
            decoration: const InputDecoration(labelText: 'Trip Name'),
          ),
          TextFormField(
            controller: totalMoneyController,
            decoration: const InputDecoration(labelText: 'Total Money'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16.0),
          ListTile(
            title: const Text("Trip Dates"),
            subtitle: selectedDateRange == null
                ? const Text("Select date range")
                : Text(
                    "${DateFormat('yyyy-MM-dd').format(selectedDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(selectedDateRange!.end)}"),
            onTap: () async {
              final DateTimeRange? pickedRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                initialDateRange: selectedDateRange,
              );

              if (pickedRange != null) {
                setState(() {
                  selectedDateRange = pickedRange;
                });
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without saving
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final DateFormat formatter = DateFormat('yyyy-MM-dd');
            final updatedTrip = widget.trip.copyWith(
              name: nameController.text,
              totalMoney: double.tryParse(totalMoneyController.text),
              startDate: formatter.format(selectedDateRange!.start),
              endDate: formatter.format(selectedDateRange!.end),
            );
            HiveService.updateTrip(updatedTrip);
            widget.refreshExpenses(); // Refresh the home page data
            Navigator.of(context).pop(true); // Close the dialog and signal a refresh
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
