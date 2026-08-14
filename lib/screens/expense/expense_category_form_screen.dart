import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense_category_model.dart';
import '../../providers/expense_provider.dart';

class ExpenseCategoryFormScreen extends StatefulWidget {
  const ExpenseCategoryFormScreen({super.key, this.category});

  final ExpenseCategoryModel? category;

  @override
  State<ExpenseCategoryFormScreen> createState() =>
      _ExpenseCategoryFormScreenState();
}

class _ExpenseCategoryFormScreenState
    extends State<ExpenseCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ExpenseProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final success = _isEditing
        ? await provider.updateCategory(
            idExpenseCategory: widget.category!.idExpenseCategory!,
            name: name,
            description: description.isEmpty ? null : description,
          )
        : await provider.createCategory(
            name: name,
            description: description.isEmpty ? null : description,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Category' : 'New Category')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save' : 'Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}