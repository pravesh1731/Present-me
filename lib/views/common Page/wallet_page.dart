import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/widgets/header.dart';
import '../viewmodels/student_auth/auth_event.dart';
import '../views/Student Screens/student Sidebar.dart';
import '../viewmodels/student_auth/auth_bloc.dart';
import '../viewmodels/student_auth/auth_state.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final box = GetStorage();
  int walletAmount = 0; // stored as whole rupees
  final TextEditingController _withdrawController = TextEditingController();

  StreamSubscription? _authSub;

  // Dummy history for now
  List<Map<String, String>> history = [
    {
      'title': 'Withdrawal',
      'amount': '-₹100',
      'date': '2026-09-01',
      'status': 'Completed',
    },
    {
      'title': 'Top-up',
      'amount': '+₹500',
      'date': '2026-08-18',
      'status': 'Completed',
    },
    {
      'title': 'Withdrawal',
      'amount': '-₹200',
      'date': '2026-07-30',
      'status': 'Failed',
    },
  ];

  @override
  void initState() {
    super.initState();

    // initial local load as fallback
    _loadWallet();

    // subscribe to AuthBloc stream after first frame so context.read works
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final authBloc = context.read<AuthBloc>();

        // set initial from bloc state if available
        final st = authBloc.state;
        if (st is AuthAuthenticated) {
          final w = int.tryParse((st.student['wallet'] ?? '0').toString()) ?? 0;
          setState(() => walletAmount = w);
        }

        _authSub = authBloc.stream.listen((state) {
          if (state is AuthAuthenticated) {
            final w = int.tryParse((state.student['wallet'] ?? '0').toString()) ?? 0;
            setState(() => walletAmount = w);
          }
        });
      } catch (e) {
        // no bloc provided; ignore
      }
    });
  }

  void _loadWallet() {
    try {
      final stored = box.read('student');
      if (stored is Map<String, dynamic>) {
        final int w = (stored['wallet'] is int)
            ? stored['wallet'] as int
            : int.tryParse((stored['wallet'] ?? '0').toString()) ?? 0;
        setState(() => walletAmount = w);
      }
    } catch (e) {
      // ignore
    }
  }

  void _saveWallet(int newAmount) {
    try {
      final stored = box.read('student');
      if (stored is Map<String, dynamic>) {
        final updated = Map<String, dynamic>.from(stored);
        updated['wallet'] = newAmount;
        box.write('student', updated);
      }
    } catch (e) {}

    // Also request a refresh of profile so other parts and the backend-backed state can propagate
    try {
      context.read<AuthBloc>().add(FetchProfileRequested());
    } catch (_) {}

    setState(() => walletAmount = newAmount);
  }

  Future<void> _showWithdrawDialog() async {
    _withdrawController.text = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Amount'),
        content: TextField(
          controller: _withdrawController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter amount in ₹'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _withdrawController.text.trim();
              final amt = int.tryParse(text);
              if (amt == null || amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              if (amt > walletAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insufficient balance')),
                );
                return;
              }

              // For now perform local withdrawal and add to dummy history
              final newBal = walletAmount - amt;
              _saveWallet(newBal);

              history.insert(0, {
                'title': 'Withdrawal',
                'amount': '-₹$amt',
                'date': DateTime.now().toIso8601String().split('T').first,
                'status': 'Completed',
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('₹$amt withdrawn — new balance ₹$newBal')),
              );
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _withdrawController.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
        Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 24,
          left: 24,
          right: 24,
        ),
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF06B6D4),
              Color(0xFF2563EB)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),

                  Text(
                    "Wallet",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹$walletAmount',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'In INR',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _showWithdrawDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Withdraw'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Transaction History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text('No transactions yet'))
                : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = history[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item['title'] == 'Top-up' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item['title'] == 'Top-up' ? Icons.add : Icons.arrow_upward,
                      color: item['title'] == 'Top-up' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(item['title'] ?? ''),
                  subtitle: Text(item['date'] ?? ''),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['amount'] ?? '',
                        style: TextStyle(
                          color: (item['amount'] ?? '').startsWith('+') ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['status'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ]
      ),

    );
  }
}
