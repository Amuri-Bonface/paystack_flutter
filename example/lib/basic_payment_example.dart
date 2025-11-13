import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';

/// Comprehensive example showing all Kenya payment methods
class KenyaPaymentExample extends StatefulWidget {
  const KenyaPaymentExample({Key? key}) : super(key: key);

  @override
  State<KenyaPaymentExample> createState() => _KenyaPaymentExampleState();
}

class _KenyaPaymentExampleState extends State<KenyaPaymentExample> {
  final TextEditingController _amountController = TextEditingController(text: '5000');
  final TextEditingController _emailController = TextEditingController(text: 'customer@example.com');
  final TextEditingController _phoneController = TextEditingController(text: '+254722000000');
  
  PaymentResult? _lastResult;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kenya Payment Methods'),
        backgroundColor: Colors.green.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPaymentForm(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildPaymentWidget(),
            const SizedBox(height: 20),
            if (_lastResult != null) _buildResultDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Kenya Payment Methods Demo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Demonstrating M-PESA, Airtel Money, Pesalink, and Card payments',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (KES)',
                border: OutlineInputBorder(),
                prefixText: 'KES ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (optional)',
                border: OutlineInputBorder(),
                hintText: '+254722000000',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton('Small Amount\n(KES 500)', 500, PaymentMethod.mpesaStkPush),
            _buildQuickButton('Medium Amount\n(KES 5,000)', 5000, PaymentMethod.pesalink),
            _buildQuickButton('Large Amount\n(KES 50,000)', 50000, PaymentMethod.pesalink),
            _buildQuickButton('Card Payment\n(Any Amount)', 10000, PaymentMethod.card),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, double amount, PaymentMethod method) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _processQuickPayment(amount, method),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 60),
        backgroundColor: _getMethodColor(method),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildPaymentWidget() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final email = _emailController.text;
    final phone = _phoneController.text.isEmpty ? null : _phoneController.text;

    if (amount <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Widget',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        KenyaPaymentWidget(
          amount: amount,
          email: email,
          publicKey: 'pk_test_your_public_key_here', // Replace with your test key
          phoneNumber: phone,
          onPaymentComplete: (result) {
            setState(() {
              _lastResult = result;
            });
            _showSuccessDialog(result);
          },
          onPaymentFailed: (result) {
            setState(() {
              _lastResult = result;
            });
            _showErrorDialog(result);
          },
          onPaymentPending: (result) {
            setState(() {
              _lastResult = result;
            });
            _showPendingDialog(result);
          },
          showTransactionLimits: true,
          enablePaymentMethodSelection: true,
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    if (_lastResult == null) return const SizedBox.shrink();

    final result = _lastResult!;
    final color = _getStatusColor(result.status);

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getStatusIcon(result.status), color: color),
                const SizedBox(width: 8),
                Text(
                  'Last Payment Result',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Status: ${result.status.name.toUpperCase()}'),
            if (result.message != null) Text('Message: ${result.message}'),
            if (result.reference != null) Text('Reference: ${result.reference}'),
            if (result.amount != null) Text('Amount: ${result.formattedAmount}'),
            if (result.paymentMethod != null) Text('Method: ${result.paymentMethod}'),
            if (result.bankTransferDetails != null) ...[
              const SizedBox(height: 8),
              Text('Bank Transfer Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Account: ${result.bankTransferDetails!['account_number']}'),
              Text('Bank: ${result.bankTransferDetails!['bank_name']}'),
              Text('Reference: ${result.bankTransferDetails!['transaction_reference']}'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _processQuickPayment(double amount, PaymentMethod method) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await FlutterPaystack.initialize(
        context: context,
        publicKey: 'pk_test_your_public_key_here', // Replace with your test key
        country: 'KE',
        currency: 'KES',
      );

      final result = await FlutterPaystack.processKenyaPayment(
        amount: amount,
        email: _emailController.text,
        reference: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        preferredMethod: method,
      );

      setState(() {
        _lastResult = result;
        _isProcessing = false;
      });

      if (result.status == PaymentStatus.success) {
        _showSuccessDialog(result);
      } else if (result.status == PaymentStatus.pending) {
        _showPendingDialog(result);
      } else {
        _showErrorDialog(result);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      final errorResult = PaymentResult.failed(message: 'Payment error: $e');
      setState(() {
        _lastResult = errorResult;
      });
      
      _showErrorDialog(errorResult);
    }
  }

  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference: ${result.reference}'),
            Text('Amount: ${result.formattedAmount}'),
            if (result.paymentMethod != null)
              Text('Method: ${result.paymentMethod}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pending, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Payment Pending'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message ?? 'Payment is being processed'),
            if (result.bankTransferDetails != null) ...[
              const SizedBox(height: 8),
              Text('Bank Transfer Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Account: ${result.bankTransferDetails!['account_number']}'),
              Text('Bank: ${result.bankTransferDetails!['bank_name']}'),
              Text('Reference: ${result.bankTransferDetails!['transaction_reference']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Payment Failed'),
          ],
        ),
        content: Text(result.message ?? 'An unknown error occurred'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesaStkPush:
        return Colors.green.shade600;
      case PaymentMethod.airtelMoney:
        return Colors.red.shade600;
      case PaymentMethod.pesalink:
        return Colors.blue.shade600;
      case PaymentMethod.card:
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.success:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}