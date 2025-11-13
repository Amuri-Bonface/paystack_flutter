import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/services.dart';
import '../flutter_paystack.dart';

/// Web implementation of Flutter Paystack with Kenya support
class FlutterPaystackWebPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_paystack_web');

  static bool _isInitialized = false;
  static String? _publicKey;
  static String? _country;
  static String? _currency;

  /// Initialize web Paystack with Kenya support
  static Future<void> initialize({
    required String publicKey,
    String country = 'KE',
    String currency = 'KES',
  }) async {
    if (_isInitialized) return;

    try {
      // Load Paystack JavaScript SDK
      await _loadPaystackScript();
      
      _publicKey = publicKey;
      _country = country;
      _currency = currency;
      _isInitialized = true;

      print('Paystack web initialized for $country ($currency)');
    } catch (e) {
      throw Exception('Failed to initialize Paystack web: $e');
    }
  }

  /// Load Paystack JavaScript SDK
  static Future<void> _loadPaystackScript() async {
    // Check if script is already loaded
    final existingScript = html.document.querySelector('script[src*="paystack"]');
    if (existingScript != null) return;

    final script = html.ScriptElement()
      ..src = 'https://js.paystack.co/v1/inline.js'
      ..type = 'text/javascript';

    final completer = Completer<void>();
    
    script.onLoad.first.then((_) {
      print('Paystack SDK loaded successfully');
      completer.complete();
    });

    script.onError.first.then((_) {
      completer.completeError('Failed to load Paystack SDK');
    });

    html.document.head!.append(script);
    
    return completer.future;
  }

  /// Process Kenya web payment
  static Future<PaymentResult> processWebPayment({
    required double amount,
    required String email,
    required String reference,
    String? phoneNumber,
    PaymentMethod? preferredMethod,
  }) async {
    if (!_isInitialized || _publicKey == null) {
      throw Exception('Paystack web not initialized');
    }

    try {
      final transaction = await _initializeTransaction(
        amount: amount,
        email: email,
        reference: reference,
        phoneNumber: phoneNumber,
      );

      return await _processTransaction(transaction);
    } catch (e) {
      return PaymentResult.failed(message: 'Web payment error: $e');
    }
  }

  /// Initialize transaction
  static Map<String, dynamic> _initializeTransaction({
    required double amount,
    required String email,
    required String reference,
    String? phoneNumber,
  }) {
    final metadata = <String, dynamic>{
      'reference': reference,
      'phone_number': phoneNumber,
      'payment_source': 'flutter_web',
      'country': _country,
    };

    // Add method-specific metadata
    if (preferredMethod != null) {
      metadata['payment_method'] = preferredMethod.name;
    }

    return {
      'key': _publicKey,
      'email': email,
      'amount': (amount * 100).round(), // Amount in kobo
      'currency': _currency ?? 'KES',
      'reference': reference,
      'metadata': metadata,
      'callback': js.allowInterop((response) {
        _handlePaymentCallback(response);
      }),
      'onClose': js.allowInterop(() {
        _handlePaymentClose();
      }),
    };
  }

  /// Process transaction using Paystack popup
  static Future<PaymentResult> _processTransaction(Map<String, dynamic> transaction) {
    final completer = Completer<PaymentResult>();
    
    try {
      // Get Paystack object from window
      final paystack = js.context['PaystackPop'];
      if (paystack == null) {
        throw Exception('Paystack SDK not loaded');
      }

      // Create popup
      final popup = paystack['new'](js.JsObject.fromProxy(js.JsObject(transaction)));
      
      // Open popup
      popup.callMethod('openIframe');
      
      // Store completer for callback
      _pendingCompleter = completer;
      
    } catch (e) {
      completer.completeError('Failed to process transaction: $e');
    }

    return completer.future;
  }

  static Completer<PaymentResult>? _pendingCompleter;

  /// Handle payment callback from Paystack
  static void _handlePaymentCallback(dynamic response) {
    final result = _parseCallbackResponse(response);
    _pendingCompleter?.complete(result);
    _pendingCompleter = null;
  }

  /// Handle payment close
  static void _handlePaymentClose() {
    _pendingCompleter?.complete(PaymentResult.cancelled());
    _pendingCompleter = null;
  }

  /// Parse Paystack callback response
  static PaymentResult _parseCallbackResponse(dynamic response) {
    try {
      final data = js.JsObject.fromProxy(response);
      final status = data['status'] as String;
      final message = data['message'] as String?;
      final reference = data['reference'] as String?;
      final amount = data['amount'] != null ? (data['amount'] as num) / 100.0 : null;

      PaymentStatus paymentStatus;
      switch (status.toLowerCase()) {
        case 'success':
          paymentStatus = PaymentStatus.success;
          break;
        case 'failed':
          paymentStatus = PaymentStatus.failed;
          break;
        case 'cancelled':
          paymentStatus = PaymentStatus.cancelled;
          break;
        default:
          paymentStatus = PaymentStatus.pending;
      }

      return PaymentResult(
        status: paymentStatus,
        message: message,
        reference: reference,
        amount: amount,
        verified: status == 'success',
      );
    } catch (e) {
      return PaymentResult.failed(message: 'Failed to parse payment response: $e');
    }
  }

  /// Get available payment methods for web
  static List<PaymentMethod> getWebPaymentMethods() {
    if (_country != 'KE') {
      return [PaymentMethod.card];
    }

    // Web has limited payment method support compared to mobile
    return [
      PaymentMethod.card,
      // Pesalink might be available in web depending on implementation
      // Mobile money typically requires mobile app
    ];
  }

  /// Validate web environment
  static Map<String, dynamic> validateWebEnvironment() {
    final isHttps = html.window.location.protocol == 'https:';
    final hasPaystackSDK = js.context.hasProperty('PaystackPop');
    
    return {
      'https_required': isHttps,
      'paystack_loaded': hasPaystackSDK,
      'country': _country,
      'currency': _currency,
      'ready': isHttps && hasPaystackSDK && _isInitialized,
    };
  }

  /// Format phone number for web (basic validation)
  static String? validateWebPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return null;
    
    // Basic validation for web
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.length < 10 || cleanNumber.length > 13) {
      return 'Invalid phone number format';
    }
    
    return null;
  }

  /// Get web-specific payment method recommendations
  static PaymentMethod getWebRecommendedMethod(double amount) {
    if (_country == 'KE') {
      // For Kenya, recommend card on web (mobile money typically requires mobile app)
      return PaymentMethod.card;
    }
    
    return PaymentMethod.card;
  }

  /// Cleanup web resources
  static void dispose() {
    _isInitialized = false;
    _publicKey = null;
    _country = null;
    _currency = null;
    _pendingCompleter?.complete(PaymentResult.cancelled(message: 'Web context disposed'));
    _pendingCompleter = null;
  }
}

