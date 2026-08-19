// screens/sale/financial_statement_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/financial_statement_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/financial_statement_model.dart';
import 'package:mini/l10n/app_localizations.dart';

class FinancialStatementDetailScreen extends StatefulWidget {
  const FinancialStatementDetailScreen({
    super.key,
    required this.idFinancialStatement,
  });

  final int idFinancialStatement;

  @override
  State<FinancialStatementDetailScreen> createState() =>
      _FinancialStatementDetailScreenState();
}

class _FinancialStatementDetailScreenState
    extends State<FinancialStatementDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<FinancialStatementProvider>()
          .loadStatementDetail(widget.idFinancialStatement);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = context.watch<FinancialStatementProvider>().currentDetail;
    final isLoading = context.watch<FinancialStatementProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');

    if (isLoading ||
        detail == null ||
        detail.statement.idFinancialStatement != widget.idFinancialStatement) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.statementDetailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final statement = detail.statement;
    final balanceColor = statement.balanceCents >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(statement.reference)),
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
                    statement.periodType.label,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(statement.startDate.toLocal())} - '
                    '${dateFormat.format(statement.endDate.toLocal())}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: l10n.salesCountLabel(statement.salesCount),
                    value: '${amountFormat.format(statement.totalSalesCents / 100)} $currency',
                    valueColor: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  _SummaryRow(
                    label: l10n.expensesCountLabel(statement.expensesCount),
                    value: '${amountFormat.format(statement.totalExpensesCents / 100)} $currency',
                    valueColor: Colors.red,
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: l10n.balanceLabel,
                    value: '${amountFormat.format(statement.balanceCents / 100)} $currency',
                    valueColor: balanceColor,
                    bold: true,
                  ),
                  if (statement.notes != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      statement.notes!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.salesSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (detail.saleItems.isEmpty)
            Text(l10n.noSalesInPeriod)
          else
            Card(
              child: Column(
                children: [
                  for (final item in detail.saleItems)
                    ListTile(
                      dense: true,
                      title: Text('${item.saleReference} — ${item.saleDescription}'),
                      subtitle: Text(dateFormat.format(item.saleDate.toLocal())),
                      trailing: Text(
                        '${amountFormat.format(item.amountCents / 100)} $currency',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(l10n.expensesSectionTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (detail.expenseItems.isEmpty)
            Text(l10n.noExpensesInPeriod)
          else
            Card(
              child: Column(
                children: [
                  for (final item in detail.expenseItems)
                    ListTile(
                      dense: true,
                      title: Text(item.expenseDescription),
                      subtitle: Text(dateFormat.format(item.expenseDate.toLocal())),
                      trailing: Text(
                        '${amountFormat.format(item.amountCents / 100)} $currency',
                      ),
                    ),
                ],
              ),
            ),

          if (detail.statement.isConsolidated && detail.storeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l10n.perStoreBreakdownTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final store in detail.storeBreakdown)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(store.businessUnitName),
                      subtitle: Text(
                        '${l10n.salesSectionTitle}: ${amountFormat.format(store.totalSalesCents / 100)} $currency  •  '
                        '${l10n.expensesSectionTitle}: ${amountFormat.format(store.totalExpensesCents / 100)} $currency',
                      ),
                      trailing: Text(
                        '${amountFormat.format(store.balanceCents / 100)} $currency',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: store.balanceCents >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: valueColor)),
      ],
    );
  }
}