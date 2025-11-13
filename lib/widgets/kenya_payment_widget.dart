import 'package:flutter/material.dart';
import '../flutter_paystack.dart';

/// Enhanced Kenya Payment Widget with all payment methods including Pesalink
class KenyaPaymentWidget extends StatefulWidget {
  final double amount;
  final String email;
  final String publicKey;
  final String? phoneNumber;
  final PaymentMethod? preferredMethod;
  final Function(PaymentResult) onPaymentComplete;
  final Function(PaymentResult) onPaymentFailed;
  final Function(PaymentResult)? onPaymentPending;
  final bool showTransactionLimits;
  final bool enablePaymentMethodSelection;
  final String? customReference;

  const KenyaPaymentWidget({
    Key? key,
    required this.amount,
    required this.email,
    required this.publicKey,
    this.phoneNumber,
    this.preferredMethod,
    required this.onPaymentComplete,
    required this.onPaymentFailed,
    this.onPaymentPending,
    this.showTransactionLimits = true,
    this.enablePaymentMethodSelection = true,
    this.customReference,
  }) : super(key: key);

  @override
  State<KenyaPaymentWidget> createState() => _KenyaPaymentWidgetState();
}

class _KenyaPaymentWidgetState extends State<KenyaPaymentWidget> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  PaymentResult? _pendingResult;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.preferredMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (widget.enablePaymentMethodSelection) ...[
              const SizedBox(height: 16),
              _buildPaymentMethodSelector(),
            ],
            const SizedBox(height: 16),
            _buildAmountDisplay(),
            const SizedBox(height: 16),
            _buildPaymentButton(),
            if (widget.showTransactionLimits) ...[
              const SizedBox(height: 12),
              _buildTransactionLimits(),
            ],
            if (_pendingResult != null) ...[
              const SizedBox(height: 12),
              _buildPendingPaymentInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.payment,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Pay with Paystack',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _buildKenyaFlag(),
      ],
    );
  }

  Widget _buildKenyaFlag() {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.red,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final availableMethods = FlutterPaystack.getAvailablePaymentMethods(
      amount: widget.amount,
      phoneNumber: widget.phoneNumber,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...availableMethods.map((method) => _buildPaymentMethodOption(method)),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method) {
    final isSelected = _selectedMethod == method;
    final methodInfo = _getPaymentMethodInfo(method);
    
    return RadioListTile<PaymentMethod>(
      value: method,
      groupValue: _selectedMethod,
      onChanged: (value) {
        setState(() {
          _selectedMethod = value;
        });
      },
      title: Row(
        children: [
          Icon(
            methodInfo.icon,
            size: 20,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  methodInfo.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
                Text(
                  methodInfo.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Amount to Pay:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'KES ${widget.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final methodInfo = _selectedMethod != null 
        ? _getPaymentMethodInfo(_selectedMethod!)
        : _getPaymentMethodInfo(PaymentMethod.card);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedMethod != null && !_isProcessing
            ? _processPayment
            : null,
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
            : Icon(methodInfo.icon),
        label: Text(
          _isProcessing 
              ? 'Processing...'
              : '${methodInfo.buttonText} (KES ${widget.amount.toStringAsFixed(2)})',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionLimits() {
    final limits = _getTransactionLimits();
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Transaction Limits',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...limits.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      'Up to ${entry.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPaymentInfo() {
    if (_pendingResult == null) return SizedBox.shrink();

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pending,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pending Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _pendingResult!.message ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_pendingResult!.metadata != null) ...[
              const SizedBox(height: 8),
              _buildPaymentInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    final metadata = _pendingResult!.metadata!;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.containsKey('account_number')) ...[
            Text(
              'Bank Transfer Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 4),
            _buildDetailRow('Account Number', metadata['account_number']),
            _buildDetailRow('Account Name', metadata['account_name']),
            _buildDetailRow('Bank Name', metadata['bank_name']),
            _buildDetailRow('Reference', metadata['transaction_reference']),
            if (metadata.containsKey('account_expires_at'))
              _buildDetailRow('Expires', _formatExpiryTime(metadata['account_expires_at'])),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiryTime(String expiry) {
    try {
      final dateTime = DateTime.parse(expiry);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '25 minutes';
    }
  }

  PaymentMethodInfo _getPaymentMethodInfo(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return PaymentMethodInfo(
          name: 'Card Payment',
          description: 'Visa, Mastercard, Amex',
          icon: Icons.credit_card,
          buttonText: 'Pay with Card',
        );
      case PaymentMethod.mpesaStkPush:
        return PaymentMethodInfo(
          name: 'M-PESA STK Push',
          description: 'Instant mobile payment',
          icon: Icons.smartphone,
          buttonText: 'Pay with M-PESA',
        );
      case PaymentMethod.mpesaPaybill:
        return PaymentMethodInfo(
          name: 'M-PESA Paybill',
          description: 'Paybill number payment',
          icon: Icons.business,
          buttonText: 'Pay with M-PESA Paybill',
        );
      case PaymentMethod.airtelMoney:
        return PaymentMethodInfo(
          name: 'Airtel Money',
          description: 'Airtel mobile money',
          icon: Icons.phone_android,
          buttonText: 'Pay with Airtel Money',
        );
      case PaymentMethod.pesalink:
        return PaymentMethodInfo(
          name: 'Pesalink Bank Transfer',
          description: 'Instant bank-to-bank transfer',
          icon: Icons.account_balance,
          buttonText: 'Pay with Bank Transfer',
        );
    }
  }

  Map<String, String> _getTransactionLimits() {
    return {
      'M-PESA STK Push': 'KES 150,000 per transaction',
      'M-PESA Paybill': 'KES 70,000 per day',
      'Airtel Money': 'KES 70,000 per day',
      'Pesalink': 'KES 999,999 per transaction',
      'Card Payment': 'No limit specified',
    };
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await FlutterPaystack.initialize(
        context: context,
        publicKey: widget.publicKey,
        country: 'KE',
        currency: 'KES',
      );

      final reference = widget.customReference ?? 
          'payment_${DateTime.now().millisecondsSinceEpoch}';

      final result = await FlutterPaystack.processKenyaPayment(
        amount: widget.amount,
        email: widget.email,
        reference: reference,
        phoneNumber: widget.phoneNumber,
        preferredMethod: _selectedMethod,
      );

      setState(() {
        _isProcessing = false;
        
        if (result.status == PaymentStatus.pending) {
          _pendingResult = result;
          widget.onPaymentPending?.call(result);
        } else if (result.status == PaymentStatus.success) {
          widget.onPaymentComplete(result);
        } else {
          widget.onPaymentFailed(result);
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      final errorResult = PaymentResult(
        status: PaymentStatus.failed,
        message: 'Payment error: $e',
      );
      
      widget.onPaymentFailed(errorResult);
    }
  }
}

/// Payment method information
class PaymentMethodInfo {
  final String name;
  final String description;
  final IconData icon;
  final String buttonText;

  const PaymentMethodInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.buttonText,
  });
}