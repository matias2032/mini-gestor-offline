import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supplier_model.dart';
import '../../providers/supplier_provider.dart';
import 'supplier_form_screen.dart';
import '/widgets/app_sidebar.dart';
import 'package:mini/l10n/app_localizations.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupplierProvider>().loadSuppliers();
  }

  Future<void> _confirmDelete(SupplierModel supplier) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSupplier),
        content: Text(l10n.confirmDeleteSupplierMessage(supplier.name)),
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
      await context.read<SupplierProvider>().deleteSupplier(
        supplier.idSupplier!,
      );
    }
  }

  void _openForm({SupplierModel? supplier}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierFormScreen(supplier: supplier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.suppliersTitle)),
      drawer: const AppSidebar(currentRoute: '/supplier'),
      body: RefreshIndicator(
        onRefresh: () => context.read<SupplierProvider>().loadSuppliers(),
        child: supplierProvider.isLoading && supplierProvider.suppliers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : supplierProvider.suppliers.isEmpty
                ? Center(child: Text(l10n.noSuppliersYet))
                : ListView.builder(
                    itemCount: supplierProvider.suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = supplierProvider.suppliers[index];
                      return ListTile(
                        title: Text(supplier.name),
                        subtitle: supplier.phone != null
                            ? Text(supplier.phone!)
                            : null,
                        onTap: () => _openForm(supplier: supplier),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(supplier),
                        ),
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