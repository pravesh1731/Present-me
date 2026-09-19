import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/withdrawal_model.dart';
import '../service/wallet_provider.dart';

class WithdrawalRequestsPage extends ConsumerStatefulWidget {
  const WithdrawalRequestsPage({
    super.key,
  });

  @override
  ConsumerState<WithdrawalRequestsPage>
  createState() =>
      _WithdrawalRequestsPageState();
}

class _WithdrawalRequestsPageState
    extends ConsumerState<WithdrawalRequestsPage> {
  @override
  Widget build(BuildContext context) {
    final withdrawalsAsync =
    ref.watch(withdrawalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF3B4FE0),
              onRefresh: () async {
                await ref.refresh(
                  withdrawalsProvider.future,
                );
              },
              child: SingleChildScrollView(
                physics:
                const AlwaysScrollableScrollPhysics(
                  parent:
                  BouncingScrollPhysics(),
                ),
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                child: withdrawalsAsync.when(
                  loading: () {
                    return _buildLoading();
                  },
                  error: (error, stack) {
                    return _buildError();
                  },
                  data: (withdrawals) {
                    return _buildWithdrawals(
                      withdrawals,
                    );
                  },
                ),
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
        top:
        MediaQuery.of(context).padding.top +
            14,
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
                color:
                Colors.white.withOpacity(0.17),
                borderRadius:
                BorderRadius.circular(14),
                border: Border.all(
                  color:
                  Colors.white.withOpacity(0.18),
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
              'Withdrawal Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
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
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF3B4FE0),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFE11D48),
          ),

          const SizedBox(height: 10),

          const Text(
            'Unable to load withdrawal requests',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          GestureDetector(
            onTap: () {
              ref.invalidate(
                withdrawalsProvider,
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
  }

  // ============================================================
  // WITHDRAWALS
  // ============================================================

  Widget _buildWithdrawals(
      List<WithdrawalModel> withdrawals,
      ) {
    if (withdrawals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 55,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 45,
              color: Color(0xFFCBD5E1),
            ),

            SizedBox(height: 12),

            Text(
              'No withdrawal requests yet',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummary(withdrawals),

        const SizedBox(height: 14),

        ...withdrawals.map(
              (withdrawal) =>
              _buildWithdrawalCard(
                withdrawal,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
      List<WithdrawalModel> withdrawals,
      ) {
    final total =
    withdrawals.fold<int>(
      0,
          (sum, item) => sum + item.amount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF3B4FE0),
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Withdrawal Requests',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${withdrawals.length}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF11183F),
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹$total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF11183F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WITHDRAWAL CARD
  // ============================================================

  Widget _buildWithdrawalCard(
      WithdrawalModel withdrawal,
      ) {
    final status =
    withdrawal.status.toUpperCase();

    Color statusBg;
    Color statusColor;

    switch (status) {
      case 'PAID':
        statusBg = const Color(0xFFE7F8F1);
        statusColor =
        const Color(0xFF059669);
        break;

      case 'PENDING':
        statusBg =
        const Color(0xFFFFF3D6);
        statusColor =
        const Color(0xFFD97706);
        break;

      case 'PROCESSING':
        statusBg =
        const Color(0xFFEFF6FF);
        statusColor =
        const Color(0xFF2563EB);
        break;

      case 'REJECTED':
      case 'FAILED':
      case 'CANCELLED':
        statusBg =
        const Color(0xFFFFE4E6);
        statusColor =
        const Color(0xFFE11D48);
        break;

      default:
        statusBg =
        const Color(0xFFF1F5F9);
        statusColor =
        const Color(0xFF64748B);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFFFE8EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Color(0xFFE11D48),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdrawal Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF11183F),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatDate(
                        withdrawal.requestedAt,
                      ),
                      style: const TextStyle(
                        fontSize: 10,
                        color:
                        Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    '-₹${withdrawal.amount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFFE11D48),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color: statusBg,
                      borderRadius:
                      BorderRadius.circular(
                        999,
                      ),
                    ),
                    child: Text(
                      _formatStatus(status),
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

          const SizedBox(height: 14),

          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),

          const SizedBox(height: 13),

          // UPI
          _buildInfoRow(
            Icons.alternate_email_rounded,
            'UPI ID',
            withdrawal.upiId,
          ),

          const SizedBox(height: 9),

          // Requested
          _buildInfoRow(
            Icons.schedule_rounded,
            'Requested',
            _formatDateTime(
              withdrawal.requestedAt,
            ),
          ),

          // Paid information
          if (withdrawal.paidAt != null) ...[
            const SizedBox(height: 9),

            _buildInfoRow(
              Icons.check_circle_outline_rounded,
              'Paid',
              _formatDateTime(
                withdrawal.paidAt!,
              ),
            ),
          ],

          // Payment reference
          if (withdrawal.paymentReferenceId
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 9),

            _buildInfoRow(
              Icons.receipt_long_outlined,
              'Payment Ref.',
              withdrawal.paymentReferenceId,
            ),
          ],

          // Admin note
          if (withdrawal.adminNote
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color:
                const Color(0xFFF8FAFC),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color:
                    Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Note',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          withdrawal.adminNote,
                          style:
                          const TextStyle(
                            fontSize: 11,
                            color:
                            Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: const Color(0xFF64748B),
        ),

        const SizedBox(width: 7),

        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return 'Unknown';
    }

    final lower = status.toLowerCase();

    return lower[0].toUpperCase() +
        lower.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour =
    date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
    date.minute.toString().padLeft(
      2,
      '0',
    );

    final period =
    date.hour >= 12 ? 'PM' : 'AM';

    return '${_formatDate(date)} '
        '$hour:$minute $period';
  }
}