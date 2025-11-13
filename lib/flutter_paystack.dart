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

// ===== COMPLETE FLUTTER_PAYSTACK COMPATIBILITY LAYER =====

import 'dart:convert';
import 'package:flutter/material.dart';

/// Checkout method options for payment processing
enum CheckoutMethod {
  selectable,
  card,
  bank,
  ussd,
  mobileMoney,
  qr,
  bankTransfer,
}

/// Payment method types
enum PaymentMethod {
  card,
  bank,
  ussd,
  mobileMoney,
  qr,
  bankTransfer,
}

/// Credit card model for flutter_credit_card package compatibility
class CreditCardModel {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final String cvvCode;
  final bool isCvvFocused;
  
  CreditCardModel({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.cvvCode,
    this.isCvvFocused = false,
  });
}

/// Payment card details - enhanced for full compatibility
class PaymentCard {
  final String number;
  final int? expiryMonth;
  final int? expiryYear;
  final String? name;
  final String? cvc;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? addressZip;
  final String? countryCode;
  final String? email;
  final String? phone;
  final String? birthDay;
  final String? addressLine2;
  
  PaymentCard({
    required this.number,
    this.expiryMonth,
    this.expiryYear,
    this.name,
    this.cvc,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.addressZip,
    this.countryCode,
    this.email,
    this.phone,
    this.birthDay,
    this.addressLine2,
  });
  
  /// Convert card number to masked format for display
  String get maskedCardNumber {
    if (number.length <= 4) return number;
    return '**** **** **** ${number.substring(number.length - 4)}';
  }
  
  /// Validate card number
  bool get isValid {
    if (number.isEmpty || number.length < 13) return false;
    
    // Luhn algorithm for basic validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n = (n % 10) + 1;
      }
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }
  
  /// Get card type based on number
  String get cardType {
    if (number.startsWith('4')) return 'visa';
    if (number.startsWith('5') || number.startsWith('2')) return 'mastercard';
    if (number.startsWith('3')) return 'amex';
    if (number.startsWith('6')) return 'discover';
    return 'unknown';
  }
}

/// Charge object for payment processing - enhanced with all original properties
class Charge {
  late int amount;
  late String currency;
  late String reference;
  late String email;
  String? subaccount;
  int? transactionCharge;
  int? bearerCharge;
  String? metadata;
  String? plan;
  int? invoiceLimit;
  String? splitCode;
  PaymentCard? card;
  String? accessCode;
  String? authorizationUrl;
  String? authorizationCode;
  String? cardNumber;
  String? cvv;
  String? expiryMonth;
  String? expiryYear;
  String? token;
  String? pin;
  String? phone;
  String? bankCode;
  String? mobileMoneyProvider;
  String? otp;
  String? address;
  String? city;
  String? state;
  String? zip;
  String? country;
  String? userId;
  String? metadataDictionary;
  
  /// Convert amount to cents (multiply by 100)
  static int amountInCents(double amount) => (amount * 100).round();
}

/// Checkout response object - enhanced with all original properties
class CheckoutResponse {
  final bool status;
  final String? reference;
  final String? message;
  final String? code;
  final dynamic data;
  final String? verifyUrl;
  final String? accessCode;
  final String? authorizationUrl;
  final String? card;
  final String? cardPanToken;
  final String? cardToken;
  final String? cardType;
  final String? expireAt;
  final String? fees;
  final String? transactionDate;
  final String? transactionData;
  
  CheckoutResponse({
    required this.status,
    this.reference,
    this.message,
    this.code,
    this.data,
    this.verifyUrl,
    this.accessCode,
    this.authorizationUrl,
    this.card,
    this.cardPanToken,
    this.cardToken,
    this.cardType,
    this.expireAt,
    this.fees,
    this.transactionDate,
    this.transactionData,
  });
  
  factory CheckoutResponse.success(String reference) {
    return CheckoutResponse(
      status: true,
      reference: reference,
      message: 'Payment successful',
    );
  }
  
  factory CheckoutResponse.failure(String message) {
    return CheckoutResponse(
      status: false,
      message: message,
      code: 'payment_failed',
    );
  }
}

