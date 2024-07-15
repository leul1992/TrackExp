import 'package:flutter/material.dart';
import 'package:trackexp/screens/add_expense.dart';
import 'package:trackexp/services/database_helper.dart';
import 'package:trackexp/services/trip_actions.dart';

class DetailView extends StatefulWidget {
  final int tripId;

  const DetailView({super.key, required this.tripId});

  @override
  _DetailViewState createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> tripRes = [];
  double totalExpenses = 0;
  double totalSell = 0;
  double soldAmount = 0;
  double totalSellExpense = 0;
  TextEditingController reasonOfPayment = TextEditingController();
  TextEditingController amount = TextEditingController();
  bool toBeSold = false;
  TextEditingController sellPrice = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTripAndExpenses();
  }

  Future<void> fetchTripAndExpenses() async {
    await
    fetchExpenses();
    setState(() {});
  }

  Future<void> fetchTrip() async {
    final tripResult = await DatabaseHelper.instance.getTrip(widget.tripId);
    setState(() {
      tripRes = [tripResult!];
    });
  }

  Future<void> refreshExpenses() async {
    await fetchExpenses();
    setState(() {
      calculateTotalExpenses();
      calculateTotalSell();
      calculateTotalSellExpense();
      fetchTrip();
    }); // Trigger UI update
  }

  Future<void> fetchExpenses() async {
    final expensesResult =
        await DatabaseHelper.instance.getExpenses(widget.tripId);
    setState(() {
      expenses = expensesResult;
      calculateTotalExpenses();
      calculateTotalSell();
      calculateTotalSellExpense();
    });
  }

  void calculateTotalExpenses() {
    totalExpenses = 0;
    for (var expense in expenses) {
      totalExpenses += expense['amount'];
    }
  }

  void calculateTotalSellExpense() {
    totalSellExpense = 0;
    for (var expense in expenses) {
      if (expense['is_sale'] == 1) {
        totalSellExpense += expense['amount'];
      }
    }
  }

  void calculateTotalSell() {
    totalSell = 0;
    for (var expense in expenses) {
      totalSell += expense['sold_amount'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tripRes.isNotEmpty ? tripRes[0]['name'] : ''),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Handle delete action
              TripActions.deleteTrip(context, widget.tripId);
            },
            icon: const Icon(Icons.folder_delete_outlined, size: 32),
          ),
          IconButton(
            onPressed: () {
              // Handle edit action
              TripActions.editTrip(context, widget.tripId, refreshExpenses: refreshExpenses,);
            },
            icon: const Icon(Icons.edit_outlined, size: 32),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: AddExpense(
                      tripId: tripRes[0]['id'],
                      refreshExpenses: refreshExpenses,
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.add_box_outlined, size: 32),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card displaying trip details
            Card(
              color: const Color(0xFF58B7B1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount: ${tripRes.isNotEmpty ? tripRes[0]['total_money'] : ''}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Profit: ${(totalSell - totalExpenses).toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ]),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .flight_takeoff, // Replace Icons.flight_takeoff with the appropriate icon
                              color: Colors.white,
                              size: 24, // Adjust size as needed
                            ),
                            const SizedBox(
                                width: 8), // Adjust spacing as needed
                            Text(
                              '${tripRes.isNotEmpty ? tripRes[0]['start_date'] : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons
                                  .flight_land, // Replace Icons.flight_land with the appropriate icon
                              color: Colors.white,
                              size: 24, // Adjust size as needed
                            ),
                            const SizedBox(
                                width: 8), // Adjust spacing as needed
                            Text(
                              '${tripRes.isNotEmpty ? tripRes[0]['end_date'] : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Add more trip details as needed
                      ],
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sell-Expense: ${totalSellExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sell: ${totalSell.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total-Expense: ${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Total Remain: ${((tripRes.isNotEmpty ? tripRes[0]['total_money'] : 0) - totalExpenses).toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Expenses',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: expenses[index]['is_sale'] == 1
                      ? IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      '${expenses[index]['sold_amount'] > 0 ? "Update" : "Add"} Sold Amount ${expenses[index]['sold_amount'] > 0 ? "\nNow Sold at ${expenses[index]['sold_amount']}" : ""}'),
                                  content: TextField(
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      soldAmount = double.tryParse(value) ?? 0;
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Enter sold amount',
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        // Update sold amount in the database
                                        Map<String, dynamic> updatedExpense = {
                                          'id': expenses[index]['id'],
                                          'sold_amount': soldAmount,
                                        };
                                        DatabaseHelper.instance
                                            .updateExpense(updatedExpense);
                                        // Refresh expenses
                                        refreshExpenses();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                          expenses[index]['sold_amount'] > 0
                                              ? "Update"
                                              : "Sell"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.more_vert),
                        )
                      : const SizedBox(
                          width: 48,
                        ),
                  title: Text(expenses[index]['name']),
                  subtitle: Text('${expenses[index]['amount']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              // Initialize controllers for text fields
                              TextEditingController nameController =
                                  TextEditingController(
                                      text: expenses[index]['name']);
                              TextEditingController amountController =
                                  TextEditingController(
                                      text:
                                          expenses[index]['amount'].toString());
                              TextEditingController soldAmountController =
                                  TextEditingController(
                                      text: expenses[index]['sold_amount']
                                          .toString());

                              return AlertDialog(
                                title: const Text('Edit Expense'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      controller: nameController,
                                      onChanged: (value) {
                                        // Update the name of the expense in the list
                                        setState(() {
                                          expenses[index]['name'] = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Expense Name',
                                        hintText: 'Enter expense name',
                                      ),
                                    ),
                                    TextFormField(
                                      controller: amountController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        // Update the amount of the expense in the list
                                        setState(() {
                                          expenses[index]['amount'] =
                                              double.tryParse(value) ?? 0;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Expense Amount',
                                        hintText: 'Enter expense amount',
                                      ),
                                    ),
                                    if (expenses[index]['is_sale'] == 1)
                                      TextFormField(
                                        controller: soldAmountController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          // Update the sold amount of the expense in the list
                                          setState(() {
                                            expenses[index]['sold_amount'] =
                                                double.tryParse(value) ?? 0;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Sold Amount',
                                          hintText: 'Enter sold amount',
                                        ),
                                      ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () async {
                                      // Convert text from controllers to appropriate data types
                                      double updatedAmount = double.tryParse(
                                              amountController.text) ??
                                          0;
                                      double updatedSoldAmount =
                                          double.tryParse(
                                                  soldAmountController.text) ??
                                              0;

                                      // Create updated expense map
                                      Map<String, dynamic> updatedExpense = {
                                        'id': expenses[index]['id'],
                                        'name': nameController.text,
                                        'amount': updatedAmount,
                                        'sold_amount': updatedSoldAmount,
                                      };

                                      // Update expense in the database
                                      int rowsAffected = await DatabaseHelper
                                          .instance
                                          .updateExpense(updatedExpense);

                                      if (rowsAffected > 0) {
                                        // Refresh expenses if update was successful
                                        refreshExpenses();
                                        // Close the dialog
                                        Navigator.of(context).pop();
                                      } else {
                                        // Handle update failure
                                        // Show an error message or take appropriate action
                                      }
                                    },
                                    child: const Text('Update'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: Text(
                                    'Are you sure you want to delete ${expenses[index]['name']}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      // Delete expense from the database
                                      DatabaseHelper.instance
                                          .deleteExpense(expenses[index]['id']);
                                      // Refresh expenses
                                      refreshExpenses();
                                      Navigator.of(context).pop();
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
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
