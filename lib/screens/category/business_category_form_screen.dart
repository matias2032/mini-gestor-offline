// screens/category/business_category_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business_category_model.dart';
import '../../providers/business_category_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

class BusinessCategoryFormScreen extends StatefulWidget {
  const BusinessCategoryFormScreen({super.key, this.category});

  final BusinessCategoryModel? category;

  @override
  State<BusinessCategoryFormScreen> createState() =>
      _BusinessCategoryFormScreenState();
}

class _BusinessCategoryFormScreenState
    extends State<BusinessCategoryFormScreen> {
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

    final provider = context.read<BusinessCategoryProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final success = _isEditing
        ? await provider.updateCategory(
            idBusinessCategory: widget.category!.idBusinessCategory!,
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
    final l10n = AppLocalizations.of(context)!;
    final errorMessage = context.watch<BusinessCategoryProvider>().errorMessage;
    final isLoading = context.watch<BusinessCategoryProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editCategoryTitle : l10n.newCategoryTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.nameFieldLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.nameRequiredMessage
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.descriptionOptionalLabel),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? l10n.saveChanges : l10n.createCategoryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}