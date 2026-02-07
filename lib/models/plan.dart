import 'package:hive/hive.dart';

part 'plan.g.dart';

@HiveType(typeId: 0)
class Plan {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String? title;

  @HiveField(4)
  final String? fromTime;

  @HiveField(5)
  final String? toTime;

  @HiveField(6)
  final String? duration;

  Plan({
    required this.id,
    required this.description,
    required this.createdAt,
    this.title,
    this.fromTime,
    this.toTime,
    this.duration,
  });
}
