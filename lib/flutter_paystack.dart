library flutter_paystack;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

part 'models/payment_models.dart';
part 'widgets/kenya_payment_widget.dart';
part 'widgets/payment_method_selector.dart';
part 'utils/payment_utils.dart';

/// PaystackPlugin class for backward compatibility
/// This provides the same interface as the official flutter_paystack package
class PaystackPlugin {
  static const String _baseUrl = 'https://api.paystack.co';
  String? _publicKey;
  String? _country;

  /// Initialize Paystack with your public key
  Future<void> initialize({required String publicKey, String? country}) async {
    _publicKey = publicKey;
    _country = country ?? 'KE';
  }

  /// Access the public key
  String? get publicKey => _publicKey;

  /// Check if plugin is initialized
  bool get isInitialized => _publicKey != null;
}

/// Enhanced Flutter Paystack with comprehensive Kenya support
class FlutterPaystack {
  static const String _baseUrl = 'https://api.paystack.co';
  static late BuildContext _context;
  static late String _publicKey;
  static late String _country;
  static late String _currency;

  /// Initialize Paystack for Kenya-focused payments
  static Future<void> initialize({
    required BuildContext context,
    required String publicKey,
    String country = 'KE',
    String currency = 'KES',
  }) async {
    _context = context;
    _publicKey = publicKey;
    _country = country;
    _currency = currency;

    // Initialize standalone Paystack client
    await _initializePaystackClient(publicKey, country, currency);
  }

  /// Process Kenya mobile money payment with auto-detection
  static Future<PaymentResult> processKenyaPayment({
    required double amount,
    required String email,
    required String reference,
    String? phoneNumber,
    PaymentMethod? preferredMethod,
    Map<String, dynamic>? metadata,
  }) async {
    if (_country != 'KE') {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Kenya payment methods require country: KE',
      );
    }

    // Auto-detect best payment method if not specified
    final method = preferredMethod ?? _detectBestPaymentMethod(
      amount: amount,
      phoneNumber: phoneNumber,
    );

