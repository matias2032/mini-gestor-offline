// screens/category/business_category_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_category_model.dart';
import '../../providers/business_category_provider.dart';
import 'business_category_form_screen.dart';
import '/widgets/app_sidebar.dart';
import 'package:mini/l10n/app_localizations.dart';

class BusinessCategoryListScreen extends StatefulWidget {
  const BusinessCategoryListScreen({super.key});

  @override
  State<BusinessCategoryListScreen> createState() =>
      _BusinessCategoryListScreenState();
}

class _BusinessCategoryListScreenState
    extends State<BusinessCategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessCategoryProvider>().loadCategories();
    });
  }

  Future<void> _confirmDelete(BusinessCategoryModel category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle),
        content: Text(l10n.confirmDeleteCategoryMessage(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context
          .read<BusinessCategoryProvider>()
          .deleteCategory(category.idBusinessCategory!);
      if (!success && mounted) {
        final error = context.read<BusinessCategoryProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? l10n.couldNotDeleteCategory)),
        );
      }
    }
  }

  Future<void> _openForm({BusinessCategoryModel? category}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessCategoryFormScreen(category: category),
      ),
    );
    if (mounted) {
      context.read<BusinessCategoryProvider>().loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = context.watch<BusinessCategoryProvider>().categories;
    final isLoading = context.watch<BusinessCategoryProvider>().isLoading;

    return Scaffold(
appBar: AppBar(title: Text(l10n.categoriesTitle)),
      drawer: const AppSidebar(currentRoute: '/category'),
      body: RefreshIndicator(
        onRefresh: () => context.read<BusinessCategoryProvider>().loadCategories(),
        child: isLoading && categories.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : categories.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(l10n.noCategoriesYet)),
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
        tooltip: l10n.addCategoryTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}