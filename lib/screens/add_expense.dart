import 'package:flutter/material.dart';
import 'package:trackexp/models/expense.dart';
import 'package:trackexp/services/hive_services.dart';
import 'package:uuid/uuid.dart';

class AddExpense extends StatefulWidget {
  final String tripId;
  final Future<void> Function() refreshExpenses;

  const AddExpense(
      {Key? key, required this.tripId, required this.refreshExpenses})
      : super(key: key);

  @override
  _AddExpenseState createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  TextEditingController reasonOfPayment = TextEditingController();
  TextEditingController amount = TextEditingController();
  bool toBeSold = false;

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
              'Add Expense',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Reason of Payment',
              ),
              controller: reasonOfPayment,
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
              keyboardType: TextInputType.number,
              controller: amount,
            ),
            Row(
              children: [
                const Text('To Be Sold:'),
                Checkbox(
                  value: toBeSold,
                  onChanged: (value) {
                    setState(() {
                      toBeSold = value ?? false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    const Color(0xFF58B7B1),
                  ),
                ),
                onPressed: () async {
                  final String reason = reasonOfPayment.text;
                  final double money = double.tryParse(amount.text) ?? 0.0;
                  final bool toSell = toBeSold;
                  final String id = widget.tripId;

                  // Create a new expense
                  final expense = Expense(
                    id: Uuid().v4(), // Generate a unique ID
                    tripId: id,
                    name: reason,
                    amount: money,
                    isSale: toSell,
                    soldAmount: 0.0,
                  );

                  // Insert the expense using HiveService
                  await HiveService.insertExpense(expense);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense added successfully!'),
                    ),
                  );

                  widget.refreshExpenses();
                  Navigator.of(context).pop(); // Close the pop-up
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
