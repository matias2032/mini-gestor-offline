// screens/sale/credit_sale_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import 'credit_sale_detail_screen.dart';
import '/widgets/app_sidebar.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Lists only active (unpaid) CREDIT sales — the ones excluded from the
/// main sales list. Each entry shows who owes, how much, and how much
/// has already been paid. Tapping a sale opens its detail screen, where
/// new payments are registered.
class CreditSaleListScreen extends StatefulWidget {
  const CreditSaleListScreen({super.key});

  @override
  State<CreditSaleListScreen> createState() => _CreditSaleListScreenState();
}

class _CreditSaleListScreenState extends State<CreditSaleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadCreditSales();
      context.read<CustomerProvider>().loadCustomers();
            context.read<SaleProvider>().loadOutstandingCreditCount();
    });
  }

  Future<void> _refresh() {
    return context.read<SaleProvider>().loadCreditSales();
  }

  String _debtorName(SaleModel sale, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (sale.walkInCustomerName != null) return sale.walkInCustomerName!;
    if (sale.customerId == null) return loc.unknownCustomer;
    final customers = context.read<CustomerProvider>().customers;
    for (final customer in customers) {
      if (customer.idCustomer == sale.customerId) return customer.name;
    }
    return loc.customerNumber(sale.customerId.toString());
  }

  Color _statusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'PARTIAL':
        return Colors.orange;
      case 'PAID':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final creditSales = context.watch<SaleProvider>().creditSales;
    final isLoading = context.watch<SaleProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: Text(loc.creditSalesTitle)),
      drawer: AppSidebar(
        currentRoute: '/credit-sale',
        creditSalesBadgeCount: context.watch<SaleProvider>().outstandingCreditCount,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: isLoading && creditSales.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : creditSales.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(loc.noOutstandingCreditSales)),
                    ],
                  )
                : ListView.separated(
                    itemCount: creditSales.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final sale = creditSales[index];
                      final remainingCents =
                          sale.totalAmountCents - sale.paidAmountCents;
                      return ListTile(
                        title: Text(_debtorName(sale, context)),
                        subtitle: Text(
                          loc.creditSaleSubtitle(
                            sale.reference,
                            sale.description,
                            amountFormat.format(remainingCents / 100),
                            currency,
                            amountFormat.format(sale.paidAmountCents / 100),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(sale.paymentStatus),
                          backgroundColor:
                              _statusColor(sale.paymentStatus).withOpacity(0.15),
                          labelStyle:
                              TextStyle(color: _statusColor(sale.paymentStatus)),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreditSaleDetailScreen(saleId: sale.idSale!),
                            ),
                          );
                          if (context.mounted) await _refresh();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}