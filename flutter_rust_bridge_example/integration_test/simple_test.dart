import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rust_bridge_example/main.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/amount.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/notes.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/progress.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/simple.dart';
import 'package:flutter_rust_bridge_example/src/rust/api/total.dart';
import 'package:flutter_rust_bridge_example/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  testWidgets('shows the sync greeting from Rust', (tester) async {
    await tester.pumpWidget(const RustBridgeApp());
    expect(find.text('Hello, Tom!'), findsOneWidget);
  });

  test('parses yuan into cents and rejects blank input', () async {
    expect(await parseCents(raw: '12.5'), 1250);
    await expectLater(
      parseCents(raw: '   '),
      throwsA(
        isA<AmountError>().having(
          (error) => error.kind,
          'kind',
          AmountErrorKind.empty,
        ),
      ),
    );
  });

  test('summarizes notes', () async {
    final result = await report(
      notes: const [
        Note(title: '买菜', priority: Priority.normal),
        Note(title: '报销', priority: Priority.high),
      ],
    );
    expect(result.total, 2);
    expect(result.high, 1);
    expect(result.headline, '共 2 条，其中 1 条高优先级：买菜、报销');
  });

  test('keeps ledger state in Rust', () {
    final ledger = Ledger();
    addTearDown(ledger.dispose);
    ledger.deposit(yuan: 12.5);
    ledger.deposit(yuan: 0.2);
    expect(ledger.balance, closeTo(12.7, 0.001));
    expect(ledger.entries, 2);
    ledger.reset();
    expect(ledger.balance, 0);
  });

  test('counts primes away from the UI thread', () async {
    final result = await countPrimes(limit: 1000);
    expect(result.primes, 168);
  });

  test('streams countdown events', () async {
    expect(await countDown(start: 1).toList(), [1, 0]);
  });
}
