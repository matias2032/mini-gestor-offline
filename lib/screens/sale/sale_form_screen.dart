// screens/sale/sale_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _walkInNameController = TextEditingController();
  final _initialPaymentController = TextEditingController();
  final _notesController = TextEditingController();

  int? _saleCategoryId;
  String _saleType = 'NORMAL';

  // Customer selection applies to both NORMAL and CREDIT sales now.
  // For NORMAL it's optional; for CREDIT it's required (customer OR
  // walk-in name).
  bool _useExistingCustomer = true;
  int? _customerId;

  DateTime? _creditDueDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadCategories();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _walkInNameController.dispose();
    _initialPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _toCents(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    return (value * 100).round();
  }

  Future<void> _pickCreditDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _creditDueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isCredit = _saleType == 'CREDIT';
    final totalCents = _toCents(_totalAmountController.text);

    int? initialPaymentCents;
    if (isCredit) {
      if (_useExistingCustomer && _customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a customer.')),
        );
        return;
      }
if (!_useExistingCustomer && _walkInNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a walk-in customer name.')),
        );
        return;
      }

      // Due date is fully optional — a credit sale can have no fixed
      // deadline and simply stay OUTSTANDING until it's paid off.

      // The entry field is optional: empty means no down payment, the
      // full total stays outstanding.
      final rawEntry = _initialPaymentController.text.trim();
      if (rawEntry.isNotEmpty) {
        final entryCents = _toCents(rawEntry);
        if (entryCents <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid initial payment.')),
          );
          return;
        }
        if (entryCents > totalCents) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Initial payment cannot exceed the sale total.'),
            ),
          );
          return;
        }
        initialPaymentCents = entryCents;
      }
    }

    final provider = context.read<SaleProvider>();
    final success = await provider.createSale(
      saleCategoryId: _saleCategoryId!,
      description: _descriptionController.text,
      totalAmountCents: totalCents,
      saleType: _saleType,
      customerId: _useExistingCustomer ? _customerId : null,
      walkInCustomerName:
          !_useExistingCustomer ? _walkInNameController.text : null,
      creditDueDate: isCredit ? _creditDueDate : null,
      notes: _notesController.text,
      initialPaymentCents: initialPaymentCents,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<SaleProvider>().categories;
    final customers = context.watch<CustomerProvider>().customers;
    final errorMessage = context.watch<SaleProvider>().errorMessage;
    final isLoading = context.watch<SaleProvider>().isLoading;
    final isCredit = _saleType == 'CREDIT';

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DropdownButtonFormField<int>(
              value: _saleCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((category) => DropdownMenuItem(
                        value: category.idSaleCategory,
                        child: Text(category.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _saleCategoryId = value),
              validator: (value) => value == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalAmountController,
              decoration: const InputDecoration(labelText: 'Total amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final cents = _toCents(value ?? '');
                return cents <= 0 ? 'Enter a valid amount' : null;
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'NORMAL', label: Text('Normal')),
                ButtonSegment(value: 'CREDIT', label: Text('Credit')),
              ],
              selected: {_saleType},
              onSelectionChanged: (selection) =>
                  setState(() => _saleType = selection.first),
            ),
            const SizedBox(height: 16),
            // Customer picker: available for every sale, not just credit.
            // For NORMAL sales it's optional — leaving it unset just means
            // a walk-in sale with no customer on record.
            SwitchListTile(
              title: Text(isCredit
                  ? 'Use existing customer'
                  : 'Associate an existing customer (optional)'),
              value: _useExistingCustomer,
              onChanged: (value) => setState(() => _useExistingCustomer = value),
            ),
            if (_useExistingCustomer)
              DropdownButtonFormField<int>(
                value: _customerId,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: customers
                    .map((customer) => DropdownMenuItem(
                          value: customer.idCustomer,
                          child: Text(customer.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _customerId = value),
              )
            else if (isCredit)
              TextFormField(
                controller: _walkInNameController,
                decoration: const InputDecoration(labelText: 'Walk-in customer name'),
              ),
            if (isCredit) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _creditDueDate == null
                    ? TextButton.icon(
                        onPressed: _pickCreditDueDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: const Text('Add a due date (optional)'),
                      )
                    : InputChip(
                        avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(
                          'Due: ${_creditDueDate!.toLocal()}'.split(' ').first,
                        ),
                        onDeleted: () => setState(() => _creditDueDate = null),
                      ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialPaymentController,
                decoration: const InputDecoration(
                  labelText: 'Initial payment (optional)',
                  helperText:
                      'Leave empty if nothing was paid yet — the full amount stays owed.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
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
                  : const Text('Create Sale'),
            ),
          ],
        ),
      ),
    );
  }
}