/// Credit card form input configuration for flutter_credit_card compatibility
class InputConfiguration {
  final InputDecoration cardNumberDecoration;
  final InputDecoration expiryDateDecoration;
  final InputDecoration cvvCodeDecoration;
  final InputDecoration cardHolderDecoration;
  
  const InputConfiguration({
    required this.cardNumberDecoration,
    required this.expiryDateDecoration,
    required this.cvvCodeDecoration,
    required this.cardHolderDecoration,
  });
}

/// Credit card widget configuration
class CreditCardWidgetConfig {
  final Border frontCardBorder;
  final Border backCardBorder;
  final Color cardBgColor;
  final bool obscureCardNumber;
  final bool obscureCardCvv;
  final bool isHolderNameVisible;
  final bool isSwipeGestureEnabled;
  final Duration animationDuration;
  
  const CreditCardWidgetConfig({
    this.frontCardBorder = const Border.all(color: Colors.grey),
    this.backCardBorder = const Border.all(color: Colors.grey),
    this.cardBgColor = Colors.blue,
    this.obscureCardNumber = true,
    this.obscureCardCvv = true,
    this.isHolderNameVisible = true,
    this.isSwipeGestureEnabled = true,
    this.animationDuration = const Duration(milliseconds: 500),
  });
}

/// Backward compatibility class for existing flutter_paystack code
/// This provides complete API compatibility with the original flutter_paystack package
class PaystackPlugin {
  static String? _publicKey;
  static String? _country;
  
  /// Initialize the plugin with public key and country
  /// 
  /// [publicKey] Your Paystack public key
  /// [country] Country code (default: 'KE' for Kenya)
  Future<void> initialize({required String publicKey, String? country}) async {
    _publicKey = publicKey;
    _country = country ?? 'KE';
  }
  
  /// Get the current public key
  String? get publicKey => _publicKey;
  
  /// Check if the plugin is initialized
  bool get isInitialized => _publicKey != null;
  
  /// Get the current country code
  String? get country => _country;
  
  /// Process checkout payment
  /// 
  /// This method provides backward compatibility and delegates to FlutterPaystack
  Future<CheckoutResponse> checkout(
    BuildContext context, {
    required CheckoutMethod method,
    required Charge charge,
    bool fullscreen = false,
    Widget? logo,
    String? theme,
    String? successMessage,
    String? accessCode,
  }) async {
    if (!isInitialized) {
      throw Exception('PaystackPlugin not initialized. Call initialize() first.');
    }
    
    try {
      // Create FlutterPaystack instance for processing
      final flutterPaystack = FlutterPaystack();
      
      // Initialize with stored configuration
      await flutterPaystack.initialize(
        publicKey: _publicKey!,
        currency: charge.currency,
        country: _country ?? 'KE',
      );
      
      // Convert checkout method to our supported methods
      List<String> paymentMethods = _convertCheckoutMethod(method);
      
      // Process payment through our standalone implementation
      final response = await flutterPaystack.startPayment(
        amount: charge.amount,
        email: charge.email,
        reference: charge.reference,
        paymentMethods: paymentMethods,
        phoneNumber: charge.phone ?? null, // Handle optional phone
        metadata: charge.metadata,
      );
      
      // Convert our response to CheckoutResponse format
      if (response['success'] == true) {
        return CheckoutResponse.success(response['reference'] ?? charge.reference);
      } else {
        return CheckoutResponse.failure(
          response['message'] ?? 'Payment was not successful'
        );
      }
    } catch (e) {
      return CheckoutResponse.failure(e.toString());
    }
  }
  
  /// Convert CheckoutMethod to our payment methods
  List<String> _convertCheckoutMethod(CheckoutMethod method) {
    switch (method) {
      case CheckoutMethod.card:
        return ['card'];
      case CheckoutMethod.mobileMoney:
        return ['mpesa_stk_push', 'airtel_money'];
      case CheckoutMethod.bank:
        return ['pesalink'];
      case CheckoutMethod.ussd:
        return ['ussd'];
      case CheckoutMethod.selectable:
        // All methods for selectable
        return ['mpesa_stk_push', 'airtel_money', 'pesalink', 'card'];
      default:
        return ['mpesa_stk_push', 'airtel_money', 'pesalink', 'card'];
    }
  }
  
  /// Show success dialog
  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  /// Show error dialog
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
}