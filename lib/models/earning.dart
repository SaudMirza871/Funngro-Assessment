enum EarningStatus { credited, pending, withdrawn }

extension EarningStatusExtension on EarningStatus {
  String get label {
    switch (this) {
      case EarningStatus.credited:
        return 'Credited';
      case EarningStatus.pending:
        return 'Pending';
      case EarningStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

enum TransactionType { credit, debit }

class EarningTransaction {
  final String id;
  final String title;
  final String company;
  final double amount;
  final DateTime date;
  final EarningStatus status;
  final TransactionType type;
  final String referenceId;

  const EarningTransaction({
    required this.id,
    required this.title,
    required this.company,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    required this.referenceId,
  });

  factory EarningTransaction.fromJson(Map<String, dynamic> json) {
    return EarningTransaction(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      status: EarningStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EarningStatus.credited,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.credit,
      ),
      referenceId: json['referenceId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status.name,
      'type': type.name,
      'referenceId': referenceId,
    };
  }
}

class EarningSummary {
  final double availableBalance;
  final double totalEarned;
  final double pendingPayout;
  final int completedProjects;

  const EarningSummary({
    required this.availableBalance,
    required this.totalEarned,
    required this.pendingPayout,
    required this.completedProjects,
  });

  EarningSummary copyWith({
    double? availableBalance,
    double? totalEarned,
    double? pendingPayout,
    int? completedProjects,
  }) {
    return EarningSummary(
      availableBalance: availableBalance ?? this.availableBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      completedProjects: completedProjects ?? this.completedProjects,
    );
  }

  factory EarningSummary.fromJson(Map<String, dynamic> json) {
    return EarningSummary(
      availableBalance: (json['availableBalance'] as num).toDouble(),
      totalEarned: (json['totalEarned'] as num).toDouble(),
      pendingPayout: (json['pendingPayout'] as num).toDouble(),
      completedProjects: json['completedProjects'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availableBalance': availableBalance,
      'totalEarned': totalEarned,
      'pendingPayout': pendingPayout,
      'completedProjects': completedProjects,
    };
  }
}
