import 'package:hive/hive.dart';

part 'trip.g.dart';

enum TripStatus { notStarted, inProgress, ended }

@HiveType(typeId: 0)
class Trip extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double totalMoney;

  @HiveField(3)
  final String startDate;

  @HiveField(4)
  final String endDate;

  Trip({
    required this.id,
    required this.name,
    required this.totalMoney,
    required this.startDate,
    required this.endDate,
  });

  TripStatus getStatus() {
    final now = DateTime.now();
    final tripStartDate = DateTime.parse(startDate);
    final tripEndDate = DateTime.parse(endDate);

    if (now.isBefore(tripStartDate)) {
      return TripStatus.notStarted;
    } else if (now.isAfter(tripStartDate) && now.isBefore(tripEndDate)) {
      return TripStatus.inProgress;
    } else {
      return TripStatus.ended;
    }
  }

  Trip copyWith({
    String? id,
    String? name,
    double? totalMoney,
    String? startDate,
    String? endDate,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      totalMoney: totalMoney ?? this.totalMoney,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'total_money': totalMoney,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}
