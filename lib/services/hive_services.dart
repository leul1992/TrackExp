import 'package:hive/hive.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/models/expense.dart';

class HiveService {
  static Box<Trip> getTripBox() => Hive.box<Trip>('trips');
  static Box<Expense> getExpenseBox() => Hive.box<Expense>('expenses');

  static Future<void> deleteTripAndAssociatedExpenses(int tripId) async {
    final expenseBox = getExpenseBox();
    final tripBox = getTripBox();

    // Delete associated expenses
    final expensesToDelete = expenseBox.values.where((expense) => expense.tripId == tripId).toList();
    for (var expense in expensesToDelete) {
      await expense.delete();
    }

    // Delete trip
    final trip = tripBox.get(tripId);
    if (trip != null) {
      await trip.delete();
    }
  }
}
