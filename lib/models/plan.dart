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

  Plan({
    required this.id,
    required this.description,
    required this.createdAt,
  });
}
