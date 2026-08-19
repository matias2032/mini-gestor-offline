import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import 'customer_form_screen.dart';
import '/widgets/app_sidebar.dart';
import 'package:mini/l10n/app_localizations.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    // Load the list as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  Future<void> _confirmDelete(CustomerModel customer) async {
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

    if (confirmed == true && mounted) {
      await context.read<CustomerProvider>().deleteCustomer(customer.idCustomer);
    }
  }

  void _openForm({CustomerModel? customer}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(customer: customer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customersTitle)),
      drawer: const AppSidebar(currentRoute: '/customer'),
      body: RefreshIndicator(
        onRefresh: () => context.read<CustomerProvider>().loadCustomers(),
        child: _buildBody(customerProvider, l10n),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: l10n.newCustomer,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(CustomerProvider customerProvider, AppLocalizations l10n) {
    if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customerProvider.errorMessage != null && customerProvider.customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            customerProvider.errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (customerProvider.customers.isEmpty) {
      return ListView(
        // ListView (not Center) so RefreshIndicator keeps working.
        children: [
          const SizedBox(height: 120),
          Center(child: Text(l10n.noCustomersYet)),
        ],
      );
    }

    return ListView.separated(
      itemCount: customerProvider.customers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = customerProvider.customers[index];
        final fullName = [customer.name, customer.lastName]
            .where((part) => part != null && part.isNotEmpty)
            .join(' ');

        return ListTile(
          title: Text(fullName),
          subtitle: customer.phone != null ? Text(customer.phone!) : null,
          onTap: () => _openForm(customer: customer),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(customer),
          ),
        );
      },
    );
  }
}

