import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';
import 'expense_filter_sheet.dart';
import 'expense_form_screen.dart';
import '/widgets/app_sidebar.dart';
import 'package:mini/l10n/app_localizations.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().loadExpenses();
    context.read<SupplierProvider>().loadSuppliers();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ExpenseFilterSheet(),
    );
  }

  Future<void> _confirmDelete(ExpenseModel expense) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmDeleteExpenseMessage(expense.description)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.deletionReasonLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ExpenseProvider>().deleteExpense(
        expense.idExpense!,
        reasonController.text.trim(),
      );
      if (!success && mounted) {
        final error = context.read<ExpenseProvider>().errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    }
  }

  Future<void> _openForm({ExpenseModel? expense}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
  }

  String _supplierName(BuildContext context, int? supplierId) {
    if (supplierId == null) return AppLocalizations.of(context)!.noneLabel;
    final suppliers = context.read<SupplierProvider>().suppliers;
    for (final supplier in suppliers) {
      if (supplier.idSupplier == supplierId) return supplier.name;
    }
    return AppLocalizations.of(context)!.noneLabel;
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'MZN ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expensesTitle),
        actions: [
          IconButton(
            icon: Icon(
              expenseProvider.hasActiveFilters
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      drawer: const AppSidebar(currentRoute: '/expense'),
      body: RefreshIndicator(
        onRefresh: () => context.read<ExpenseProvider>().loadExpenses(),
        child: expenseProvider.isLoading && expenseProvider.expenses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : expenseProvider.expenses.isEmpty
                ? Center(child: Text(l10n.noExpensesYet))
                : ListView.builder(
                    itemCount: expenseProvider.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenseProvider.expenses[index];
                      return ListTile(
                        title: Text(expense.description),
                        subtitle: Text(
                          '${_supplierName(context, expense.supplierId)} · '
                          '${dateFormat.format(expense.expenseDate)}',
                        ),
                        trailing: Text(
                          currencyFormat.format(expense.amountCents / 100),
                        ),
                        onTap: () => _openForm(expense: expense),
                        onLongPress: () => _confirmDelete(expense),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}