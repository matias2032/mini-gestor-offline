import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Handles both creation and editing.
/// `customer == null` → create mode. `customer != null` → edit mode.
class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final CustomerModel? customer;

  bool get isEditing => customer != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _lastNameController = TextEditingController(text: customer?.lastName ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _notesController = TextEditingController(text: customer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final customerProvider = context.read<CustomerProvider>();

    final success = widget.isEditing
        ? await customerProvider.updateCustomer(
            idCustomer: widget.customer!.idCustomer,
            name: _nameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            notes: _notesController.text.trim(),
          )
        : await customerProvider.createCustomer(
            name: _nameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            notes: _notesController.text.trim(),
          );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    }
    // On failure, the provider's errorMessage is shown on the form below.
  }

  Future<void> _delete() async {
    final customer = widget.customer;
    if (customer == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCustomer),
        content: Text(l10n.confirmDeleteCustomerMessage(customer.name)),
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

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<CustomerProvider>().deleteCustomer(customer.idCustomer);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editCustomer : l10n.newCustomer),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: l10n.deleteCustomer,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: l10n.lastName,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.notesLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                if (customerProvider.errorMessage != null) ...[
                  Text(
                    customerProvider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: customerProvider.isLoading ? null : _submit,
                    child: customerProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? l10n.saveChanges : l10n.createCustomer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

