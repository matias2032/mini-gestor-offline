// screens/sale/credit_sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    if (walkInName != null) return walkInName;
    if (customerId == null) return loc.unknownCustomer;
    final customers = context.read<CustomerProvider>().customers;
    for (final customer in customers) {
      if (customer.idCustomer == customerId) return customer.name;
    }
    return loc.customerNumber(customerId.toString());
  }

  Future<void> _submitPayment(int remainingCents) async {
    if (!_paymentFormKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context)!;
    final amountCents = _toCents(_paymentAmountController.text);
    if (amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterValidPaymentAmount)),
      );
      return;
    }
    if (amountCents > remainingCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.paymentExceedsRemainingDebt)),
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

    final loc2 = AppLocalizations.of(context)!;
    if (success) {
      _paymentAmountController.clear();
      _paymentNotesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc2.paymentRegistered)),
      );
    } else {
      final error = context.read<SaleProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? loc2.couldNotRegisterPayment)),
      );
    }
  }

  Future<void> _confirmCancel() async {
    final loc = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.cancelSale),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: loc.cancellationReasonLabel),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.back),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(loc.cancelSaleButton),
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
        final loc2 = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? loc2.couldNotCancelSale)),
        );
      }
    }
    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sale = context.watch<SaleProvider>().currentSale;
    final payments = context.watch<SaleProvider>().payments;
    final isLoading = context.watch<SaleProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (sale == null || sale.idSale != widget.saleId) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.creditSaleTitle)),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Text(loc.saleNotFound)),
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
              tooltip: loc.cancelSale,
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
                    label: loc.totalLabel,
                    value:
                        '${amountFormat.format(sale.totalAmountCents / 100)} $currency',
                  ),
                  _InfoRow(
                    label: loc.paidSoFarLabel,
                    value:
                        '${amountFormat.format(sale.paidAmountCents / 100)} $currency',
                  ),
                  _InfoRow(
                    label: loc.remainingDebtLabel,
                    value:
                        '${amountFormat.format(remainingCents / 100)} $currency',
                    valueColor: remainingCents > 0 ? Colors.red : Colors.green,
                  ),
                  _InfoRow(label: loc.statusLabel, value: sale.saleStatus),
                  _InfoRow(
                      label: loc.paymentStatusLabel,
                      value: sale.paymentStatus),
                  if (sale.creditDueDate != null)
                    _InfoRow(
                      label: loc.dueDateLabel,
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
                      Text(
                        loc.registerPayment,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paymentAmountController,
                        decoration:
                            InputDecoration(labelText: loc.amountFieldLabel),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final cents = _toCents(value ?? '');
                          return cents <= 0 ? loc.enterValidAmount : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(
                            labelText: loc.paymentMethodLabel),
                        items: [
                          DropdownMenuItem(
                              value: 'CASH', child: Text(loc.cashMethod)),
                          DropdownMenuItem(
                              value: 'BANK_TRANSFER',
                              child: Text(loc.bankTransferMethod)),
                          DropdownMenuItem(
                              value: 'MPESA', child: Text(loc.mpesaMethod)),
                          DropdownMenuItem(
                              value: 'EMOLA', child: Text(loc.emolaMethod)),
                          DropdownMenuItem(
                              value: 'OTHER', child: Text(loc.otherMethod)),
                        ],
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _paymentNotesController,
                        decoration: InputDecoration(
                            labelText: loc.notesOptionalLabel),
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
                            : Text(loc.registerPayment),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(loc.paymentHistory,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (payments.isEmpty)
            Text(loc.noPaymentsYet)
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