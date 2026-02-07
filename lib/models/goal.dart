import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 1)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime createdAt;

  Goal({
    required this.id,
    required this.description,
    required this.createdAt,
  });
}
