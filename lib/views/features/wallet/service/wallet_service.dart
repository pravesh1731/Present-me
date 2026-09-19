import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/constants.dart';
import '../model/wallet_model.dart';
import '../model/wallet_transaction_model.dart';
import '../model/withdrawal_model.dart';

class WalletService {
  WalletService({
    required this.baseUrl,
  });

  final String baseUrl;

  final GetStorage _storage = GetStorage();

  Future<WalletModel> getWalletBalance() async {
    final token = _storage.read('token')?.toString() ?? '';

    if (token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/wallet/balance'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid wallet response');
      }

      return WalletModel.fromJson(data);
    }

    throw Exception(
      body['message']?.toString() ??
          'Failed to fetch wallet balance',
    );
  }


  Future<List<WalletTransactionModel>> getWalletTransactions() async {
    final token = _storage.read('token')?.toString() ?? '';

    if (token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/wallet/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid transaction response');
      }

      return data
          .map(
            (item) => WalletTransactionModel.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList();
    }

    throw Exception(
      body['message']?.toString() ??
          'Failed to fetch wallet transactions',
    );
  }


  Future<List<WithdrawalModel>> getWithdrawals() async {
    final token = _storage.read('token')?.toString() ?? '';

    if (token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/wallet/withdrawals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 &&
        body['success'] == true) {
      final data = body['data'];

      if (data is! List) {
        throw Exception(
          'Invalid withdrawal response',
        );
      }

      return data
          .map(
            (item) => WithdrawalModel.fromJson(
          Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList();
    }

    throw Exception(
      body['message']?.toString() ??
          'Failed to fetch withdrawal requests',
    );
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String upiId,
  }) async {
    final token = _storage.read('token')?.toString() ?? '';

    if (token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/withdrawal/request'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'upiId': upiId.trim().toLowerCase(),
      }),
    );

    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 ||
        response.statusCode == 201) &&
        body['success'] == true) {
      return body;
    }

    throw Exception(
      body['message']?.toString() ??
          'Failed to submit withdrawal request',
    );
  }
}

