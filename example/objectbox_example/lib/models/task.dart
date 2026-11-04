import 'package:objectbox/objectbox.dart';

@Entity()
class Task {
  @Id()
  int id;

  @Property(uid: 1)
  String title;
  @Property(uid: 2)
  String? description;
  @Property(uid: 3)
  bool isCompleted;
  @Property(type: PropertyType.date, uid: 4)
  DateTime createdAt;

  Task({
    this.id = 0,
    required this.title,
    this.description,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
