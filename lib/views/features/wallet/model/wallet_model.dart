class WalletModel {
  final String walletId;
  final String userId;
  final int balance;
  final String currency;

  const WalletModel({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['walletId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balance: int.tryParse(
        json['balance']?.toString() ?? '0',
      ) ??
          0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}