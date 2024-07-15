import 'package:hive/hive.dart';

part 'trip.g.dart';

@HiveType(typeId: 0)
class Trip extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double totalMoney;

  @HiveField(3)
  String startDate;

  @HiveField(4)
  String endDate;

  Trip({
    required this.id,
    required this.name,
    required this.totalMoney,
    required this.startDate,
    required this.endDate,
  });
}
