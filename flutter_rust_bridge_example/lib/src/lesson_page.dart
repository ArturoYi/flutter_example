import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/amount.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/notes.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/progress.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/simple.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/total.dart';

/// 界面上的六节来自 `rust/src/api`。
/// 生成出来的 Dart 在 `lib/src/rust/api`，下面调用的就是这些函数。
class LessonPage extends StatefulWidget {
  const LessonPage({super.key});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController(text: 'Tom');
  final _noteController = TextEditingController();
  final _amountController = TextEditingController(text: '12.5');
  final _depositController = TextEditingController(text: '12.5');

  late final AnimationController _spin;
  late final Ledger _ledger;

  var _limit = 1000000;
  var _busy = false;
  var _workText = '点下面的按钮，让 Rust 数质数。';
  var _priority = Priority.normal;
  var _headline = '点「交给 Rust」，列表会整份传过去。';
  var _amountText = '成功时拿到整数「分」，失败时抛出 AmountError。';
  var _counting = false;
  var _ticks = const <int>[];
  String? _depositError;

  final _notes = <Note>[
    const Note(title: '买菜', priority: Priority.normal),
    const Note(title: '报销', priority: Priority.high),
  ];

  StreamSubscription<int>? _countdown;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ledger = Ledger();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _spin.dispose();
    _ledger.dispose();
    _nameController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _countAsync() async {
    setState(() {
      _busy = true;
      _workText = 'Rust 正在工作线程里计算，旁边的图标继续转。';
    });
    final result = await countPrimes(limit: _limit);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _workText = _workLine(result);
    });
  }

  void _countBlocking() {
    final result = countPrimesBlocking(limit: _limit);
    setState(() => _workText = _workLine(result));
  }

  String _workLine(WorkResult result) {
    return '不超过 ${_group(_limit)} 的质数有 ${result.primes} 个，'
        'Rust 用了 ${result.elapsedMillis} ms。';
  }

  void _addNote() {
    final title = _noteController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _notes.add(Note(title: title, priority: _priority));
      _noteController.clear();
    });
  }

  Future<void> _summarize() async {
    final result = await report(notes: List<Note>.of(_notes));
    if (!mounted) return;
    setState(() => _headline = result.headline);
  }

  Future<void> _parseAmount() async {
    try {
      final cents = await parseCents(raw: _amountController.text);
      if (!mounted) return;
      setState(() => _amountText = '${_yuanFromCents(cents)} 元 = $cents 分');
    } on AmountError catch (error) {
      if (!mounted) return;
      setState(() => _amountText = _amountErrorText(error));
    }
  }

  void _deposit() {
    final yuan = double.tryParse(_depositController.text.trim());
    if (yuan == null) {
      setState(() => _depositError = '请输入数字，单位是元。');
      return;
    }
    _ledger.deposit(yuan: yuan);
    setState(() => _depositError = null);
  }

  void _startCountdown() {
    _countdown?.cancel();
    setState(() {
      _counting = true;
      _ticks = [];
    });
    _countdown = countDown(start: 5).listen(
      (value) {
        if (!mounted) return;
        setState(() => _ticks = [..._ticks, value]);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _counting = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter + Rust')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('flutter_rust_bridge 2.13', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(
            '在 rust/src/api 写普通 Rust 函数。代码生成器产出 lib/src/rust 里的 Dart，'
            '调用方式和普通函数一样。启动时 main 里先执行 RustLib.init()。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _LessonCard(
            index: 1,
            title: '同步函数',
            source: 'rust/src/api/simple.rs · greet',
            explanation: '加上 #[frb(sync)] 后，Dart 直接拿到返回值。适合很短的计算，build 里也能调用。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名字',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  greet(name: _nameController.text),
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          _LessonCard(
            index: 2,
            title: '把耗时计算放进工作线程',
            source: 'rust/src/api/simple.rs · count_primes',
            explanation:
                '同一个质数统计有两个入口。countPrimes 返回 Future，Rust 在工作线程跑。'
                'countPrimesBlocking 在当前这条线程跑；从按钮调用时，这条线程就是 UI 线程，转圈会停住。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RotationTransition(
                      turns: _spin,
                      child: Icon(
                        Icons.refresh,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('图标由 Flutter 自己在转。UI 线程被占住时，它会停。'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('上限 ${_group(_limit)}'),
                Slider(
                  min: 200000,
                  max: 2000000,
                  divisions: 18,
                  label: _group(_limit),
                  value: _limit.toDouble(),
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _limit = value.round()),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : _countAsync,
                      child: const Text('异步计算'),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : _countBlocking,
                      child: const Text('同步计算'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_workText),
              ],
            ),
          ),
          _LessonCard(
            index: 3,
            title: '结构体和枚举',
            source: 'rust/src/api/notes.rs · Note、Priority、report',
            explanation: '公开字段的结构体和没有数据的枚举会生成 Dart 类。列表整份拷贝进 Rust，再把汇总拷贝回来。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _notes.length; index++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_notes[index].title),
                    subtitle: Text(_priorityLabel(_notes[index].priority)),
                    trailing: IconButton(
                      tooltip: '删除',
                      onPressed: () => setState(() => _notes.removeAt(index)),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '新笔记',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addNote(),
                ),
                const SizedBox(height: 12),
                SegmentedButton<Priority>(
                  segments: const [
                    ButtonSegment(value: Priority.low, label: Text('低')),
                    ButtonSegment(value: Priority.normal, label: Text('普通')),
                    ButtonSegment(value: Priority.high, label: Text('高')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selected) {
                    setState(() => _priority = selected.first);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _addNote,
                      child: const Text('添加'),
                    ),
                    FilledButton(
                      onPressed: _summarize,
                      child: const Text('交给 Rust'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_headline),
              ],
            ),
          ),
          _LessonCard(
            index: 4,
            title: '用 Result 表示失败',
            source: 'rust/src/api/amount.rs · parse_cents',
            explanation: 'Rust 返回 Result<i64, AmountError>。Dart 在成功时拿到分，失败时抛出 AmountError。金额在 Rust 里按分保存。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '金额（元）',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _parseAmount(),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _parseAmount, child: const Text('解析')),
                const SizedBox(height: 12),
                Text(_amountText),
              ],
            ),
          ),
          _LessonCard(
            index: 5,
            title: '状态留在 Rust',
            source: 'rust/src/api/total.rs · Ledger',
            explanation: 'Ledger 标了 #[frb(opaque)]，字段也是私有的。Dart 持有句柄，deposit 和 balance 都作用在同一个 Rust 对象上。页面销毁时调用 dispose()。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '余额 ${_ledger.balance.toStringAsFixed(2)} 元 · ${_ledger.entries} 笔',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _depositController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '记一笔（元）',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _deposit(),
                ),
                if (_depositError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _depositError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(onPressed: _deposit, child: const Text('记账')),
                    OutlinedButton(
                      onPressed: () => setState(_ledger.reset),
                      child: const Text('清零'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _LessonCard(
            index: 6,
            title: '一次调用，多次返回',
            source: 'rust/src/api/progress.rs · count_down',
            explanation: 'Rust 参数里的 StreamSink<i32> 会从 Dart 签名里消失，函数变成 Stream<int>。每 add 一次，listen 就收到一个数。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton(
                  onPressed: _counting ? null : _startCountdown,
                  child: Text(_counting ? '倒计时进行中' : '从 5 倒数到 0'),
                ),
                const SizedBox(height: 12),
                Text(_ticks.isEmpty ? '还没有事件' : _ticks.join('  ')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.index,
    required this.title,
    required this.source,
    required this.explanation,
    required this.child,
  });

  final int index;
  final String title;
  final String source;
  final String explanation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$index. $title', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              source,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(explanation),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

String _priorityLabel(Priority priority) {
  return switch (priority) {
    Priority.low => '低',
    Priority.normal => '普通',
    Priority.high => '高',
  };
}

String _amountErrorText(AmountError error) {
  return switch (error.kind) {
    AmountErrorKind.empty => '金额是空的。',
    AmountErrorKind.notANumber => '「${error.detail}」不是数字。',
    AmountErrorKind.negative => '金额不能是负数。',
  };
}

String _yuanFromCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final absolute = cents.abs();
  final whole = absolute ~/ 100;
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign$whole.$fraction';
}

String _group(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    if (index > 0 && (text.length - index) % 3 == 0) buffer.write(',');
    buffer.write(text[index]);
  }
  return buffer.toString();
}
