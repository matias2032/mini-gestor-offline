// screens/sale/sale_category_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sale_category_model.dart';
import '../../providers/sale_provider.dart';
import 'sale_category_form_screen.dart';
import '/widgets/app_sidebar.dart';

class SaleCategoryListScreen extends StatefulWidget {
  const SaleCategoryListScreen({super.key});

  @override
  State<SaleCategoryListScreen> createState() =>
      _SaleCategoryListScreenState();
}

class _SaleCategoryListScreenState extends State<SaleCategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadCategories();
    });
  }

  Future<void> _confirmDelete(SaleCategoryModel category) async {
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

    if (confirmed == true && mounted) {
      final success = await context
          .read<SaleProvider>()
          .deleteCategory(category.idSaleCategory!);
      if (!success && mounted) {
        final error = context.read<SaleProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Could not delete category.')),
        );
      }
    }
  }

  Future<void> _openForm({SaleCategoryModel? category}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaleCategoryFormScreen(category: category),
      ),
    );
    if (mounted) {
      context.read<SaleProvider>().loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<SaleProvider>().categories;
    final isLoading = context.watch<SaleProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Sale Categories')),
       drawer: const AppSidebar(currentRoute: '/sale-category'),
      body: RefreshIndicator(
        onRefresh: () => context.read<SaleProvider>().loadCategories(),
        child: isLoading && categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : categories.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No sale categories yet.')),
                    ],
                  )
                : ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        title: Text(category.name),
                        subtitle: category.description != null
                            ? Text(category.description!)
                            : null,
                        onTap: () => _openForm(category: category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(category),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add category',
        child: const Icon(Icons.add),
      ),
    );
  }
}