/// Web-specific payment widget
class KenyaWebPaymentWidget extends StatefulWidget {
  final double amount;
  final String email;
  final String publicKey;
  final String? phoneNumber;
  final Function(PaymentResult) onPaymentComplete;
  final Function(PaymentResult) onPaymentFailed;
  final bool enableCardOnly;

  const KenyaWebPaymentWidget({
    Key? key,
    required this.amount,
    required this.email,
    required this.publicKey,
    this.phoneNumber,
    required this.onPaymentComplete,
    required this.onPaymentFailed,
    this.enableCardOnly = true,
  }) : super(key: key);

  @override
  State<KenyaWebPaymentWidget> createState() => _KenyaWebPaymentWidgetState();
}

class _KenyaWebPaymentWidgetState extends State<KenyaWebPaymentWidget> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Web Payment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: KES ${widget.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_isProcessing ? _processPayment : null,
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : Icon(Icons.payment),
                label: Text(_isProcessing ? 'Processing...' : 'Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await FlutterPaystackWebPlugin.initialize(
        publicKey: widget.publicKey,
        country: 'KE',
        currency: 'KES',
      );

      final result = await FlutterPaystackWebPlugin.processWebPayment(
        amount: widget.amount,
        email: widget.email,
        reference: 'web_${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: widget.phoneNumber,
      );

      if (result.status == PaymentStatus.success) {
        widget.onPaymentComplete(result);
      } else {
        widget.onPaymentFailed(result);
      }
    } catch (e) {
      widget.onPaymentFailed(PaymentResult.failed(message: 'Payment error: $e'));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}