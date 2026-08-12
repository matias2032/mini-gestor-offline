import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import 'customer_form_screen.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? '
          'Associated sales history will be kept.',
        ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: RefreshIndicator(
        onRefresh: () => context.read<CustomerProvider>().loadCustomers(),
        child: _buildBody(customerProvider),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'New customer',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(CustomerProvider customerProvider) {
    if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (customerProvider.errorMessage != null && customerProvider.customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            customerProvider.errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (customerProvider.customers.isEmpty) {
      return ListView(
        // ListView (not Center) so RefreshIndicator keeps working.
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No customers registered yet.')),
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