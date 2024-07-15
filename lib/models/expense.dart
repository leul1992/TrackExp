import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  int tripId;

  @HiveField(2)
  String name;

  @HiveField(3)
  double amount;

  @HiveField(4)
  bool isSale;

  @HiveField(5)
  double soldAmount;

  Expense({
    required this.id,
    required this.tripId,
    required this.name,
    required this.amount,
    required this.isSale,
    required this.soldAmount,
  });
}
