import 'package:flutter/material.dart';
import 'package:objectbox_example/models/task.dart';
import 'package:objectbox_example/objectbox/database_manager.dart';
import 'package:objectbox_example/repositories/task_repository.dart';

// 此页面为UI页面
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestObjectBoxWidget(),
    );
  }
}

class TestObjectBoxWidget extends StatefulWidget {
  const TestObjectBoxWidget({super.key});

  @override
  State<TestObjectBoxWidget> createState() => _TestObjectBoxWidgetState();
}

class _TestObjectBoxWidgetState extends State<TestObjectBoxWidget> {
  //所有任务
  List<Task> taskList = [];
  late TaskRepository taskRepository;

  @override
  void didChangeDependencies() {
    init();
    super.didChangeDependencies();
  }

  //初始化方法
  Future<void> init() async {
    DatabaseManager databaseManager = await DatabaseManager.create();
    taskRepository = TaskRepository(databaseManager);
    getAllTasks();
  }

  //获取所有任务
  Future<void> getAllTasks() async {
    setState(() {
      taskList = taskRepository.getAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ObjectBox"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                Task item = taskList[index];
                return Container(
                  width: double.infinity,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.black12,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "id:${item.id}",
                            ),
                            Text(
                              "title:${item.title}",
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          taskRepository.deleteTask(item.id);
                          getAllTasks();
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Text("isCompleted:"),
                      Switch(
                        value: item.isCompleted,
                        onChanged: (value) {
                          item.isCompleted = !item.isCompleted;
                          taskRepository.updateTask(item);
                          getAllTasks();
                        },
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const SizedBox(
                  width: double.infinity,
                  height: 16,
                );
              },
              itemCount: taskList.length,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              "实现了基本的增删查改的例子，复杂的需要自己探索，最重要的一点，版本升级和降级，找了网上大量ObjectBox的教程，说是不需要手动管理版本，当涉及字段的改变（更改或删除时），只需要给一个uid即可，但是好奇类型改变的情况是否适用，目前没遇到这种场景，需要继续探索。",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(
            width: double.infinity,
            height: 70,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          taskRepository.addTask(
            Task(
              title: taskList.length.toString(),
            ),
          );
          getAllTasks();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
