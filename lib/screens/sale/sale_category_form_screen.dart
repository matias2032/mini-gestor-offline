// screens/sale/sale_category_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sale_category_model.dart';
import '../../providers/sale_provider.dart';

class SaleCategoryFormScreen extends StatefulWidget {
  const SaleCategoryFormScreen({super.key, this.category});

  final SaleCategoryModel? category;

  @override
  State<SaleCategoryFormScreen> createState() =>
      _SaleCategoryFormScreenState();
}

class _SaleCategoryFormScreenState extends State<SaleCategoryFormScreen> {
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

    final provider = context.read<SaleProvider>();
    final success = _isEditing
        ? await provider.updateCategory(
            idSaleCategory: widget.category!.idSaleCategory!,
            name: _nameController.text,
            description: _descriptionController.text,
          )
        : await provider.createCategory(
            name: _nameController.text,
            description: _descriptionController.text,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = context.watch<SaleProvider>().errorMessage;
    final isLoading = context.watch<SaleProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Category' : 'New Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
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
    );
  }
}