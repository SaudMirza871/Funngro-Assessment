import 'dart:async';
import '../models/earning.dart';

class EarningsApiException implements Exception {
  final String message;
  const EarningsApiException(this.message);

  @override
  String toString() => 'EarningsApiException: $message';
}

class EarningsApi {
  static const Duration _simulatedLatency = Duration(milliseconds: 600);

  EarningSummary _summary = const EarningSummary(
    availableBalance: 8750,
    totalEarned: 24500,
    pendingPayout: 3200,
    completedProjects: 8,
  );

  late final List<EarningTransaction> _transactions;
  final StreamController<List<EarningTransaction>>
  _transactionsStreamController =
      StreamController<List<EarningTransaction>>.broadcast();

  final bool enableFailures;
  final bool? forceFailure;

  EarningsApi({
    this.enableFailures = false,
    this.forceFailure,
    int initialCount =
        3000, // Meets requirement to handle large lists of 3,000+ items
  }) {
    _transactions = _generateTransactions(initialCount);
  }

  static List<EarningTransaction> _generateTransactions(int count) {
    final list = <EarningTransaction>[];
    final titles = [
      'Payment for Social Media Content',
      'Bonus for Timely Delivery',
      'Mobile App UI Mockups Milestone',
      'Reels Video Editing Payout',
      'Campus Research Survey Submission',
      'SEO Blog Article Approval',
      'Withdrawal to Bank Account (UPI)',
      'Contest Prize Credit',
    ];

    final companies = [
      'EcoVibe Organics',
      'NextGen Ventures',
      'SkillUp Academy',
      'FinBud Fintech',
      'YouthPulse Insights',
      'GameCraft Studios',
      'Self Withdrawal',
    ];

    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final isWithdrawal = i % 7 == 6;
      final status = isWithdrawal
          ? EarningStatus.withdrawn
          : (i % 5 == 0 ? EarningStatus.pending : EarningStatus.credited);
      final type = isWithdrawal
          ? TransactionType.debit
          : TransactionType.credit;
      final amt = isWithdrawal
          ? 2000.0 + ((i * 100) % 3000)
          : 1500.0 + ((i * 150) % 4000);

      list.add(
        EarningTransaction(
          id: 'tx-${(count - i).toString().padLeft(5, '0')}',
          title: isWithdrawal
              ? 'Bank Withdrawal (UPI/IMPS)'
              : titles[i % titles.length],
          company: isWithdrawal
              ? 'Self Withdrawal'
              : companies[i % companies.length],
          amount: amt,
          date: now.subtract(Duration(hours: i * 4)),
          status: status,
          type: type,
          referenceId: 'UPI/2026/${(10000 + i % 90000)}',
        ),
      );
    }
    return list;
  }

  /// Exposes a broadcast stream for real-time ledger updates
  Stream<List<EarningTransaction>> get transactionsStream =>
      _transactionsStreamController.stream;

  Future<EarningSummary> getSummary() async {
    await Future.delayed(_simulatedLatency);
    if (forceFailure == true) {
      throw const EarningsApiException('Failed to load wallet balance.');
    }
    return _summary;
  }

  Future<List<EarningTransaction>> getTransactions() async {
    await Future.delayed(_simulatedLatency);
    if (forceFailure == true) {
      throw const EarningsApiException(
        'Network failure while fetching transaction ledger.',
      );
    }
    // Return unmodifiable list copy
    return List<EarningTransaction>.unmodifiable(_transactions);
  }

  Future<bool> requestWithdrawal(double amount) async {
    await Future.delayed(_simulatedLatency);
    if (amount <= 0 || amount > _summary.availableBalance) {
      return false;
    }

    _summary = _summary.copyWith(
      availableBalance: _summary.availableBalance - amount,
    );

    final newTx = EarningTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Bank Withdrawal Request',
      company: 'Self Withdrawal',
      amount: amount,
      date: DateTime.now(),
      status: EarningStatus.withdrawn,
      type: TransactionType.debit,
      referenceId: 'UPI/${DateTime.now().millisecondsSinceEpoch % 100000}',
    );

    _transactions.insert(0, newTx);
    _transactionsStreamController.add(List.unmodifiable(_transactions));
    return true;
  }

  void dispose() {
    _transactionsStreamController.close();
  }
}
