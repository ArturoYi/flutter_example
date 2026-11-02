import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:realm_example/database/database_manager.dart';
import 'package:realm_example/models/person.dart';
import 'package:realm_example/repositories/person_repository.dart';

late final PersonRepository personRepository;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  personRepository = PersonRepository(DatabaseManager.open());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realm',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      home: const PersonListPage(),
    );
  }
}

class PersonListPage extends StatefulWidget {
  const PersonListPage({super.key});

  @override
  State<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends State<PersonListPage> {
  final _nameController = TextEditingController();
  late final Stream<List<Person>> _people = personRepository.watchAllPersons();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    personRepository.createPerson(
      name,
      25,
      email: 'realm@example.com',
      address: Address(
        ObjectId(),
        '某某路某某号',
        '上海',
        '中国',
        postalCode: '200000',
      ),
    );
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('input'),
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '输入姓名',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addPerson(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '回车或点加号添加。编辑会改名并让年龄加 1。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Person>>(
              stream: _people,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('读取失败：${snapshot.error}'));
                }
                final people = snapshot.data;
                if (people == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (people.isEmpty) {
                  return const Center(child: Text('还没有人员'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: people.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person.name,
                                  key: Key('list_item_$index'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '年龄 ${person.age}  ·  ${person.email ?? '无邮箱'}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                ),
                                Text(
                                  _formatAddress(person.address),
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                ),
                                Text(
                                  'id: ${person.id}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              personRepository.updatePerson(
                                person,
                                name: '${person.name}(更新)',
                                age: person.age + 1,
                              );
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () =>
                                personRepository.deletePerson(person),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('submit'),
        onPressed: _addPerson,
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _formatAddress(Address? address) {
  if (address == null) return '无地址';
  final postalCode = address.postalCode;
  final suffix = postalCode == null ? '' : '  $postalCode';
  return '${address.country} ${address.city} ${address.street}$suffix';
}
