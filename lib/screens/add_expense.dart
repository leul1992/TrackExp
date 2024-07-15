import 'package:flutter/material.dart';
import 'package:trackexp/services/database_helper.dart';

class AddExpense extends StatefulWidget {
  final int tripId;
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
                  final String money = amount.text;
                  final bool toSell = toBeSold;
                  final int id = widget.tripId;
                  // Handle adding the expense here
                  final int insertedId =
                      await DatabaseHelper.instance.insertExpense({
                    DatabaseHelper.columnExpenseTripId: id,
                    DatabaseHelper.columnExpenseName: reason,
                    DatabaseHelper.columnExpenseAmount: money,
                    DatabaseHelper.columnExpenseIsSale: toSell ? 1 : 0,
                    DatabaseHelper.columnExpenseSoldAmount: 0,
                  });
                  if (insertedId > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense added successfully!'),
                      ),
                    );
      
                    widget.refreshExpenses();
                    Navigator.of(context).pop(); // Close the pop-up
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error adding expense!'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Add',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
