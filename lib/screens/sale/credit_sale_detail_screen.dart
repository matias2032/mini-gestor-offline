// screens/sale/credit_sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';

/// Detail screen for a single CREDIT sale. This is where each new
/// payment is registered; every payment registered here automatically
/// generates the next installment (see SaleRepository._applyPayment).
class CreditSaleDetailScreen extends StatefulWidget {
  const CreditSaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  State<CreditSaleDetailScreen> createState() =>
      _CreditSaleDetailScreenState();
}

class _CreditSaleDetailScreenState extends State<CreditSaleDetailScreen> {
  final _paymentFormKey = GlobalKey<FormState>();
  final _paymentAmountController = TextEditingController();
  final _paymentNotesController = TextEditingController();
  String _paymentMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSaleDetail(widget.saleId);
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _paymentNotesController.dispose();
    super.dispose();
  }

  int _toCents(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    return (value * 100).round();
  }

  String _debtorName(String? walkInName, int? customerId) {
    if (walkInName != null) return walkInName;
    if (customerId == null) return 'Unknown customer';
    final customers = context.read<CustomerProvider>().customers;
    for (final customer in customers) {
      if (customer.idCustomer == customerId) return customer.name;
    }
    return 'Customer #$customerId';
  }

  Future<void> _submitPayment(int remainingCents) async {
    if (!_paymentFormKey.currentState!.validate()) return;

    final amountCents = _toCents(_paymentAmountController.text);
    if (amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid payment amount.')),
      );
      return;
    }
    if (amountCents > remainingCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment exceeds the remaining debt.')),
      );
      return;
    }

    final success = await context.read<SaleProvider>().registerPayment(
          saleId: widget.saleId,
          paidAmountCents: amountCents,
          paymentMethod: _paymentMethod,
          notes: _paymentNotesController.text.trim().isEmpty
              ? null
              : _paymentNotesController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      _paymentAmountController.clear();
      _paymentNotesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment registered.')),
      );
    } else {
      final error = context.read<SaleProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not register payment.')),
      );
    }
  }

  Future<void> _confirmCancel() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel sale'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Cancellation reason'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Sale'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SaleProvider>().cancelSale(
            saleId: widget.saleId,
            cancellationReason: reasonController.text,
          );
      if (!success && mounted) {
        final error = context.read<SaleProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Could not cancel sale.')),
        );
      }
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sale = context.watch<SaleProvider>().currentSale;
    final payments = context.watch<SaleProvider>().payments;
    final isLoading = context.watch<SaleProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (sale == null || sale.idSale != widget.saleId) {
      return Scaffold(
        appBar: AppBar(title: const Text('Credit Sale')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Sale not found.')),
      );
    }

    final remainingCents = sale.totalAmountCents - sale.paidAmountCents;
    final isSettled =
        sale.saleStatus == 'COMPLETED' || sale.saleStatus == 'CANCELLED';

    return Scaffold(
      appBar: AppBar(
        title: Text(sale.reference),
        actions: [
          if (!isSettled)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel sale',
              onPressed: _confirmCancel,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _debtorName(sale.walkInCustomerName, sale.customerId),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(sale.description),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Total',
                    value:
                        '${amountFormat.format(sale.totalAmountCents / 100)} $currency',
                  ),
                  _InfoRow(
                    label: 'Paid so far',
                    value:
                        '${amountFormat.format(sale.paidAmountCents / 100)} $currency',
                  ),
                  _InfoRow(
                    label: 'Remaining debt',
                    value:
                        '${amountFormat.format(remainingCents / 100)} $currency',
                    valueColor: remainingCents > 0 ? Colors.red : Colors.green,
                  ),
                  _InfoRow(label: 'Status', value: sale.saleStatus),
                  _InfoRow(label: 'Payment status', value: sale.paymentStatus),
                  if (sale.creditDueDate != null)
                    _InfoRow(
                      label: 'Due date',
                      value: '${sale.creditDueDate!.toLocal()}'.split(' ').first,
                    ),
                ],
              ),
            ),
          ),
          if (!isSettled) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _paymentFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Register payment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paymentAmountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final cents = _toCents(value ?? '');
                          return cents <= 0 ? 'Enter a valid amount' : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration:
                            const InputDecoration(labelText: 'Payment method'),
                        items: const [
                          DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                          DropdownMenuItem(
                              value: 'BANK_TRANSFER', child: Text('Bank transfer')),
                          DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                          DropdownMenuItem(value: 'EMOLA', child: Text('E-Mola')),
                          DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                        ],
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paymentNotesController,
                        decoration:
                            const InputDecoration(labelText: 'Notes (optional)'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submitPayment(remainingCents),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Register payment'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Payment history', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            const Text('No payments registered yet.')
          else
            ...payments.map(
              (payment) => Card(
                child: ListTile(
                  title: Text(
                    '${amountFormat.format(payment.paidAmountCents / 100)} $currency'
                    ' • ${payment.paymentMethod}',
                  ),
                  subtitle: Text(dateFormat.format(payment.paidAt.toLocal())),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}