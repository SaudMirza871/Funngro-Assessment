import 'package:flutter_test/flutter_test.dart';
import 'package:funngro_assessment/features/earnings/controllers/earnings_controller.dart';
import 'package:funngro_assessment/services/earnings_api.dart';

void main() {
  group('EarningsController Tests', () {
    late EarningsApi api;
    late EarningsController controller;

    setUp(() {
      api = EarningsApi(initialCount: 3000);
      controller = EarningsController(api: api);
    });

    tearDown(() {
      controller.dispose();
      api.dispose();
    });

    test('Loads 3,000+ transaction ledger and summary successfully', () async {
      await controller.fetchEarnings();

      expect(controller.summary, isNotNull);
      expect(controller.summary!.availableBalance, equals(8750));
      expect(controller.transactions.length, equals(3000));
      expect(controller.errorMessage, isNull);
    });

    test('Filters transactions correctly by category', () async {
      await controller.fetchEarnings();

      controller.setFilter('Credited');
      expect(
        controller.filteredTransactions.every(
          (t) => t.status.name == 'credited',
        ),
        isTrue,
      );

      controller.setFilter('Pending');
      expect(
        controller.filteredTransactions.every(
          (t) => t.status.name == 'pending',
        ),
        isTrue,
      );

      controller.setFilter('Withdrawals');
      expect(
        controller.filteredTransactions.every(
          (t) => t.status.name == 'withdrawn',
        ),
        isTrue,
      );
    });

    test(
      'Withdrawal request mutates available balance and emits update',
      () async {
        await controller.fetchEarnings();
        final initialBalance = controller.summary!.availableBalance;

        final success = await controller.requestWithdrawal(2000);
        expect(success, isTrue);

        expect(
          controller.summary!.availableBalance,
          equals(initialBalance - 2000),
        );
        expect(controller.transactions.length, equals(3001));
        expect(controller.transactions.first.title, contains('Withdrawal'));
      },
    );
  });
}
