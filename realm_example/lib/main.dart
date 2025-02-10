import 'package:flutter/material.dart';
import 'package:realm_example/database/database_manager.dart';
import 'package:realm_example/models/person.dart';
import 'package:realm_example/repositories/person_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseManager = await DatabaseManager.getInstance();
  runApp(MyApp(databaseManager: databaseManager));
}

class MyApp extends StatelessWidget {
  final DatabaseManager databaseManager;

  const MyApp({super.key, required this.databaseManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realm示例',
      home: PersonListPage(databaseManager: databaseManager),
    );
  }
}

class PersonListPage extends StatefulWidget {
  final DatabaseManager databaseManager;

  const PersonListPage({super.key, required this.databaseManager});

  @override
  State<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends State<PersonListPage> {
  late PersonRepository _personRepository;
  List<Person> _persons = [];

  @override
  void initState() {
    super.initState();
    _personRepository = PersonRepository(widget.databaseManager);
    _loadPersons();
  }

  void _loadPersons() {
    setState(() {
      _persons = _personRepository.getAllPersons();
    });
  }

  Future<void> _addPerson() async {
    final person =
        _personRepository.createPerson('name', 25, email: 'realm@example.com');
    _personRepository.addAddress(
      person,
      '某某路某某号',
      '上海',
      '中国',
      postalCode: '000000',
    );
    _loadPersons();
  }

  void _updatePerson(Person person) {
    _personRepository.updatePerson(
      person,
      name: '${person.name}(更新)',
      age: person.age + 1,
    );
    _loadPersons();
  }

  void _deletePerson(Person person) {
    _personRepository.deletePerson(person);
    _loadPersons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realm数据库示例'),
      ),
      body: ListView.builder(
        itemCount: _persons.length,
        itemBuilder: (context, index) {
          final person = _persons[index];
          return ListTile(
            title: Text(person.name),
            subtitle: Text(
              '''
              年龄: ${person.age}
              邮箱: ${person.email ?? "无"}
              国家: ${person.addresses?.street}
              城市: ${person.addresses?.city}
              国家: ${person.addresses?.country}
              编码: ${person.addresses?.postalCode}
              ''',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _updatePerson(person),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deletePerson(person),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: const Text("关于数据库远程同步，这里暂时没有使用场景所以不考虑，至于数据库版本升级：版本设置在数据库初始化字段里的schemaVersion里面，版本改变时会触发migrationCallback回调，数据迁移和更改就在该回调里处理。",),
      ),
    );
  }
}
