import 'package:realm/realm.dart';
import 'package:realm_example/database/database_manager.dart';
import 'package:realm_example/models/person.dart';

class PersonRepository {
  final Realm _realm;

  PersonRepository(DatabaseManager databaseManager)
      : _realm = databaseManager.realm;

  /// 一次写入同时保存人员和地址。关联对象可以放进构造函数，由 `add` 一起入库。
  Person createPerson(
    String name,
    int age, {
    String? email,
    Address? address,
  }) {
    return _realm.write(() {
      return _realm
          .add(Person(ObjectId(), name, age, email: email, address: address));
    });
  }

  void addAddress(
    Person person,
    String street,
    String city,
    String country, {
    String? postalCode,
  }) {
    _realm.write(() {
      final previous = person.address;
      person.address = Address(
        ObjectId(),
        street,
        city,
        country,
        postalCode: postalCode,
      );
      if (previous != null) {
        _realm.delete(previous);
      }
    });
  }

  List<Person> getAllPersons() {
    return _realm.query<Person>('TRUEPREDICATE SORT(name ASC)').toList();
  }

  Person? getPersonById(ObjectId id) => _realm.find<Person>(id);

  List<Person> findPersonsByName(String name) {
    return _realm.query<Person>(r'name == $0', [name]).toList();
  }

  void updatePerson(Person person, {String? name, int? age, String? email}) {
    _realm.write(() {
      if (name != null) person.name = name;
      if (age != null) person.age = age;
      if (email != null) person.email = email;
    });
  }

  void deletePerson(Person person) {
    _realm.write(() {
      final address = person.address;
      person.address = null;
      if (address != null) {
        _realm.delete(address);
      }
      _realm.delete(person);
    });
  }

  /// 先发出当前结果，之后由 `RealmResults.changes` 在数据变化时再发。
  Stream<List<Person>> watchAllPersons() async* {
    final results = _realm.query<Person>('TRUEPREDICATE SORT(name ASC)');
    yield results.toList();
    yield* results.changes.map((changes) => changes.results.toList());
  }
}
