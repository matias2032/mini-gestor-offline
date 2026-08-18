import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/business_category_provider.dart';
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
  // One expense can now have 2+ categories, so the list row needs the
  // splits, not just expense.expenseCategoryId (which no longer exists).
  // Cached per idExpense to avoid re-querying on every rebuild; cleared
  // whenever the underlying list is reloaded.
  final Map<int, List<ExpenseCategorySplitModel>> _splitsCache = {};

  @override
  void initState() {
    super.initState();
    context.read<BusinessCategoryProvider>().loadCategories();
    context.read<ExpenseProvider>().loadExpenses();
    context.read<SupplierProvider>().loadSuppliers();
  }

  Future<List<ExpenseCategorySplitModel>> _splitsFor(int idExpense) async {
    final cached = _splitsCache[idExpense];
    if (cached != null) return cached;
    final splits = await context.read<ExpenseProvider>().getSplitsByExpense(idExpense);
    _splitsCache[idExpense] = splits;
    return splits;
  }

  Future<void> _refresh() async {
    _splitsCache.clear();
    await context.read<ExpenseProvider>().loadExpenses();
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
    // Allocations may have changed (created/edited); drop stale cache.
    _splitsCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final businessCategoryProvider = context.watch<BusinessCategoryProvider>();
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
        onRefresh: _refresh,
        child: expenseProvider.isLoading && expenseProvider.expenses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : expenseProvider.expenses.isEmpty
                ? Center(child: Text(l10n.noExpensesYet))
                : ListView.builder(
                    itemCount: expenseProvider.expenses.length,
                   itemBuilder: (context, index) {
                      final expense = expenseProvider.expenses[index];
                      return FutureBuilder<List<ExpenseCategorySplitModel>>(
                        future: _splitsFor(expense.idExpense!),
                        builder: (context, snapshot) {
                          final splits = snapshot.data;
                          final categoryLabel = splits == null
                              ? '…'
                              : splits
                                  .map((s) => businessCategoryProvider.categories
                                      .firstWhere(
                                        (c) => c.idBusinessCategory == s.businessCategoryId,
                                        orElse: () => businessCategoryProvider.categories.first,
                                      )
                                      .name)
                                  .join(', ');
                          return ListTile(
                            title: Text(expense.description),
                            subtitle: Text(
                              '$categoryLabel · ${dateFormat.format(expense.expenseDate)}',
                            ),
                            trailing: Text(
                              currencyFormat.format(expense.amountCents / 100),
                            ),
                            onTap: () => _openForm(expense: expense),
                            onLongPress: () => _confirmDelete(expense),
                          );
                        },
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