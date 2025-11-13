part of flutter_paystack;

/// Enhanced payment result with comprehensive Kenya support
class PaymentResult {
  final PaymentStatus status;
  final String? message;
  final String? reference;
  final String? transactionId;
  final double? amount;
  final double? fees;
  final bool verified;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.status,
    this.message,
    this.reference,
    this.transactionId,
    this.amount,
    this.fees,
    this.verified = false,
    this.metadata,
  });

  /// Create success result
  factory PaymentResult.success({
    String? reference,
    String? transactionId,
    double? amount,
    double? fees,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      status: PaymentStatus.success,
      reference: reference,
      transactionId: transactionId,
      amount: amount,
      fees: fees,
      verified: true,
      metadata: metadata,
    );
  }

  /// Create failed result
  factory PaymentResult.failed({
    String? message,
    String? reference,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      status: PaymentStatus.failed,
      message: message,
      reference: reference,
      metadata: metadata,
    );
  }

  /// Create pending result
  factory PaymentResult.pending({
    String? message,
    String? reference,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentResult(
      status: PaymentStatus.pending,
      message: message,
      reference: reference,
      metadata: metadata,
    );
  }

  /// Create cancelled result
  factory PaymentResult.cancelled({
    String? message,
    String? reference,
  }) {
    return PaymentResult(
      status: PaymentStatus.cancelled,
      message: message ?? 'Payment cancelled by user',
      reference: reference,
    );
  }

  /// Check if payment is successful
  bool get isSuccess => status == PaymentStatus.success;

  /// Check if payment failed
  bool get isFailed => status == PaymentStatus.failed;

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;

  /// Check if payment was cancelled
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Get formatted amount
  String get formattedAmount {
    if (amount == null) return 'N/A';
    return 'KES ${amount!.toStringAsFixed(2)}';
  }

  /// Get formatted fees
  String get formattedFees {
    if (fees == null) return 'N/A';
    return 'KES ${fees!.toStringAsFixed(2)}';
  }

  /// Get payment method from metadata
  String? get paymentMethod {
    return metadata?['payment_method'] as String?;
  }

  /// Get bank transfer details for Pesalink
  Map<String, dynamic>? get bankTransferDetails {
    if (status == PaymentStatus.pending && 
        paymentMethod == 'pesalink' && 
        metadata != null) {
      return {
        'account_number': metadata!['account_number'] as String?,
        'account_name': metadata!['account_name'] as String?,
        'bank_name': metadata!['bank_name'] as String?,
        'transaction_reference': metadata!['transaction_reference'] as String?,
        'account_expires_at': metadata!['account_expires_at'] as String?,
      };
    }
    return null;
  }

  @override
  String toString() {
    return 'PaymentResult{status: $status, reference: $reference, amount: $amount, verified: $verified}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentResult &&
        other.status == status &&
        other.reference == reference &&
        other.transactionId == transactionId &&
        other.amount == amount &&
        other.verified == verified;
  }

  @override
  int get hashCode {
    return Object.hash(status, reference, transactionId, amount, verified);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'message': message,
      'reference': reference,
      'transactionId': transactionId,
      'amount': amount,
      'fees': fees,
      'verified': verified,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      message: json['message'] as String?,
      reference: json['reference'] as String?,
      transactionId: json['transactionId'] as String?,
      amount: json['amount'] as double?,
      fees: json['fees'] as double?,
      verified: json['verified'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Enhanced payment request with Kenya-specific features
class KenyaPaymentRequest {
  final double amount;
  final String email;
  final String reference;
  final String secretKey;
  final PaymentMethod method;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;
  final bool enableOfflinePayment;
  final Duration? timeout;

  const KenyaPaymentRequest({
    required this.amount,
    required this.email,
    required this.reference,
    required this.secretKey,
    required this.method,
    this.phoneNumber,
    this.metadata,
    this.enableOfflinePayment = true,
    this.timeout,
  });

  /// Convert to base PaymentRequest
  PaymentRequest toBaseRequest() {
    return PaymentRequest(
      amount: amount,
      email: email,
      reference: reference,
      secretKey: secretKey,
      currency: 'KES',
      country: 'KE',
      phoneNumber: phoneNumber,
      metadata: {
        'payment_method': method.name,
        ...?metadata,
      },
    );
  }

  /// Validate the request
  ValidationResult validate() {
    if (amount <= 0) {
      return ValidationResult.invalid('Amount must be greater than 0');
    }

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return ValidationResult.invalid('Valid email is required');
    }

    if (reference.isEmpty) {
      return ValidationResult.invalid('Payment reference is required');
    }

    if (method == PaymentMethod.mpesaStkPush && (phoneNumber == null || phoneNumber!.isEmpty)) {
      return ValidationResult.invalid('Phone number required for M-PESA STK Push');
    }

    if (amount > 999999 && method == PaymentMethod.pesalink) {
      return ValidationResult.invalid('Pesalink transaction limit is KES 999,999');
    }

    if (amount > 150000 && method == PaymentMethod.mpesaStkPush) {
      return ValidationResult.invalid('M-PESA STK Push limit is KES 150,000');
    }

    return ValidationResult.valid();
  }
}

/// Validation result for payment requests
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.valid() => const ValidationResult._(true, null);

  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);
}

