import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/models/expense.dart';

class HiveService {
  static const String tripBoxName = 'trips';
  static const String expenseBoxName = 'expenses';

  static Future<void> openBoxes() async {
    // Register adapters only if not registered
    print('opeing box');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TripAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExpenseAdapter());
    }

    // Open boxes
    await Hive.openBox<Trip>(tripBoxName);
    await Hive.openBox<Expense>(expenseBoxName);
  }

  static Box<Trip> getTripBox() => Hive.box<Trip>(tripBoxName);
  static Box<Expense> getExpenseBox() => Hive.box<Expense>(expenseBoxName);

  // Insert Trip
  static Future<void> insertTrip(Trip trip) async {
    final tripBox = getTripBox();
    await tripBox.put(trip.id, trip);
  }

  // Insert Expense
  static Future<void> insertExpense(Expense expense) async {
    final expenseBox = getExpenseBox();
    await expenseBox.put(expense.id, expense);
  }

  // Get all Trips
  static Future<List<Trip>> getTrips() async {
    final tripBox = getTripBox();
    for (var trip in tripBox.values) {
  final tripJson = jsonEncode(trip.toJson());
  print('data json: $tripJson');
}
    return tripBox.values.toList();
  }

  // Get a single Trip by ID
  static Trip? getTrip(String tripId) {
    final tripBox = getTripBox();
    return tripBox.get(tripId);
  }

  // Get all Expenses for a specific Trip
  static List<Expense> getExpenses(String tripId) {
    final expenseBox = getExpenseBox();
    return expenseBox.values
        .where((expense) => expense.tripId == tripId)
        .toList();
  }

  // Update Trip
  static Future<void> updateTrip(Trip trip) async {
    final tripBox = getTripBox();
    await tripBox.put(trip.id, trip);
  }

  // Update Expense
  static Future<void> updateExpense(Expense expense) async {
    final expenseBox = getExpenseBox();
    await expenseBox.put(expense.id, expense);
  }

  // Delete Trip and associated Expenses
  static Future<void> deleteTripAndAssociatedExpenses(String tripId) async {
    print('final step');
    final expenseBox = getExpenseBox();
    final tripBox = getTripBox();

    // Delete associated expenses
    final expensesToDelete =
        expenseBox.values.where((expense) => expense.tripId == tripId).toList();
    for (var expense in expensesToDelete) {
      await expense.delete();
    }

    // Delete trip
    final trip = tripBox.get(tripId);
    if (trip != null) {
      await trip.delete();
    }
  }

  // Delete Trip
  static Future<void> deleteTrip(int tripId) async {
    final tripBox = getTripBox();
    await tripBox.delete(tripId);
  }

  // Delete Expense
  static Future<void> deleteExpense(String expenseId) async {
    final expenseBox = getExpenseBox();
    await expenseBox.delete(expenseId);
  }
}
