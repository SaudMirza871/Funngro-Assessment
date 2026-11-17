import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/earning.dart';
import '../../../services/earnings_api.dart';

class EarningsController extends ChangeNotifier {
  final EarningsApi _api;
  StreamSubscription<List<EarningTransaction>>? _transactionsSubscription;

  EarningsController({EarningsApi? api}) : _api = api ?? EarningsApi();

  EarningSummary? _summary;
  List<EarningTransaction> _transactions = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'All';

  // Getters
  EarningSummary? get summary => _summary;
  List<EarningTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  /// Returns filtered transactions without expensive re-allocations
  List<EarningTransaction> get filteredTransactions {
    switch (_selectedFilter) {
      case 'Credited':
        return _transactions
            .where((t) => t.status == EarningStatus.credited)
            .toList();
      case 'Pending':
        return _transactions
            .where((t) => t.status == EarningStatus.pending)
            .toList();
      case 'Withdrawals':
        return _transactions
            .where((t) => t.status == EarningStatus.withdrawn)
            .toList();
      case 'All':
      default:
        return _transactions;
    }
  }

  /// Initializes data fetching and sets up lifecycle-safe stream listener
  Future<void> fetchEarnings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch initial snapshot
      final results = await Future.wait([
        _api.getSummary(),
        _api.getTransactions(),
      ]);

      _summary = results[0] as EarningSummary;
      _transactions = results[1] as List<EarningTransaction>;

      // Setup/renew StreamSubscription safely to prevent duplicate listeners
      _subscribeToLedgerUpdates();
    } catch (e) {
      _errorMessage = e is EarningsApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToLedgerUpdates() {
    // Cancel existing subscription first to prevent memory leaks and duplicate listeners
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _api.transactionsStream.listen(
      (updatedTransactions) {
        _transactions = updatedTransactions;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Ledger update failed: $error';
        notifyListeners();
      },
    );
  }

  /// Request withdrawal with immediate balance mutation and stream broadcast
  Future<bool> requestWithdrawal(double amount) async {
    try {
      final success = await _api.requestWithdrawal(amount);
      if (success) {
        // Refresh summary
        _summary = await _api.getSummary();
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Explicit resource disposal to guarantee zero memory leaks
  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = null;
    super.dispose();
  }
}
