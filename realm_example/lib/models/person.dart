import 'package:realm/realm.dart';

part 'person.realm.dart';

/// 人员。主键用 [ObjectId]，这是当前 Realm Flutter 文档里的写法。
@RealmModel()
class _Person {
  @PrimaryKey()
  late ObjectId id;

  late String name;
  late int age;
  String? email;

  /// 一对一关系必须是可选的，否则打开数据库时会抛异常。
  late _Address? address;
}

@RealmModel()
class _Address {
  @PrimaryKey()
  late ObjectId id;

  late String street;
  late String city;
  late String country;
  String? postalCode;
}
