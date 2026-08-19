// lib/screens/business_unit/business_unit_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business_unit_model.dart';
import '../../providers/business_unit_provider.dart';
import 'package:mini/l10n/app_localizations.dart';
import '../../widgets/app_sidebar.dart';

/// Store management: create, rename, set as default, remove. Reachable
/// from AppSidebar regardless of hasMultipleUnits — a single-store user
/// still needs a way to add their second store.
class BusinessUnitManagementScreen extends StatelessWidget {
  const BusinessUnitManagementScreen({super.key});

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    String? initialValue,
  }) {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: loc.storeNameLabel),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? loc.storeNameRequired : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: Text(loc.saveLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _createStore(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final name = await _promptForName(context, title: loc.newStore);
    if (name == null || name.isEmpty || !context.mounted) return;

    try {
      await context.read<BusinessUnitProvider>().createUnit(name);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.couldNotCreateStore)));
      }
    }
  }

  Future<void> _renameStore(BuildContext context, BusinessUnitModel unit) async {
    final loc = AppLocalizations.of(context)!;
    final name = await _promptForName(
      context,
      title: loc.renameStoreTitle,
      initialValue: unit.name,
    );
    if (name == null || name.isEmpty || name == unit.name || !context.mounted) return;

        try {
      await context.read<BusinessUnitProvider>().renameUnit(unit.idBusinessUnit!, name);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.couldNotRenameStore)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, BusinessUnitModel unit) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(loc.deleteStoreTitle),
        content: Text(loc.confirmDeleteStoreMessage(unit.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

        try {
      await context.read<BusinessUnitProvider>().deleteUnit(unit.idBusinessUnit!);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.couldNotDeleteStore)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<BusinessUnitProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(loc.storesTitle)),
      drawer: const AppSidebar(currentRoute: '/business-unit-management'),
      floatingActionButton: FloatingActionButton(
        tooltip: loc.newStore,
        onPressed: () => _createStore(context),
        child: const Icon(Icons.add),
      ),
      body: provider.isLoading && provider.units.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.units.length,
              itemBuilder: (context, index) {
                final unit = provider.units[index];
                final isActive =
                    unit.idBusinessUnit == provider.activeBusinessUnit?.idBusinessUnit;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.storefront_outlined,
                      color: isActive ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(
                      unit.name,
                      style: TextStyle(fontWeight: isActive ? FontWeight.w700 : null),
                    ),
                    subtitle: unit.isDefault ? Text(loc.defaultStoreLabel) : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        switch (action) {
                          case 'rename':
                            _renameStore(context, unit);
                            break;
                          case 'default':
                            context.read<BusinessUnitProvider>().setAsDefault(unit.idBusinessUnit!);
                            break;
                          case 'delete':
                            _confirmDelete(context, unit);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'rename', child: Text(loc.renameStoreTitle)),
                        if (!unit.isDefault)
                          PopupMenuItem(value: 'default', child: Text(loc.setAsDefault)),
                        if (provider.units.length > 1)
                          PopupMenuItem(value: 'delete', child: Text(loc.delete)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}