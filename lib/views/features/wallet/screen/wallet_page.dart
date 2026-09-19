import 'dart:async';
import 'package:app/views/features/wallet/screen/withdrawal_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/wallet_transaction_model.dart';
import '../service/wallet_provider.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {


  final TextEditingController _withdrawController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  bool _isWithdrawalSubmitting = false;
  String? _amountError;
  String? _upiError;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _submitWithdrawal({
    required BuildContext modalContext,
    required double amount,
    required String upiId,
    required StateSetter setModalState,
  }) async {
    if (_isWithdrawalSubmitting) {
      return;
    }

    setModalState(() {
      _isWithdrawalSubmitting = true;
      _amountError = null;
      _upiError = null;
    });

    try {
      final service = ref.read(walletServiceProvider);

      final response = await service.requestWithdrawal(
        amount: amount,
        upiId: upiId,
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);

      Navigator.pop(modalContext);

      final responseData = response['data'];

      final submittedAmount =
      responseData is Map
          ? responseData['amount']?.toString() ??
          amount.toString()
          : amount.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Withdrawal request of ₹$submittedAmount submitted',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '');

      setModalState(() {
        _isWithdrawalSubmitting = false;

        // Server validation errors related to the amount
        if (errorMessage.toLowerCase().contains('amount') ||
            errorMessage.toLowerCase().contains('balance') ||
            errorMessage.toLowerCase().contains('insufficient') ||
            errorMessage.toLowerCase().contains('minimum')) {
          _amountError = errorMessage;
        }
        // Server validation errors related to UPI
        else if (errorMessage.toLowerCase().contains('upi')) {
          _upiError = errorMessage;
        }
        // Other errors can be shown on the amount field
        else {
          _amountError = errorMessage;
        }
      });
    }
  }

  String _transactionTitle(
      WalletTransactionModel transaction,
      ) {
    if (transaction.source.toUpperCase() ==
        'NOTE/PYQ_REWARD') {
      return 'PYQ Reward';
    }

    if (transaction.type.toUpperCase() ==
        'DEBIT') {
      return 'Withdrawal Request';
    }

    if (transaction.description.trim().isNotEmpty) {
      return transaction.description;
    }

    return transaction.type.toUpperCase() == 'CREDIT'
        ? 'Wallet Credit'
        : 'Wallet Debit';
  }

  String _transactionMethod(
      WalletTransactionModel transaction,
      ) {
    if (transaction.source.toUpperCase() ==
        'NOTE/PYQ_REWARD') {
      return 'Notes / PYQ Reward';
    }

    if (transaction.source.toUpperCase() ==
        'WITHDRAWAL') {
      return 'UPI Transfer';
    }

    if (transaction.description.trim().isNotEmpty) {
      return transaction.description;
    }

    return transaction.source;
  }

  String _formatTransactionStatus(
      String status,
      ) {
    if (status.trim().isEmpty) {
      return 'Unknown';
    }

    final value = status.toLowerCase();

    return value[0].toUpperCase() +
        value.substring(1);
  }

  String _formatTransactionDate(
      DateTime date,
      ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
  // ============================================================
  // WITHDRAWAL BOTTOM SHEET
  // ============================================================

  Future<void> _showWithdrawDialog() async {
    _withdrawController.clear();
    _upiController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius:
                              BorderRadius.circular(100),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Header
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: Color(0xFF2563EB),
                                size: 27,
                              ),
                            ),

                            const SizedBox(width: 14),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Withdraw Money',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Transfer your earnings to your UPI',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF64748B),
                                  size: 21,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Available balance
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF0F7FF),
                                Color(0xFFF5F3FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                            BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE0E7FF),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF3B4FE0),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Balance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Builder(
                                    builder: (context) {
                                      final walletAsync =
                                      ref.watch(walletBalanceProvider);

                                      return walletAsync.when(
                                        loading: () => const Text(
                                          'Loading...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        error: (_, __) => const Text(
                                          'Unavailable',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFE11D48),
                                          ),
                                        ),
                                        data: (wallet) => Text(
                                          '₹${wallet.balance}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Amount
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: _withdrawController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) {
                            if (_amountError != null) {
                              setModalState(() {
                                _amountError = null;
                              });
                            }
                          },
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: '₹ Enter amount',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                              color: Color(0xFF3B4FE0),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            errorText: _amountError,
                            errorStyle: const TextStyle(
                              color: Color(0xFFE11D48),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _amountError != null
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _amountError != null
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFF3B4FE0),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE11D48),
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE11D48),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Minimum withdrawal amount is ₹10',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Method
                        const Text(
                          'Withdrawal Method',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius:
                            BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF3B4FE0),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'UPI',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPI Transfer',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Instant transfer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFF3B4FE0),
                                    width: 5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // UPI ID
                        const Text(
                          'UPI ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: _upiController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) {
                            if (_upiError != null) {
                              setModalState(() {
                                _upiError = null;
                              });
                            }
                          },
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'yourname@upi',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            errorText: _upiError,
                            errorStyle: const TextStyle(
                              color: Color(0xFFE11D48),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _upiError != null
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _upiError != null
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFF3B4FE0),
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE11D48),
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE11D48),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 7),

                        const Text(
                          'Example: name@paytm, name@ybl',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Important notes
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF3B4FE0),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Important Notes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2635C7),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '• Minimum withdrawal amount is ₹10.\n'
                                          '• Requests are usually processed within 24 hours.\n'
                                          '• Make sure your UPI ID is correct.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.6,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Withdraw button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF6B4FE8),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius:
                              BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B4FE0)
                                      .withOpacity(0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isWithdrawalSubmitting
                                  ? null
                                  : () async {
                                final text = _withdrawController.text.trim();
                                final upi = _upiController.text.trim();

                                // Clear old errors
                                setModalState(() {
                                  _amountError = null;
                                  _upiError = null;
                                });

                                // ==============================
                                // AMOUNT VALIDATION
                                // ==============================

                                if (text.isEmpty) {
                                  setModalState(() {
                                    _amountError = 'Please enter an amount';
                                  });
                                  return;
                                }

                                final amt = double.tryParse(text);

                                if (amt == null || amt <= 0) {
                                  setModalState(() {
                                    _amountError = 'Enter a valid amount';
                                  });
                                  return;
                                }

                                if (amt < 10) {
                                  setModalState(() {
                                    _amountError =
                                    'Minimum withdrawal amount is ₹10';
                                  });
                                  return;
                                }

                                // Maximum 2 decimal places
                                final decimalPart =
                                text.contains('.') ? text.split('.').last : '';

                                if (decimalPart.length > 2) {
                                  setModalState(() {
                                    _amountError =
                                    'Amount can have maximum 2 decimal places';
                                  });
                                  return;
                                }

                                // ==============================
                                // UPI VALIDATION
                                // ==============================

                                if (upi.isEmpty) {
                                  setModalState(() {
                                    _upiError = 'Please enter your UPI ID';
                                  });
                                  return;
                                }

                                final upiRegex = RegExp(
                                  r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$',
                                );

                                if (!upiRegex.hasMatch(upi)) {
                                  setModalState(() {
                                    _upiError = 'Enter a valid UPI ID';
                                  });
                                  return;
                                }

                                // ==============================
                                // CHECK CURRENT BALANCE
                                // ==============================

                                final walletAsync =
                                ref.read(walletBalanceProvider);

                                final wallet = walletAsync.value;

                                if (wallet == null) {
                                  setModalState(() {
                                    _amountError =
                                    'Wallet balance is still loading';
                                  });
                                  return;
                                }

                                if (amt > wallet.balance) {
                                  setModalState(() {
                                    _amountError =
                                    'Insufficient wallet balance. Available: ₹${wallet.balance}';
                                  });
                                  return;
                                }

                                // ==============================
                                // API REQUEST
                                // ==============================

                                await _submitWithdrawal(
                                  modalContext: context,
                                  amount: amt,
                                  upiId: upi,
                                  setModalState: setModalState,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                ),
                              ),
                              child: _isWithdrawalSubmitting
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'Withdraw',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Security
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Your information is safe and secure',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _withdrawController.dispose();
    _upiController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16,16, 16, 28,),
              child: Column(
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 10),

                  _buildWithdrawButton(),

                  const SizedBox(height: 14),

                  _buildTransactionHeader(),

                  const SizedBox(height: 10),

                  _buildTransactionHistory(),

                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF06B6D4),
            Color(0xFF2563EB),
            Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.17),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              'Wallet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BALANCE CARD
  // ============================================================

  Widget _buildBalanceCard() {
    final walletAsync = ref.watch(walletBalanceProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: walletAsync.when(
        loading: () {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF3B4FE0),
                      ),
                    ),
                  ],
                ),
              ),
              _walletIcon(),
            ],
          );
        },

        error: (error, stack) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Unable to load balance',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ref.invalidate(walletBalanceProvider);
                      },
                      child: const Text(
                        'Tap to retry',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _walletIcon(),
            ],
          );
        },

        data: (wallet) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '₹${wallet.balance}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11183F),
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F8F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 15,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '+ Earnings',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _walletIcon(),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // WITHDRAW BUTTON
  // ============================================================

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2188FF),
              Color(0xFF4338CA),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B4FE0)
                  .withOpacity(0.28),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _showWithdrawDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 19,
              ),
              SizedBox(width: 9),
              Text(
                'Withdraw Money',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ============================================================
  // TRANSACTION HEADER
  // ============================================================

  Widget _buildTransactionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Transaction History',
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11183F),
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const WithdrawalRequestsPage(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'Withdrawal Request',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B4FE0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: Color(0xFF3B4FE0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRANSACTION HISTORY
  // ============================================================

  Widget _buildTransactionHistory() {
    final transactionsAsync =
    ref.watch(walletTransactionsProvider);

    return transactionsAsync.when(
      loading: () {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 45,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF3B4FE0),
              ),
            ),
          ),
        );
      },

      error: (error, stack) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 35,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: Color(0xFFE11D48),
              ),

              const SizedBox(height: 10),

              const Text(
                'Unable to load transactions',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: () {
                  ref.invalidate(
                    walletTransactionsProvider,
                  );
                },
                child: const Text(
                  'Tap to retry',
                  style: TextStyle(
                    color: Color(0xFF3B4FE0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },

      data: (transactions) {
        if (transactions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 45,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Color(0xFFCBD5E1),
                ),
                SizedBox(height: 10),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => Container(
              height: 1,
              color: const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final transaction =
              transactions[index];

              final isCredit =
                  transaction.type.toUpperCase() ==
                      'CREDIT';

              final amount =
                  '${isCredit ? '+' : '-'}₹${transaction.amount}';

              final status =
              _formatTransactionStatus(
                transaction.status,
              );

              final date =
              _formatTransactionDate(
                transaction.createdAt,
              );

              final title =
              _transactionTitle(transaction);

              final method =
              _transactionMethod(transaction);

              Color statusBg;
              Color statusColor;

              if (transaction.status
                  .toUpperCase() ==
                  'COMPLETED') {
                statusBg =
                const Color(0xFFE7F8F1);
                statusColor =
                const Color(0xFF059669);
              } else if (transaction.status
                  .toUpperCase() ==
                  'PENDING') {
                statusBg =
                const Color(0xFFFFF3D6);
                statusColor =
                const Color(0xFFD97706);
              } else {
                statusBg =
                const Color(0xFFFFE4E6);
                statusColor =
                const Color(0xFFE11D48);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // SAME ICON CONTAINER
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCredit
                            ? const Color(0xFFE5F8F1)
                            : const Color(0xFFFFE8EC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit
                            ? Icons
                            .arrow_downward_rounded
                            : Icons
                            .arrow_upward_rounded,
                        color: isCredit
                            ? const Color(0xFF059669)
                            : const Color(0xFFE11D48),
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF11183F),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            method,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color:
                              Color(0xFF64748B),
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 10,
                              color:
                              Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                          amount,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w800,
                            color: isCredit
                                ? const Color(
                              0xFF059669,
                            )
                                : const Color(
                              0xFFE11D48,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius:
                            BorderRadius.circular(
                              999,
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                              FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

}

Widget _walletIcon() {
  return Container(
    width: 74,
    height: 74,
    decoration: const BoxDecoration(
      color: Color(0xFFF1F5FF),
      shape: BoxShape.circle,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 43,
          height: 33,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2563EB),
                Color(0xFF4F46E5),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        Positioned(
          top: 13,
          right: 13,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                '₹',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}