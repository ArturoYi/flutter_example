import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';
import 'package:realm_example/database/database_manager.dart';
import 'package:realm_example/main.dart';
import 'package:realm_example/models/person.dart';
import 'package:realm_example/repositories/person_repository.dart';

void main() {
  late DatabaseManager databaseManager;
  late PersonRepository repository;

  setUp(() {
    databaseManager = DatabaseManager.inMemory();
    repository = PersonRepository(databaseManager);
  });

  tearDown(() {
    databaseManager.close();
  });

  test('creates, queries, updates and deletes a person with an address', () {
    final person = repository.createPerson(
      '李四',
      30,
      email: 'lisi@example.com',
      address: Address(ObjectId(), '南京路 1 号', '上海', '中国', postalCode: '200001'),
    );

    expect(person.address?.city, '上海');
    expect(repository.getPersonById(person.id)?.name, '李四');
    expect(repository.findPersonsByName('李四'), hasLength(1));
    expect(repository.findPersonsByName('不存在'), isEmpty);
    expect(repository.getAllPersons().map((item) => item.name), ['李四']);

    repository.updatePerson(person, name: '李四(更新)', age: 31);
    expect(person.name, '李四(更新)');
    expect(person.age, 31);

    repository.addAddress(person, '新街 2 号', '杭州', '中国', postalCode: '310000');
    expect(person.address?.city, '杭州');
    expect(databaseManager.realm.all<Address>(), hasLength(1));

    repository.deletePerson(person);
    expect(repository.getAllPersons(), isEmpty);
    expect(databaseManager.realm.all<Address>(), isEmpty);
  });

  test('watch emits the current people before later changes', () async {
    repository.createPerson('王五', 20);
    final people = await repository.watchAllPersons().first;
    expect(people.single.name, '王五');
  });

  testWidgets('shows people from the Realm stream', (tester) async {
    final database = DatabaseManager.inMemory();
    addTearDown(database.close);
    personRepository = PersonRepository(database);
    personRepository.createPerson(
      '赵六',
      22,
      address: Address(ObjectId(), '某某路某某号', '上海', '中国'),
    );

    await tester.pumpWidget(const MainApp());
    await tester.pump();

    expect(find.text('赵六'), findsOneWidget);
    expect(find.textContaining('上海'), findsOneWidget);
  });
}