/// Payment configuration for Kenya
class KenyaPaymentConfig {
  final String country;
  final String currency;
  final Map<PaymentMethod, PaymentMethodConfig> methodConfigs;

  const KenyaPaymentConfig({
    this.country = 'KE',
    this.currency = 'KES',
    Map<PaymentMethod, PaymentMethodConfig>? methodConfigs,
  }) : methodConfigs = methodConfigs ?? _defaultConfigs;

  static const Map<PaymentMethod, PaymentMethodConfig> _defaultConfigs = {
    PaymentMethod.card: PaymentMethodConfig(
      name: 'Card Payment',
      icon: 'credit_card',
      maxAmount: double.infinity,
      transactionTime: 'Instant',
      feeStructure: '2.5% + KES 20',
    ),
    PaymentMethod.mpesaStkPush: PaymentMethodConfig(
      name: 'M-PESA STK Push',
      icon: 'smartphone',
      maxAmount: 150000,
      transactionTime: 'Instant',
      feeStructure: 'KES 10 (for amounts >KES 100)',
    ),
    PaymentMethod.mpesaPaybill: PaymentMethodConfig(
      name: 'M-PESA Paybill',
      icon: 'business',
      maxAmount: 70000,
      transactionTime: '1-5 minutes',
      feeStructure: 'KES 25',
    ),
    PaymentMethod.airtelMoney: PaymentMethodConfig(
      name: 'Airtel Money',
      icon: 'phone_android',
      maxAmount: 70000,
      transactionTime: 'Instant',
      feeStructure: 'KES 10 (for amounts >KES 100)',
    ),
    PaymentMethod.pesalink: PaymentMethodConfig(
      name: 'Pesalink Bank Transfer',
      icon: 'account_balance',
      maxAmount: 999999,
      transactionTime: 'Instant',
      feeStructure: 'KES 20',
    ),
  };
}

/// Configuration for each payment method
class PaymentMethodConfig {
  final String name;
  final String icon;
  final double maxAmount;
  final String transactionTime;
  final String feeStructure;

  const PaymentMethodConfig({
    required this.name,
    required this.icon,
    required this.maxAmount,
    required this.transactionTime,
    required this.feeStructure,
  });

  bool isAmountWithinLimit(double amount) {
    return amount <= maxAmount;
  }

  String getFormattedLimit() {
    if (maxAmount == double.infinity) return 'No limit';
    return 'KES ${maxAmount.toStringAsFixed(0)}';
  }
}