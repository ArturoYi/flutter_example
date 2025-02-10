import 'package:realm/realm.dart';

part 'person.realm.dart';

@RealmModel()
class _Person {
  @PrimaryKey()
  late String id;
  
  late String name;
  late int age;
  String? email;
  
  late _Address? addresses;
}


@RealmModel()
class _Address {
  @PrimaryKey()
  late String id;
  
  late String street;
  late String city;
  late String country;
  String? postalCode;
}