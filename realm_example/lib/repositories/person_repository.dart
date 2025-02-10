import 'package:realm/realm.dart';
import 'package:realm_example/database/database_manager.dart';
import 'package:realm_example/models/person.dart';

class PersonRepository {
  final DatabaseManager _databaseManager;
  late final Realm _realm;

  PersonRepository(this._databaseManager) {
    _realm = _databaseManager.realm;
  }

  // 创建新的Person对象
  Person createPerson(String name, int age, {String? email}) {
    final person = Person(
      ObjectId().toString(),
      name,
      age,
      email: email,
    );
    _realm.write(() => _realm.add(person));
    return person;
  }

  // 添加地址到Person
  void addAddress(Person person, String street, String city, String country,
      {String? postalCode}) {
    final address = Address(
      ObjectId().toString(),
      street,
      city,
      country,
      postalCode: postalCode,
    );
    _realm.write(() {
      person.addresses = address;
    });
  }

  // 获取所有Person对象
  List<Person> getAllPersons() {
    return _realm.all<Person>().toList();
  }

  // 根据ID查找Person
  Person? getPersonById(String id) {
    return _realm.find<Person>(id);
  }

  // 根据名字查找Person
  List<Person> findPersonsByName(String name) {
    return _realm.query<Person>(r'name == "$0"', [name]).toList();
  }

  // 更新Person信息
  void updatePerson(Person person, {String? name, int? age, String? email}) {
    _realm.write(() {
      if (name != null) person.name = name;
      if (age != null) person.age = age;
      if (email != null) person.email = email;
    });
  }

  // 删除Person
  void deletePerson(Person person) {
    _realm.write(() {
      _realm.delete(person);
    });
  }

  // 删除Person的地址
  void deleteAddress(Person person, Address address) {
    _realm.write(() {
      person.addresses = null;
      _realm.delete(address);
    });
  }
}
