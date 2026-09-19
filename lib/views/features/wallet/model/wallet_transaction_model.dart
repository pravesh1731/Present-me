class WalletTransactionModel {
  final String transactionId;
  final int amount;
  final DateTime createdAt;
  final String description;
  final String referenceId;
  final String source;
  final String status;
  final String type;
  final String userId;
  final String walletId;

  const WalletTransactionModel({
    required this.transactionId,
    required this.amount,
    required this.createdAt,
    required this.description,
    required this.referenceId,
    required this.source,
    required this.status,
    required this.type,
    required this.userId,
    required this.walletId,
  });

  factory WalletTransactionModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return WalletTransactionModel(
      transactionId:
      json['transactionId']?.toString() ?? '',
      amount: int.tryParse(
        json['amount']?.toString() ?? '0',
      ) ??
          0,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
      description:
      json['description']?.toString() ?? '',
      referenceId:
      json['referenceId']?.toString() ?? '',
      source:
      json['source']?.toString() ?? '',
      status:
      json['status']?.toString() ?? '',
      type:
      json['type']?.toString() ?? '',
      userId:
      json['userId']?.toString() ?? '',
      walletId:
      json['walletId']?.toString() ?? '',
    );
  }
}