// screens/sale/financial_statement_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/financial_statement_model.dart';
import '../../providers/financial_statement_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import '/widgets/app_sidebar.dart';
import 'financial_statement_detail_screen.dart';
import 'financial_statement_generate_screen.dart';

/// Lists all generated financial statements ("extractos"), most recent
/// first. Each statement is a frozen snapshot — nothing here recomputes
/// totals from live sale/expense data.
class FinancialStatementListScreen extends StatefulWidget {
  const FinancialStatementListScreen({super.key});

  @override
  State<FinancialStatementListScreen> createState() =>
      _FinancialStatementListScreenState();
}

class _FinancialStatementListScreenState
    extends State<FinancialStatementListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialStatementProvider>().loadStatements();
      context.read<SaleProvider>().loadOutstandingCreditCount();
    });
  }

  Future<void> _openGenerate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FinancialStatementGenerateScreen()),
    );
    if (mounted) context.read<FinancialStatementProvider>().loadStatements();
  }

  Future<void> _openDetail(int idFinancialStatement) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinancialStatementDetailScreen(
          idFinancialStatement: idFinancialStatement,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FinancialStatementModel statement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete statement'),
        content: Text(
          'Delete statement ${statement.reference}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<FinancialStatementProvider>()
          .deleteStatement(statement.idFinancialStatement!);
      if (!success && mounted) {
        final error = context.read<FinancialStatementProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Could not delete statement.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statements = context.watch<FinancialStatementProvider>().statements;
    final isLoading = context.watch<FinancialStatementProvider>().isLoading;
    final currency = context.watch<UserProvider>().user?.currency ?? 'MZN';
    final amountFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Statements')),
      drawer: AppSidebar(
        currentRoute: '/sale/financial-statement',
        creditSalesBadgeCount: context.watch<SaleProvider>().outstandingCreditCount,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FinancialStatementProvider>().loadStatements(),
        child: isLoading && statements.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : statements.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No statements generated yet.')),
                    ],
                  )
                : ListView.separated(
                    itemCount: statements.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final statement = statements[index];
                      final balanceColor =
                          statement.balanceCents >= 0 ? Colors.green : Colors.red;
                      return ListTile(
                        title: Text(
                          '${statement.reference} — ${statement.periodType.label}',
                        ),
                        subtitle: Text(
                          '${dateFormat.format(statement.startDate.toLocal())} - '
                          '${dateFormat.format(statement.endDate.toLocal())}\n'
                          'Generated ${dateFormat.format(statement.generatedAt.toLocal())}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${amountFormat.format(statement.balanceCents / 100)} $currency',
                              style: TextStyle(
                                color: balanceColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(statement),
                            ),
                          ],
                        ),
                        onTap: () => _openDetail(statement.idFinancialStatement!),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openGenerate,
        tooltip: 'Generate statement',
        child: const Icon(Icons.add),
      ),
    );
  }
}