# Flutter Paystack - Enhanced Kenya Integration v2.1.0

[![pub package](https://img.shields.io/pub/v/flutter_paystack.svg)](https://pub.dev/packages/flutter_paystack)
[![build status](https://github.com/Amuri-Bonface/flutter_paystack/workflows/Build/badge.svg)](https://github.com/Amuri-Bonface/flutter_paystack/actions)
[![coverage](https://coveralls.io/repos/github/Amuri-Bonface/flutter_paystack/badge.svg)](https://coveralls.io/github/Amuri-Bonface/flutter_paystack)

**The most comprehensive Flutter Paystack plugin for Kenya with support for all payment methods: M-PESA STK Push, M-PESA Paybill, Airtel Money, Pesalink bank transfers, and card payments.**

## 🇰🇪 New in v2.1.0 - Pesalink Bank Transfer Support!

**🚀 Major Update**: Added **Pesalink** - instant bank-to-bank transfers in Kenya (up to KES 999,999)!

### ✨ Key Features

#### 🇰🇪 Complete Kenya Payment Ecosystem
- **M-PESA STK Push**: Direct mobile payments with instant confirmation (up to KES 150,000)
- **M-PESA Paybill**: Business payments via Paybill numbers (up to KES 70,000 daily)
- **Airtel Money**: Direct Airtel mobile money integration (up to KES 70,000 daily)
- **NEW: Pesalink Bank Transfer**: Instant bank-to-bank transfers (up to KES 999,999)
- **Card Payments**: Visa, Mastercard, Amex support
- **Auto-Detection**: Intelligently recommends best payment method for each transaction

#### 🧠 Smart Payment Intelligence
- **Amount-Based Recommendations**: Automatically suggests optimal payment method
- **Transaction Limit Validation**: Prevents failed transactions with real-time limit checking
- **Phone Number Normalization**: Handles all Kenya phone number formats automatically
- **Fee Estimation**: Shows estimated fees before payment selection

#### 📱 Cross-Platform Excellence
- **Android**: Full native integration with all Kenya payment methods
- **iOS**: Complete iOS payment handling
- **Web**: Browser-based payments with Kenya-specific optimizations
- **Consistent API**: Unified experience across all platforms

## 📦 Installation

Add `flutter_paystack` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_paystack: ^2.1.0
```

### Platform Setup

#### Android
No additional setup required. Works out of the box with all Kenya payment methods.

#### iOS
Ensure minimum iOS deployment target of 11.0 or higher.

#### Web
Add Paystack JavaScript SDK to your `index.html`:

```html
<script src="https://js.paystack.co/v1/inline.js"></script>
```

## 🚀 Quick Start - Complete Kenya Integration

### 1. Basic Kenya Payment with Auto-Detection

```dart
import 'package:flutter_paystack/flutter_paystack.dart';

class PaymentService {
  static const String _publicKey = 'pk_test_your_public_key_here';

  Future<void> processPayment({
    required BuildContext context,
    required double amount,
    required String email,
    String? phoneNumber,
  }) async {
    // Initialize for Kenya (auto-configures currency and country)
    await FlutterPaystack.initialize(
      context: context,
      publicKey: _publicKey,
      country: 'KE',
      currency: 'KES',
    );

    // Auto-detect best payment method and process payment
    final result = await FlutterPaystack.processKenyaPayment(
      amount: amount,
      email: email,
      reference: 'payment_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phoneNumber, // Optional - improves mobile money detection
    );

    // Handle result
    if (result.status == PaymentStatus.success) {
      print('✅ Payment successful! Reference: ${result.reference}');
      print('💰 Amount: ${result.formattedAmount}');
      print('🏦 Method: ${result.paymentMethod}');
    } else if (result.status == PaymentStatus.pending) {
      print('⏳ Payment pending: ${result.message}');
      if (result.bankTransferDetails != null) {
        // Show Pesalink transfer instructions
        final details = result.bankTransferDetails!;
        print('📋 Account: ${details['account_number']}');
        print('🏛️ Bank: ${details['bank_name']}');
      }
    } else {
      print('❌ Payment failed: ${result.message}');
    }
  }
}
```

### 2. M-PESA STK Push Payment

```dart
Future<void> processMpesaStkPush({
  required BuildContext context,
  required double amount,
  required String email,
  required String phoneNumber, // Required for M-PESA
}) async {
  final result = await FlutterPaystack.processKenyaPayment(
    amount: amount,
    email: email,
    reference: 'mpesa_${DateTime.now().millisecondsSinceEpoch}',
    phoneNumber: phoneNumber,
    preferredMethod: PaymentMethod.mpesaStkPush,
  );

  if (result.status == PaymentStatus.success) {
    print('💳 M-PESA payment successful! Reference: ${result.reference}');
  }
}
```

### 3. Pesalink Bank Transfer

```dart
Future<void> processPesalinkTransfer({
  required BuildContext context,
  required double amount,
  required String email,
}) async {
  // Pesalink is perfect for high-value transactions
  if (amount >= 50000) {
    final result = await FlutterPaystack.processKenyaPayment(
      amount: amount,
      email: email,
      reference: 'pesalink_${DateTime.now().millisecondsSinceEpoch}',
      preferredMethod: PaymentMethod.pesalink,
    );

    if (result.status == PaymentStatus.pending) {
      // Show bank transfer instructions
      final details = result.bankTransferDetails!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Bank Transfer Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please transfer to:'),
              Text('Account: ${details['account_number']}', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Bank: ${details['bank_name']}'),
              Text('Reference: ${details['transaction_reference']}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
  }
}
```

### 4. Enhanced Payment Widget

```dart
class MyCheckoutPage extends StatelessWidget {
  const MyCheckoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kenya Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: KenyaPaymentWidget(
          amount: 25000.0, // KES 25,000
          email: 'customer@example.com',
          publicKey: 'pk_test_your_public_key_here',
          phoneNumber: '+254722000000',
          onPaymentComplete: (result) {
            if (result.status == PaymentStatus.success) {
              // Payment successful - update UI
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment successful! ${result.reference}')),
              );
            }
          },
          onPaymentFailed: (result) {
            // Payment failed - show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onPaymentPending: (result) {
            // Show pending status (e.g., for Pesalink)
            if (result.bankTransferDetails != null) {
              showBankTransferDialog(context, result);
            }
          },
          showTransactionLimits: true,
          enablePaymentMethodSelection: true,
        ),
      ),
    );
  }

  void showBankTransferDialog(BuildContext context, PaymentResult result) {
    final details = result.bankTransferDetails!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bank Transfer Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please transfer using your banking app:'),
            SizedBox(height: 8),
            Text('Account Number:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(details['account_number'] ?? 'N/A'),
            SizedBox(height: 8),
            Text('Bank Name:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(details['bank_name'] ?? 'N/A'),
            SizedBox(height: 8),
            Text('Reference:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(details['transaction_reference'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('I\'ve Made the Transfer'),
          ),
        ],
      ),
    );
  }
}
```

### 5. Payment Method Selection

```dart
class PaymentMethodSelector extends StatelessWidget {
  final double amount;
  final String? phoneNumber;

  const PaymentMethodSelector({
    Key? key,
    required this.amount,
    this.phoneNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get available payment methods for this amount and phone number
    final methods = FlutterPaystack.getAvailablePaymentMethods(
      amount: amount,
      phoneNumber: phoneNumber,
    );

    return Column(
      children: methods.map((method) => 
        PaymentMethodCard(method: method)
      ).toList(),
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;

  const PaymentMethodCard({Key? key, required this.method}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(method.iconName as IconData?),
        title: Text(method.displayName),
        subtitle: Text(method.description),
        trailing: Text('Up to ${_getLimit(method)}'),
        onTap: () => _selectPaymentMethod(context),
      ),
    );
  }

  String _getLimit(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesaStkPush:
        return 'KES 150,000';
      case PaymentMethod.mpesaPaybill:
        return 'KES 70,000/day';
      case PaymentMethod.airtelMoney:
        return 'KES 70,000/day';
      case PaymentMethod.pesalink:
        return 'KES 999,999';
      case PaymentMethod.card:
        return 'No limit';
    }
  }
}
```

## 🧠 Smart Payment Intelligence

### Auto-Detection

```dart
// The plugin automatically detects the best payment method
final methods = FlutterPaystack.getAvailablePaymentMethods(
  amount: 25000, // KES 25,000
  phoneNumber: '+254722000000',
);

// Recommendations:
// - 50,000+ KES → Pesalink (best for high amounts)
// - 1,000-50,000 KES + phone → M-PESA STK Push
// - Any amount → Card (fallback)
```

### Transaction Validation

```dart
// Validate before processing
final request = KenyaPaymentRequest(
  amount: 25000,
  email: 'user@example.com',
  reference: 'payment_123',
  secretKey: 'sk_test_key',
  method: PaymentMethod.pesalink,
  phoneNumber: '+254722000000',
);

final validation = request.validate();
if (!validation.isValid) {
  print('Invalid request: ${validation.errorMessage}');
  return;
}
```

## 📊 Payment Method Comparison

| Method | Limit | Speed | Fee | Best For |
|--------|-------|-------|-----|----------|
| **M-PESA STK Push** | KES 150,000 | Instant | KES 10 (>KES 100) | Real-time payments |
| **M-PESA Paybill** | KES 70,000/day | 1-5 min | KES 25 | Business payments |
| **Airtel Money** | KES 70,000/day | Instant | KES 10 (>KES 100) | Airtel subscribers |
| **Pesalink** | KES 999,999 | Instant | KES 20 | High-value transfers |
| **Card** | No limit | Instant | 2.5% + KES 20 | International cards |

## 🔧 Configuration

### Paystack Dashboard Setup

1. **Verify Business Account**: Complete Paystack business verification for Kenya
2. **Enable Kenya Payment Channels**:
   - M-PESA STK Push
   - M-PESA Paybill  
   - Airtel Money
   - **Pesalink Bank Transfer** (new!)
   - Card payments
3. **Set Kenya as Default Country**: Configure in Paystack dashboard
4. **Get Updated Keys**: Copy your public and secret keys

### Environment Configuration

```dart
class Config {
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_your_key_here',
  );
  
  static const String paystackSecretKey = String.fromEnvironment(
    'PAYSTACK_SECRET_KEY', 
    defaultValue: 'sk_test_your_key_here',
  );
}
```

## 🧪 Testing

### Test Keys
```dart
// Safe to use in development
static const String testPublicKey = 'pk_test_your_test_key_here';
static const String testSecretKey = 'sk_test_your_test_key_here';
```

### Test Phone Numbers
- **M-PESA**: Use Paystack's test phone numbers
- **Airtel Money**: Use Paystack's test numbers  
- **Pesalink**: Test with any Kenyan bank account
- **Cards**: Use Paystack test card numbers

## 📋 API Reference

### PaymentResult Enhanced
```dart
class PaymentResult {
  // Core properties
  final PaymentStatus status;
  final String? message;
  final String? reference;
  final String? transactionId;
  final double? amount;
  final double? fees;
  final bool verified;
  
  // Kenya-specific enhancements
  final Map<String, dynamic>? metadata;
  
  // Kenya-specific getters
  String? get paymentMethod;
  Map<String, dynamic>? get bankTransferDetails; // For Pesalink
  String get formattedAmount;
}
```

### Payment Methods
```dart
enum PaymentMethod {
  card,              // Card payments (Visa, Mastercard, Amex)
  mpesaStkPush,      // M-PESA STK Push
  mpesaPaybill,      // M-PESA Paybill
  airtelMoney,       // Airtel Money
  pesalink,          // Pesalink Bank Transfer (NEW!)
}
```

### Utility Functions
```dart
// Phone number utilities
PaymentUtils.isValidKenyaPhoneNumber('+254722000000');
PaymentUtils.normalizeKenyaPhoneNumber('0722000000'); // → +254722000000

// Payment method utilities
PaymentUtils.getRecommendedPaymentMethod(amount: 25000);
PaymentUtils.calculateEstimatedFees(5000, PaymentMethod.mpesaStkPush);
PaymentUtils.isAmountWithinLimits(10000, PaymentMethod.pesalink);

// Validation
PaymentUtils.isValidEmail('user@example.com');
PaymentUtils.generatePaymentReference(prefix: 'order_');
```

## 🌍 Migration from v1.x/v2.0

### Breaking Changes
- **Updated API**: New `FlutterPaystack` class with Kenya-specific methods
- **Enhanced Models**: `PaymentResult` now includes Kenya-specific metadata
- **Payment Flow**: Intelligent auto-detection replaces manual method selection

### Migration Example

**Before (v2.0):**
```dart
final request = PaymentRequest(
  amount: 1000,
  email: 'user@example.com',
  reference: 'ref_123',
  secretKey: publicKey,
  currency: 'KES',
  country: 'KE',
);

final result = await FlutterPaystack.chargeCard(
  context: context,
  request: request,
);
```

**After (v2.1.0):**
```dart
// Auto-detect best payment method and process
final result = await FlutterPaystack.processKenyaPayment(
  amount: 1000,
  email: 'user@example.com',
  reference: 'ref_123',
  phoneNumber: '+254722000000', // Optional but recommended
);

// Or specify preferred method
final result = await FlutterPaystack.processKenyaPayment(
  amount: 1000,
  email: 'user@example.com',
  reference: 'ref_123',
  preferredMethod: PaymentMethod.mpesaStkPush,
);
```

## 📖 Examples

Check the `/example` directory for complete implementations:

- **Basic Kenya Payment**: Auto-detection example
- **M-PESA STK Push**: Mobile payment example  
- **Pesalink Bank Transfer**: High-value transfer example
- **Widget Integration**: Using `KenyaPaymentWidget`
- **Payment Method Selector**: Custom payment selection UI
- **Error Handling**: Comprehensive error handling examples

## 🔐 Security Best Practices

- **Client-Side**: Never expose secret keys in client code
- **Server-Side**: Handle transaction verification on your server
- **HTTPS**: Always use HTTPS in production
- **Validation**: Validate all payment responses
- **Reference**: Use unique references to prevent duplicate processing

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines before submitting pull requests.

### Development Setup
1. Fork the repository
2. Create a feature branch  
3. Make your changes
4. Add tests for Kenya payment methods
5. Submit a pull request

## 📄 License

This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/Amuri-Bonface/flutter_paystack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Amuri-Bonface/flutter_paystack/discussions)
- **Documentation**: [Wiki](https://github.com/Amuri-Bonface/flutter_paystack/wiki)

## 🙏 Acknowledgments

- **Paystack**: For comprehensive payment infrastructure including Pesalink
- **Flutter Team**: For the amazing framework
- **Kenya Mobile Money**: M-PESA, Airtel Money teams
- **Banking Partners**: For Pesalink integration

## 📈 What's New in v2.1.0

### 🚀 Major Features
- ✨ **Pesalink Integration**: Instant bank-to-bank transfers up to KES 999,999
- 🧠 **Smart Payment Detection**: Intelligent method recommendation based on amount and context
- 📊 **Transaction Limits Display**: Real-time limit checking and validation
- 🔧 **Enhanced Widgets**: Improved UI with payment method selection
- 📱 **Better Web Support**: Optimized web experience for Kenya users

### 🛠️ Technical Improvements
- **Enhanced Models**: Extended `PaymentResult` with Kenya-specific metadata
- **Utility Functions**: Comprehensive utilities for Kenya payment handling
- **Better Error Handling**: Improved error messages and validation
- **Performance**: Optimized for Kenya payment ecosystem

### 📚 Documentation
- **Complete Kenya Guide**: Comprehensive documentation for all Kenya payment methods
- **Migration Guide**: Easy upgrade path from v1.x and v2.0
- **Examples**: Complete examples for each payment method
- **API Reference**: Detailed API documentation with Kenya-specific features

---

**Made with ❤️ for the Kenya payment ecosystem**

*Supporting all major payment methods in Kenya: M-PESA, Airtel Money, Pesalink, and Cards*