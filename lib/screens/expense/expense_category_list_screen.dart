import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_category_model.dart';
import '../../providers/expense_provider.dart';
import 'expense_category_form_screen.dart';
import '/widgets/app_sidebar.dart';

class ExpenseCategoryListScreen extends StatefulWidget {
  const ExpenseCategoryListScreen({super.key});

  @override
  State<ExpenseCategoryListScreen> createState() =>
      _ExpenseCategoryListScreenState();
}

class _ExpenseCategoryListScreenState
    extends State<ExpenseCategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadCategories();
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ExpenseCategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
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

    if (confirmed == true && context.mounted) {
      final success = await context
          .read<ExpenseProvider>()
          .deleteCategory(category.idExpenseCategory!);
      if (!success && context.mounted) {
        final error = context.read<ExpenseProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to delete category.')),
        );
      }
    }
  }

  Future<void> _openForm(
    BuildContext context, {
    ExpenseCategoryModel? category,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseCategoryFormScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Categories')),
            drawer: const AppSidebar(currentRoute: '/expense-category'),
      body: RefreshIndicator(
        onRefresh: () => context.read<ExpenseProvider>().loadCategories(),
        child: categories.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No categories yet.')),
                ],
              )
            : ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category.name),
                    subtitle:
                        category.description != null &&
                                category.description!.isNotEmpty
                            ? Text(category.description!)
                            : null,
                    onTap: () => _openForm(context, category: category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, category),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}