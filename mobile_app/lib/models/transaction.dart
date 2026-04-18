class Transaction {
  final String? id;
  final String userId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? customCategory;
  final String description;
  final DateTime date;
  final String? receiptImage;
  final String? receiptImageId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    this.userId = '',
    required this.type,
    required this.amount,
    required this.category,
    this.customCategory,
    this.description = '',
    required this.date,
    this.receiptImage,
    this.receiptImageId,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'],
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'expense',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      customCategory: json['customCategory'],
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      receiptImage: json['receiptImage'],
      receiptImageId: json['receiptImageId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
      'amount': amount,
      'category': category,
      'customCategory': customCategory,
      'description': description,
      'date': date.toIso8601String(),
      'receiptImage': receiptImage,
      'receiptImageId': receiptImageId,
    };
    
    if (id != null) map['_id'] = id;
    if (userId.isNotEmpty) map['userId'] = userId;
    
    return map;
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? type,
    double? amount,
    String? category,
    String? customCategory,
    String? description,
    DateTime? date,
    String? receiptImage,
    String? receiptImageId,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      description: description ?? this.description,
      date: date ?? this.date,
      receiptImage: receiptImage ?? this.receiptImage,
      receiptImageId: receiptImageId ?? this.receiptImageId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
