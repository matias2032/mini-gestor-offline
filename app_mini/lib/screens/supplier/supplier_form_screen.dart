import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/supplier_model.dart';
import '../../providers/supplier_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key, this.supplier});

  final SupplierModel? supplier;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name);
    _phoneController = TextEditingController(text: widget.supplier?.phone);
    _addressController = TextEditingController(text: widget.supplier?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final supplierProvider = context.read<SupplierProvider>();
    final success = _isEditing
        ? await supplierProvider.updateSupplier(
            idSupplier: widget.supplier!.idSupplier!,
            name: _nameController.text,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
          )
        : await supplierProvider.createSupplier(
            name: _nameController.text,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
          );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSupplier),
        content: Text(l10n.deleteSupplierConfirmationGeneric),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<SupplierProvider>().deleteSupplier(
        widget.supplier!.idSupplier!,
      );
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editSupplier : l10n.newSupplier),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.nameFieldLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.nameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l10n.phone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: l10n.addressLabel),
              ),
              const SizedBox(height: 20),
              if (supplierProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    supplierProvider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: supplierProvider.isLoading ? null : _submit,
                child: supplierProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? l10n.saveChanges : l10n.createSupplier),
              ),
            ],
          ),
        ),
      ),
    );
  }
}