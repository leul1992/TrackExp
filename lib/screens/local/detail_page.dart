import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trackexp/screens/local/add_expense.dart';
import 'package:trackexp/services/hive_services.dart';
import 'package:trackexp/services/trip_actions.dart';
import 'package:trackexp/models/expense.dart';
import 'package:trackexp/models/trip.dart';

class DetailView extends StatefulWidget {
  final String tripId;
  final VoidCallback onTripUpdated;

  const DetailView(
      {super.key, required this.tripId, required this.onTripUpdated});

  @override
  _DetailViewState createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  List<Expense> expenses = [];
  Trip? trip;
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
    await fetchTrip();
    await fetchExpenses();
    setState(() {});
  }

  Future<void> fetchTrip() async {
    final fetchedTrip = HiveService.getTrip(widget.tripId);
    setState(() {
      trip = fetchedTrip;
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
    final fetchedExpenses = HiveService.getExpenses(widget.tripId);
    setState(() {
      expenses = fetchedExpenses;
      calculateTotalExpenses();
      calculateTotalSell();
      calculateTotalSellExpense();
    });
  }

  void calculateTotalExpenses() {
    totalExpenses = expenses.fold(0, (sum, item) => sum + item.amount);
  }

  void calculateTotalSellExpense() {
    totalSellExpense = expenses
        .where((expense) => expense.isSale)
        .fold(0, (sum, item) => sum + item.amount);
  }

  void calculateTotalSell() {
    totalSell = expenses.fold(0, (sum, item) => sum + item.soldAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(trip != null ? trip!.name : ''),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              // Handle delete action
              print("Delete trip ${widget.tripId}");
              await TripActions.deleteTrip(context, widget.tripId);
              widget.onTripUpdated(); // Trigger the refresh on HomePage
            },
            icon: const Icon(Icons.folder_delete_outlined, size: 32),
          ),
          IconButton(
            onPressed: () async {
              // Handle edit action
              await TripActions.editTrip(
                context,
                widget.tripId,
                refreshExpenses: refreshExpenses,
              );
              widget.onTripUpdated(); // Trigger the refresh on HomePage
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
                      tripId: trip!.id,
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
                            'Total Amount: ${trip != null ? trip!.totalMoney : ''}',
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
                              Icons.flight_takeoff,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trip != null ? trip!.startDate : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.flight_land,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              trip != null ? trip!.endDate : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
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
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total-Expense: ${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Total Remain: ${((trip != null ? trip!.totalMoney : 0) - totalExpenses).toStringAsFixed(2)}',
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
                  leading: expenses[index].isSale
                      ? IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      '${expenses[index].soldAmount > 0 ? "Update" : "Add"} Sold Amount ${expenses[index].soldAmount > 0 ? "\nNow Sold at ${expenses[index].soldAmount}" : ""}'),
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
                                      onPressed: () async {
                                        // Update sold amount in the Hive
                                        expenses[index].soldAmount = soldAmount;
                                        await HiveService.updateExpense(
                                            expenses[index]);
                                        // Refresh expenses
                                        refreshExpenses();
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(expenses[index].soldAmount > 0
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
                  title: Text(expenses[index].name),
                  subtitle: Text('${expenses[index].amount}'),
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
                                      text: expenses[index].name);
                              TextEditingController amountController =
                                  TextEditingController(
                                      text: expenses[index].amount.toString());
                              TextEditingController soldAmountController =
                                  TextEditingController(
                                      text: expenses[index]
                                          .soldAmount
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
                                          expenses[index].name = value;
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
                                          expenses[index].amount =
                                              double.tryParse(value) ?? 0;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Expense Amount',
                                        hintText: 'Enter expense amount',
                                      ),
                                    ),
                                    if (expenses[index].isSale)
                                      TextFormField(
                                        controller: soldAmountController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          // Update the sold amount of the expense in the list
                                          setState(() {
                                            expenses[index].soldAmount =
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

                                      // Update the expense in the list
                                      expenses[index].name =
                                          nameController.text;
                                      expenses[index].amount = updatedAmount;
                                      expenses[index].soldAmount =
                                          updatedSoldAmount;

                                      // Update expense in the Hive
                                      await HiveService.updateExpense(
                                          expenses[index]);

                                      // Refresh expenses if update was successful
                                      refreshExpenses();
                                      // Close the dialog
                                      Navigator.of(context).pop();
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
                                    'Are you sure you want to delete ${expenses[index].name}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () async {
                                      // Delete expense from the Hive
                                      await HiveService.deleteExpense(
                                          expenses[index].id);
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
