part of flutter_paystack;

/// Utility functions for Kenya payment operations
class PaymentUtils {
  /// Validate Kenya phone number format
  static bool isValidKenyaPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check different valid formats
    return cleanNumber.startsWith('254') && cleanNumber.length == 12 ||
           cleanNumber.startsWith('07') && cleanNumber.length == 10 ||
           cleanNumber.startsWith('+254') && cleanNumber.length == 13;
  }

  /// Normalize Kenya phone number to +254 format
  static String normalizeKenyaPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.startsWith('254')) {
      return '+$cleanNumber';
    } else if (cleanNumber.startsWith('07')) {
      return '+254${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('7')) {
      return '+254$cleanNumber';
    } else if (cleanNumber.startsWith('+254')) {
      return phoneNumber;
    }
    
    throw ArgumentError('Invalid Kenya phone number format');
  }

  /// Get payment method display name
  static String getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Card Payment';
      case PaymentMethod.mpesaStkPush:
        return 'M-PESA STK Push';
      case PaymentMethod.mpesaPaybill:
        return 'M-PESA Paybill';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.pesalink:
        return 'Pesalink Bank Transfer';
    }
  }

  /// Get payment method icon name
  static String getPaymentMethodIconName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'credit_card';
      case PaymentMethod.mpesaStkPush:
        return 'smartphone';
      case PaymentMethod.mpesaPaybill:
        return 'business';
      case PaymentMethod.airtelMoney:
        return 'phone_android';
      case PaymentMethod.pesalink:
        return 'account_balance';
    }
  }

  /// Check if amount is within payment method limits
  static bool isAmountWithinLimits(double amount, PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesaStkPush:
        return amount <= 150000;
      case PaymentMethod.mpesaPaybill:
        return amount <= 70000;
      case PaymentMethod.airtelMoney:
        return amount <= 70000;
      case PaymentMethod.pesalink:
        return amount <= 999999;
      case PaymentMethod.card:
        return true; // No specified limit
    }
  }

  /// Calculate estimated fees for payment method
  static double calculateEstimatedFees(double amount, PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return amount * 0.025 + 20; // 2.5% + KES 20
      case PaymentMethod.mpesaStkPush:
        return amount > 100 ? 10 : 0; // KES 10 for amounts >KES 100
      case PaymentMethod.mpesaPaybill:
        return 25; // Fixed KES 25
      case PaymentMethod.airtelMoney:
        return amount > 100 ? 10 : 0; // KES 10 for amounts >KES 100
      case PaymentMethod.pesalink:
        return 20; // Fixed KES 20
    }
  }

  /// Get recommended payment method for amount
  static PaymentMethod getRecommendedPaymentMethod({
    required double amount,
    String? phoneNumber,
    bool preferSpeed = true,
  }) {
    // High amounts (>50,000) - recommend Pesalink
    if (amount >= 50000) {
      return PaymentMethod.pesalink;
    }
    
    // If phone number provided, prefer mobile money
    if (phoneNumber != null && isValidKenyaPhoneNumber(phoneNumber)) {
      if (preferSpeed) {
        return PaymentMethod.mpesaStkPush;
      } else {
        return PaymentMethod.airtelMoney;
      }
    }
    
    // Medium amounts (1,000-50,000) - recommend M-PESA
    if (amount >= 1000) {
      return PaymentMethod.mpesaStkPush;
    }
    
    // Small amounts - recommend card or cheapest option
    if (amount <= 100) {
      return PaymentMethod.card;
    }
    
    return PaymentMethod.mpesaStkPush;
  }

  /// Generate unique payment reference
  static String generatePaymentReference({
    String? prefix,
    String? suffix,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    final reference = '${prefix ?? 'payment'}_${timestamp}_$random${suffix ?? ''}';
    return reference.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Format currency amount
  static String formatCurrency(double amount, {String currency = 'KES'}) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Parse currency string to double
  static double parseCurrency(String currencyString) {
    return double.parse(currencyString.replaceAll(RegExp(r'[^0-9.]'), ''));
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Get transaction timeout for payment method
  static Duration getTransactionTimeout(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesaStkPush:
        return Duration(minutes: 3); // 180 seconds
      case PaymentMethod.mpesaPaybill:
        return Duration(minutes: 5);
      case PaymentMethod.airtelMoney:
        return Duration(minutes: 3); // 180 seconds
      case PaymentMethod.pesalink:
        return Duration(minutes: 25); // 25 minutes
      case PaymentMethod.card:
        return Duration(minutes: 10);
    }
  }

  /// Get status message for payment status
  static String getStatusMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Payment is being processed...';
      case PaymentStatus.success:
        return 'Payment successful!';
      case PaymentStatus.failed:
        return 'Payment failed. Please try again.';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled.';
    }
  }

  /// Get status color for UI
  static Color getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.success:
        return Colors.green;
      case PaymentMethod.airtelMoney:
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  /// Check if payment method requires phone number
  static bool requiresPhoneNumber(PaymentMethod method) {
    return method == PaymentMethod.mpesaStkPush || 
           method == PaymentMethod.airtelMoney;
  }

  /// Get payment method description
  static String getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Pay with Visa, Mastercard, or Amex';
      case PaymentMethod.mpesaStkPush:
        return 'Instant payment via M-PESA STK Push';
      case PaymentMethod.mpesaPaybill:
        return 'Pay using M-PESA Paybill number';
      case PaymentMethod.airtelMoney:
        return 'Pay with Airtel Money';
      case PaymentMethod.pesalink:
        return 'Instant bank-to-bank transfer';
    }
  }

  /// Validate Pesalink transaction details
  static Map<String, dynamic>? validatePesalinkDetails(
    Map<String, dynamic> metadata,
  ) {
    final requiredFields = [
      'account_number',
      'account_name', 
      'bank_name',
      'transaction_reference',
    ];
    
    for (final field in requiredFields) {
      if (!metadata.containsKey(field) || metadata[field] == null) {
        return {
          'valid': false,
          'error': 'Missing required field: $field',
        };
      }
    }
    
    return {'valid': true};
  }

  /// Check if Pesalink account has expired
  static bool isPesalinkAccountExpired(String expiryTime) {
    try {
      final expiry = DateTime.parse(expiryTime);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Get time remaining for Pesalink account
  static Duration? getPesalinkTimeRemaining(String expiryTime) {
    try {
      final expiry = DateTime.parse(expiryTime);
      final remaining = expiry.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return null;
    }
  }

  /// Format duration to human readable string
  static String formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

/// Extension on PaymentMethod for additional functionality
extension PaymentMethodExtensions on PaymentMethod {
  /// Get display name
  String get displayName => PaymentUtils.getPaymentMethodDisplayName(this);
  
  /// Get icon name
  String get iconName => PaymentUtils.getPaymentMethodIconName(this);
  
  /// Get description
  String get description => PaymentUtils.getPaymentMethodDescription(this);
  
  /// Check if requires phone number
  bool get requiresPhone => PaymentUtils.requiresPhoneNumber(this);
  
  /// Get transaction timeout
  Duration get timeout => PaymentUtils.getTransactionTimeout(this);
  
  /// Check if amount is within limits
  bool isAmountWithinLimits(double amount) => 
      PaymentUtils.isAmountWithinLimits(amount, this);
}

/// Extension on PaymentStatus for additional functionality  
extension PaymentStatusExtensions on PaymentStatus {
  /// Get status message
  String get message => PaymentUtils.getStatusMessage(this);
  
  /// Get status color
  Color get color => PaymentUtils.getStatusColor(this);
  
  /// Check if completed (success or failed)
  bool get isCompleted => this == PaymentStatus.success || this == PaymentStatus.failed || this == PaymentStatus.cancelled;
  
  /// Check if needs user action (pending)
  bool get needsUserAction => this == PaymentStatus.pending;
}