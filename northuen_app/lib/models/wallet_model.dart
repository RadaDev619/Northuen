class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.reference,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String type;
  final num amount;
  final num balanceAfter;
  final String reference;
  final String note;
  final DateTime createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'],
        type: json['type'],
        amount: json['amount'],
        balanceAfter: json['balanceAfter'],
        reference: json['reference'],
        note: json['note'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class WalletAccount {
  WalletAccount({
    required this.id,
    required this.userId,
    required this.tokenBalance,
    required this.currency,
    required this.rechargeMode,
    required this.transactions,
  });

  final String id;
  final String userId;
  final num tokenBalance;
  final String currency;
  final String rechargeMode;
  final List<WalletTransaction> transactions;

  factory WalletAccount.fromJson(Map<String, dynamic> json) => WalletAccount(
    id: json['id'],
    userId: json['userId'],
    tokenBalance: json['tokenBalance'],
    currency: json['currency'],
    rechargeMode: json['rechargeMode'],
    transactions: ((json['transactions'] ?? []) as List)
        .map((item) => WalletTransaction.fromJson(item))
        .toList(),
  );
}
