import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';
import 'expense_filter_sheet.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseProvider>().loadCategories();
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
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${expense.description}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Deletion reason',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
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

  void _openForm({ExpenseModel? expense}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'MZN ', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
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
      body: RefreshIndicator(
        onRefresh: () => context.read<ExpenseProvider>().loadExpenses(),
        child: expenseProvider.isLoading && expenseProvider.expenses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : expenseProvider.expenses.isEmpty
                ? const Center(child: Text('No expenses registered.'))
                : ListView.builder(
                    itemCount: expenseProvider.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenseProvider.expenses[index];
                      final category = expenseProvider.categories.firstWhere(
                        (c) => c.idExpenseCategory == expense.expenseCategoryId,
                        orElse: () => expenseProvider.categories.first,
                      );
                      return ListTile(
                        title: Text(expense.description),
                        subtitle: Text(
                          '${category.name} · ${dateFormat.format(expense.expenseDate)}',
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