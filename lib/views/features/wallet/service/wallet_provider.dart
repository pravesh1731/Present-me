import 'package:app/core/constants/constants.dart';
import 'package:app/views/features/wallet/service/wallet_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/wallet_model.dart';
import '../model/wallet_transaction_model.dart';
import '../model/withdrawal_model.dart';


final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(
    baseUrl: baseUrl,
  );
});

final walletBalanceProvider =
FutureProvider.autoDispose<WalletModel>((ref) async {
  final service = ref.read(walletServiceProvider);

  return service.getWalletBalance();
});

final walletTransactionsProvider =
FutureProvider.autoDispose<List<WalletTransactionModel>>(
      (ref) async {
    final service = ref.read(walletServiceProvider);

    return service.getWalletTransactions();
  },
);

final withdrawalsProvider =
FutureProvider.autoDispose<List<WithdrawalModel>>(
      (ref) async {
    final service =
    ref.read(walletServiceProvider);

    return service.getWithdrawals();
  },
);