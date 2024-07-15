import 'package:mongo_dart/mongo_dart.dart';
import 'package:trackexp/models/trip.dart';
import 'package:trackexp/models/expense.dart';

class MongoDBService {
  final Db db = Db("mongodb://your_mongodb_uri");
  late DbCollection tripCollection;
  late DbCollection expenseCollection;

  Future<void> connect() async {
    await db.open();
    tripCollection = db.collection('trips');
    expenseCollection = db.collection('expenses');
  }

  Future<void> disconnect() async {
    await db.close();
  }

  Future<void> backupTrips(List<Trip> trips) async {
    for (var trip in trips) {
      await tripCollection.save(trip.toJson());
    }
  }

  Future<void> backupExpenses(List<Expense> expenses) async {
    for (var expense in expenses) {
      await expenseCollection.save(expense.toJson());
    }
  }
}

extension on Trip {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalMoney': totalMoney,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

extension on Expense {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'amount': amount,
      'isSale': isSale,
      'soldAmount': soldAmount,
    };
  }
}
