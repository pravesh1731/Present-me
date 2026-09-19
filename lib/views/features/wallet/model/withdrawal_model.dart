class WithdrawalModel {
  final String withdrawalId;
  final String adminId;
  final String adminNote;
  final int amount;
  final String currency;
  final String institutionId;
  final DateTime? paidAt;
  final String paymentReferenceId;
  final DateTime? processedAt;
  final DateTime requestedAt;
  final String status;
  final DateTime updatedAt;
  final String upiId;
  final String userId;
  final String userRole;
  final String walletId;

  const WithdrawalModel({
    required this.withdrawalId,
    required this.adminId,
    required this.adminNote,
    required this.amount,
    required this.currency,
    required this.institutionId,
    required this.paidAt,
    required this.paymentReferenceId,
    required this.processedAt,
    required this.requestedAt,
    required this.status,
    required this.updatedAt,
    required this.upiId,
    required this.userId,
    required this.userRole,
    required this.walletId,
  });

  factory WithdrawalModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return WithdrawalModel(
      withdrawalId:
      json['withdrawalId']?.toString() ?? '',
      adminId:
      json['adminId']?.toString() ?? '',
      adminNote:
      json['adminNote']?.toString() ?? '',
      amount: int.tryParse(
        json['amount']?.toString() ?? '0',
      ) ??
          0,
      currency:
      json['currency']?.toString() ?? 'INR',
      institutionId:
      json['institutionId']?.toString() ?? '',
      paidAt: DateTime.tryParse(
        json['paidAt']?.toString() ?? '',
      ),
      paymentReferenceId:
      json['paymentReferenceId']?.toString() ?? '',
      processedAt: DateTime.tryParse(
        json['processedAt']?.toString() ?? '',
      ),
      requestedAt: DateTime.tryParse(
        json['requestedAt']?.toString() ??
            '',
      ) ??
          DateTime.now(),
      status:
      json['status']?.toString() ?? 'PENDING',
      updatedAt: DateTime.tryParse(
        json['updatedAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
      upiId:
      json['upiId']?.toString() ?? '',
      userId:
      json['userId']?.toString() ?? '',
      userRole:
      json['userRole']?.toString() ?? '',
      walletId:
      json['walletId']?.toString() ?? '',
    );
  }
}