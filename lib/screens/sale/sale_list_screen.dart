// screens/sale/sale_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/sale_model.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import 'sale_form_screen.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  String? _saleTypeFilter;
  String? _saleStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadCategories();
      _applyFilters();
    });
  }

  void _applyFilters() {
    context.read<SaleProvider>().loadSales(
          saleType: _saleTypeFilter,
          saleStatus: _saleStatusFilter,
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

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SaleProvider>().sales;
    final isLoading = context.watch<SaleProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _saleStatusFilter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                          value: 'OUTSTANDING', child: Text('Outstanding')),
                      DropdownMenuItem(
                          value: 'COMPLETED', child: Text('Completed')),
                      DropdownMenuItem(
                          value: 'CANCELLED', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() => _saleStatusFilter = value);
                      _applyFilters();
                    },
                  ),
                ),
              ],
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
                            Center(child: Text('No sales yet.')),
                          ],
                        )
                      : ListView.separated(
                          itemCount: sales.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sale = sales[index];
                            final canCancel = sale.saleStatus != 'CANCELLED' &&
                                sale.saleStatus != 'COMPLETED';
                            return ListTile(
                              title: Text('${sale.reference} — ${sale.description}'),
                              subtitle: Text(
                                '${amountFormat.format(sale.totalAmountCents / 100)} $currency'
                                '${sale.isCredit ? ' • ${sale.creditModality}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(sale.saleStatus),
                                    backgroundColor:
                                        _statusColor(sale.saleStatus).withOpacity(0.15),
                                    labelStyle:
                                        TextStyle(color: _statusColor(sale.saleStatus)),
                                  ),
                                  if (canCancel)
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined),
                                      onPressed: () => _confirmCancel(sale),
                                    ),
                                ],
                              ),
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