// screens/sale/sale_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale_installment_model.dart';
import '../../models/sale_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import 'credit_sale_list_screen.dart';
import 'sale_form_screen.dart';
import '/widgets/app_sidebar.dart';

/// Lists finished sales only: every NORMAL sale (always COMPLETED), plus
/// CREDIT sales once they're settled (COMPLETED or CANCELLED). Active
/// credit sales live in CreditSaleListScreen instead.
class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  String? _saleTypeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadCategories();
      context.read<CustomerProvider>().loadCustomers();
      context.read<SaleProvider>().loadOutstandingCreditCount();
      _applyFilters();
    });
  }

  void _applyFilters() {
    context.read<SaleProvider>().loadSales(
          saleType: _saleTypeFilter,
        );
  }

  Future<void> _confirmCancel(SaleModel sale) async {
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
            saleId: sale.idSale!,
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

  Future<void> _openForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SaleFormScreen()),
    );
    if (mounted) _applyFilters();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'OUTSTANDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _customerName(SaleModel sale) {
    if (sale.walkInCustomerName != null) return sale.walkInCustomerName!;
    if (sale.customerId == null) return 'No customer';
    final customers = context.read<CustomerProvider>().customers;
    for (final customer in customers) {
      if (customer.idCustomer == sale.customerId) return customer.name;
    }
    return 'Customer #${sale.customerId}';
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SaleProvider>().sales;
    final isLoading = context.watch<SaleProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finished Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.credit_score_outlined),
            tooltip: 'Credit sales',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreditSaleListScreen()),
              );
            },
          ),
        ],
      ),
drawer: AppSidebar(
        currentRoute: '/sale',
        creditSalesBadgeCount: context.watch<SaleProvider>().outstandingCreditCount,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _saleTypeFilter,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                DropdownMenuItem(value: 'CREDIT', child: Text('Credit')),
              ],
              onChanged: (value) {
                setState(() => _saleTypeFilter = value);
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _applyFilters(),
              child: isLoading && sales.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : sales.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No finished sales yet.')),
                          ],
                        )
                      : ListView.separated(
                          itemCount: sales.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sale = sales[index];
                            return _SaleListItem(
                              sale: sale,
                              customerName: _customerName(sale),
                              currency: currency,
                              amountFormat: amountFormat,
                              statusColor: _statusColor(sale.saleStatus),
                              onCancel: sale.saleStatus != 'CANCELLED' &&
                                      sale.saleStatus != 'COMPLETED'
                                  ? () => _confirmCancel(sale)
                                  : null,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: 'New sale',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// One row in the finished sales list. NORMAL sales render as a plain
/// ListTile. CREDIT sales render as an ExpansionTile so they can show
/// how many installments settled the debt, and what each one was —
/// loaded lazily on first expand.
class _SaleListItem extends StatelessWidget {
  const _SaleListItem({
    required this.sale,
    required this.customerName,
    required this.currency,
    required this.amountFormat,
    required this.statusColor,
    required this.onCancel,
  });

  final SaleModel sale;
  final String customerName;
  final String currency;
  final NumberFormat amountFormat;
  final Color statusColor;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final title = Text('${sale.reference} — ${sale.description}');
    final subtitle = Text(
      '$customerName • ${sale.isCredit ? 'Credit' : 'Immediate'}\n'
      '${amountFormat.format(sale.totalAmountCents / 100)} $currency',
    );
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          label: Text(sale.saleStatus),
          backgroundColor: statusColor.withOpacity(0.15),
          labelStyle: TextStyle(color: statusColor),
        ),
        if (onCancel != null)
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            onPressed: onCancel,
          ),
      ],
    );

    if (!sale.isCredit) {
      return ListTile(
        title: title,
        subtitle: subtitle,
        isThreeLine: true,
        trailing: trailing,
      );
    }

    return ExpansionTile(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      children: [
        FutureBuilder<List<SaleInstallmentModel>>(
          future: context.read<SaleProvider>().installmentsForSale(sale.idSale!),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final installments = snapshot.data ?? [];
            if (installments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('No installments registered.'),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paid in ${installments.length} '
                    'installment${installments.length > 1 ? 's' : ''}:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  for (final installment in installments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '#${installment.installmentNumber} — '
                        '${amountFormat.format(installment.paidAmountCents / 100)} $currency'
                        '${installment.paidAt != null ? ' • ${DateFormat('dd/MM/yyyy').format(installment.paidAt!.toLocal())}' : ''}',
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}