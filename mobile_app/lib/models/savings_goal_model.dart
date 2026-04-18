class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String userId;
  final String? familyId;
  final bool isFamilyGoal;
  final String status;
  final List<Contribution> contributions;
  final SavingsInsights insights;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.userId,
    this.familyId,
    required this.isFamilyGoal,
    required this.status,
    required this.contributions,
    required this.insights,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : DateTime.now(),
      userId: json['userId'] ?? '',
      familyId: json['familyId'],
      isFamilyGoal: json['isFamilyGoal'] ?? false,
      status: json['status'] ?? 'active',
      contributions: (json['contributions'] as List<dynamic>?)
              ?.map((c) => Contribution.fromJson(c))
              .toList() ??
          [],
      insights: SavingsInsights.fromJson(json['insights'] ?? {}),
    );
  }
}

class Contribution {
  final String userId;
  final double amount;
  final DateTime date;
  final String note;

  Contribution({
    required this.userId,
    required this.amount,
    required this.date,
    required this.note,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      note: json['note'] ?? '',
    );
  }
}

class SavingsInsights {
  final int progressPercentage;
  final int daysRemaining;
  final double amountNeeded;
  final double dailyNeeded;
  final double weeklyNeeded;
  final double monthlyNeeded;
  final String motivation;

  SavingsInsights({
    required this.progressPercentage,
    required this.daysRemaining,
    required this.amountNeeded,
    required this.dailyNeeded,
    required this.weeklyNeeded,
    required this.monthlyNeeded,
    required this.motivation,
  });

  factory SavingsInsights.fromJson(Map<String, dynamic> json) {
    return SavingsInsights(
      progressPercentage: json['progressPercentage'] ?? 0,
      daysRemaining: json['daysRemaining'] ?? 0,
      amountNeeded: (json['amountNeeded'] as num?)?.toDouble() ?? 0.0,
      dailyNeeded: double.tryParse(json['dailyNeeded']?.toString() ?? '0') ?? 0.0,
      weeklyNeeded: double.tryParse(json['weeklyNeeded']?.toString() ?? '0') ?? 0.0,
      monthlyNeeded: double.tryParse(json['monthlyNeeded']?.toString() ?? '0') ?? 0.0,
      motivation: json['motivation'] ?? '',
    );
  }
}