    switch (method) {
      case PaymentMethod.mpesaStkPush:
        return await _processMpesaStkPush(
          amount: amount,
          email: email,
          reference: reference,
          phoneNumber: phoneNumber,
          metadata: metadata,
        );
      case PaymentMethod.mpesaPaybill:
        return await _processMpesaPaybill(
          amount: amount,
          email: email,
          reference: reference,
          metadata: metadata,
        );
      case PaymentMethod.airtelMoney:
        return await _processAirtelMoney(
          amount: amount,
          email: email,
          reference: reference,
          phoneNumber: phoneNumber,
          metadata: metadata,
        );
      case PaymentMethod.pesalink:
        return await _processPesalink(
          amount: amount,
          email: email,
          reference: reference,
          metadata: metadata,
        );
      default:
        return await _processCardPayment(
          amount: amount,
          email: email,
          reference: reference,
          metadata: metadata,
        );
    }
  }

  /// Process M-PESA STK Push payment
  static Future<PaymentResult> _processMpesaStkPush({
    required double amount,
    required String email,
    required String reference,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (phoneNumber == null || phoneNumber.isEmpty) {
        return PaymentResult(
          status: PaymentStatus.failed,
          message: 'Phone number required for M-PESA STK Push',
        );
      }

      final request = PaymentRequest(
        amount: amount,
        email: email,
        reference: reference,
        secretKey: _publicKey,
        currency: _currency,
        country: _country,
        phoneNumber: phoneNumber.startsWith('+254') 
            ? phoneNumber 
            : '+254${phoneNumber.replaceAll(RegExp(r'[^0-9]'), '')}',
        metadata: metadata ?? {
          'payment_method': 'mpesa_stk_push',
          'transaction_type': 'individual_customer_charge',
        },
      );

      final result = await FlutterPaystackPlus.chargeCard(
        context: _context,
        request: request,
      );

      return PaymentResult(
        status: _mapPaymentStatus(result.status),
        message: result.message,
        reference: result.reference,
        transactionId: result.transactionId,
        amount: result.amount,
        fees: result.fees,
        verified: result.verified,
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'M-PESA STK Push failed: $e',
      );
    }
  }

  /// Process M-PESA Paybill payment
  static Future<PaymentResult> _processMpesaPaybill({
    required double amount,
    required String email,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = PaymentRequest(
        amount: amount,
        email: email,
        reference: reference,
        secretKey: _publicKey,
        currency: _currency,
        country: _country,
        metadata: metadata ?? {
          'payment_method': 'mpesa_paybill',
          'mobile_money_provider': 'mpesa_offline',
          'account_number': '700000', // Paystack's Paybill number
          'account_reference': reference,
        },
      );

      final result = await FlutterPaystackPlus.chargeCard(
        context: _context,
        request: request,
      );

      return PaymentResult(
        status: _mapPaymentStatus(result.status),
        message: 'M-PESA Paybill initiated. Please complete payment on your phone.',
        reference: result.reference,
        transactionId: result.transactionId,
        amount: result.amount,
        fees: result.fees,
        verified: result.verified,
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'M-PESA Paybill failed: $e',
      );
    }
  }

  /// Process Airtel Money payment
  static Future<PaymentResult> _processAirtelMoney({
    required double amount,
    required String email,
    required String reference,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = PaymentRequest(
        amount: amount,
        email: email,
        reference: reference,
        secretKey: _publicKey,
        currency: _currency,
        country: _country,
        phoneNumber: phoneNumber,
        metadata: metadata ?? {
          'payment_method': 'airtel_money',
          'mobile_money_provider': 'atl',
        },
      );

      final result = await FlutterPaystackPlus.chargeCard(
        context: _context,
        request: request,
      );

      return PaymentResult(
        status: _mapPaymentStatus(result.status),
        message: result.message,
        reference: result.reference,
        transactionId: result.transactionId,
        amount: result.amount,
        fees: result.fees,
        verified: result.verified,
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Airtel Money payment failed: $e',
      );
    }
  }

  /// Process Pesalink bank transfer
  static Future<PaymentResult> _processPesalink({
    required double amount,
    required String email,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Pesalink requires specific API call
      final bankTransferData = {
        'type': 'bank_transfer',
        'account_expires_at': DateTime.now().add(Duration(minutes: 25)).toUtc().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/charge'),
        headers: {
          'Authorization': 'Bearer $_publicKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'amount': (amount * 100).round(), // Amount in kobo
          'currency': _currency,
          'reference': reference,
          'bank_transfer': bankTransferData,
          'metadata': metadata ?? {
            'payment_method': 'pesalink',
            'payment_type': 'bank_transfer',
            'transaction_reference': reference,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bankTransfer = data['data']['bank_transfer'];
        
        return PaymentResult(
          status: PaymentStatus.pending,
          message: 'Pesalink transfer initiated. Use the account details below to complete payment.',
          reference: reference,
          amount: amount,
          metadata: {
            'account_number': bankTransfer['account_number'],
            'account_name': bankTransfer['account_name'],
            'bank_name': 'Diamond Trust Bank',
            'transaction_reference': reference,
            'account_expires_at': bankTransfer['account_expires_at'],
          },
        );
      } else {
        return PaymentResult(
          status: PaymentStatus.failed,
          message: 'Pesalink initialization failed: ${response.body}',
        );
      }
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Pesalink payment failed: $e',
      );
    }
  }

  /// Process card payment (fallback)
  static Future<PaymentResult> _processCardPayment({
    required double amount,
    required String email,
    required String reference,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final request = PaymentRequest(
        amount: amount,
        email: email,
        reference: reference,
        secretKey: _publicKey,
        currency: _currency,
        country: _country,
        metadata: metadata ?? {
          'payment_method': 'card',
        },
      );

      final result = await FlutterPaystackPlus.chargeCard(
        context: _context,
        request: request,
      );

      return PaymentResult(
        status: _mapPaymentStatus(result.status),
        message: result.message,
        reference: result.reference,
        transactionId: result.transactionId,
        amount: result.amount,
        fees: result.fees,
        verified: result.verified,
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Card payment failed: $e',
      );
    }
  }

  /// Auto-detect best payment method for Kenya
  static PaymentMethod _detectBestPaymentMethod({
    required double amount,
    String? phoneNumber,
  }) {
    // High-value transactions (>50,000 KES) - prefer Pesalink
    if (amount >= 50000) {
      return PaymentMethod.pesalink;
    }
    
    // If phone number provided, prefer mobile money
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (phoneNumber.startsWith('+254') || 
          phoneNumber.startsWith('254') || 
          phoneNumber.startsWith('07')) {
        return PaymentMethod.mpesaStkPush;
      }
    }
    
    // Medium amounts - prefer mobile money
    if (amount >= 1000) {
      return PaymentMethod.mpesaStkPush;
    }
    
    // Low amounts - card payment
    return PaymentMethod.card;
  }

  /// Get available payment methods for the current amount and context
  static List<PaymentMethod> getAvailablePaymentMethods({
    required double amount,
    String? phoneNumber,
  }) {
    final methods = <PaymentMethod>[];
    
    // Always available
    methods.add(PaymentMethod.card);
    
    // Kenya-specific methods
    if (_country == 'KE') {
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        methods.addAll([
          PaymentMethod.mpesaStkPush,
          PaymentMethod.airtelMoney,
        ]);
      }
      
      methods.addAll([
        PaymentMethod.mpesaPaybill,
        PaymentMethod.pesalink,
      ]);
    }
    
    return methods;
  }

  /// Verify transaction status
  static Future<PaymentResult> verifyTransaction(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer $_publicKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transaction = data['data'];
        
        return PaymentResult(
          status: _mapTransactionStatus(transaction['status']),
          message: transaction['gateway_response'],
          reference: transaction['reference'],
          transactionId: transaction['id'].toString(),
          amount: transaction['amount'] / 100.0,
          fees: transaction['fees'] / 100.0,
          verified: transaction['status'] == 'success',
        );
      } else {
        return PaymentResult(
          status: PaymentStatus.failed,
          message: 'Transaction verification failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.failed,
        message: 'Verification error: $e',
      );
    }
  }

  static PaymentStatus _mapPaymentStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'success':
          return PaymentStatus.success;
        case 'failed':
        case 'error':
          return PaymentStatus.failed;
        case 'pending':
        case 'pay_offline':
          return PaymentStatus.pending;
        case 'cancelled':
          return PaymentStatus.cancelled;
        default:
          return PaymentStatus.pending;
      }
    }
    return PaymentStatus.pending;
  }

  static PaymentStatus _mapTransactionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'abandoned':
      case 'timeout':
        return PaymentStatus.pending;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// Payment methods supported in Kenya
enum PaymentMethod {
  card,
  mpesaStkPush,
  mpesaPaybill,
  airtelMoney,
  pesalink,
}

/// Payment status
enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
}

/// Payment request model
class PaymentRequest {
  final double amount;
  final String email;
  final String reference;
  final String secretKey;
  final String currency;
  final String country;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;

  PaymentRequest({
    required this.amount,
    required this.email,
    required this.reference,
    required this.secretKey,
    required this.currency,
    required this.country,
    this.phoneNumber,
    this.metadata,
  });
}

/// Private method to initialize the standalone Paystack client
Future<void> _initializePaystackClient(String publicKey, String country, String currency) async {
  // Store configuration for later use
  _publicKey = publicKey;
  _country = country;
  _currency = currency;
  
  // Validate public key format
  if (!publicKey.startsWith('pk_') && !publicKey.startsWith('sk_')) {
    throw ArgumentError('Invalid public key format. Must start with pk_ or sk_');
  }
  
  // Set up HTTP client with proper headers
  // This replaces the flutter_paystack_plus initialization
}