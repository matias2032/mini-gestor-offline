// screens/sale/sale_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import '../../repositories/sale_repository.dart' show InstallmentInput;

class _InstallmentDraft {
  _InstallmentDraft(this.number)
      : amountController = TextEditingController();

  final int number;
  final TextEditingController amountController;
  DateTime? dueDate;

  void dispose() => amountController.dispose();
}

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
  final _notesController = TextEditingController();

  int? _saleCategoryId;
  String _saleType = 'NORMAL';
  bool _useExistingCustomer = true;
  int? _customerId;
  String _creditModality = 'SINGLE_PAYMENT';
  DateTime? _creditDueDate;
  final List<_InstallmentDraft> _installments = [];

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
    _notesController.dispose();
    for (final installment in _installments) {
      installment.dispose();
    }
    super.dispose();
  }

  int _toCents(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
    return (value * 100).round();
  }

  void _addInstallment() {
    setState(() {
      _installments.add(_InstallmentDraft(_installments.length + 1));
    });
  }

  void _removeInstallment(int index) {
    setState(() {
      _installments[index].dispose();
      _installments.removeAt(index);
      for (var i = 0; i < _installments.length; i++) {
        _installments[i] = _InstallmentDraft(i + 1)
          ..amountController.text = _installments[i].amountController.text
          ..dueDate = _installments[i].dueDate;
      }
    });
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

  Future<void> _pickInstallmentDueDate(_InstallmentDraft installment) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => installment.dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isCredit = _saleType == 'CREDIT';
    final totalCents = _toCents(_totalAmountController.text);

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
      if (_creditModality == 'SINGLE_PAYMENT' && _creditDueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a due date.')),
        );
        return;
      }
      if (_creditModality == 'INSTALLMENTS') {
        if (_installments.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add at least one installment.')),
          );
          return;
        }
        for (final installment in _installments) {
          if (installment.dueDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Set a due date for installment ${installment.number}.')),
            );
            return;
          }
        }
        final sum = _installments.fold<int>(
          0,
          (total, installment) => total + _toCents(installment.amountController.text),
        );
        if (sum != totalCents) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Installment amounts must add up to the sale total.'),
            ),
          );
          return;
        }
      }
    }

    final provider = context.read<SaleProvider>();
    final success = await provider.createSale(
      saleCategoryId: _saleCategoryId!,
      description: _descriptionController.text,
      totalAmountCents: totalCents,
      saleType: _saleType,
      creditModality: isCredit ? _creditModality : null,
      customerId: isCredit && _useExistingCustomer ? _customerId : null,
      walkInCustomerName:
          isCredit && !_useExistingCustomer ? _walkInNameController.text : null,
      creditDueDate: isCredit && _creditModality == 'SINGLE_PAYMENT'
          ? _creditDueDate
          : null,
      notes: _notesController.text,
      installments: isCredit && _creditModality == 'INSTALLMENTS'
          ? _installments
              .map((installment) => InstallmentInput(
                    installmentNumber: installment.number,
                    installmentAmountCents:
                        _toCents(installment.amountController.text),
                    dueDate: installment.dueDate!,
                  ))
              .toList()
          : const [],
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
            if (isCredit) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use existing customer'),
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
              else
                TextFormField(
                  controller: _walkInNameController,
                  decoration: const InputDecoration(labelText: 'Walk-in customer name'),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _creditModality,
                decoration: const InputDecoration(labelText: 'Credit modality'),
                items: const [
                  DropdownMenuItem(
                      value: 'SINGLE_PAYMENT', child: Text('Single payment')),
                  DropdownMenuItem(
                      value: 'INSTALLMENTS', child: Text('Installments')),
                ],
                onChanged: (value) => setState(() => _creditModality = value!),
              ),
              const SizedBox(height: 16),
              if (_creditModality == 'SINGLE_PAYMENT')
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _creditDueDate == null
                        ? 'Select due date'
                        : 'Due date: ${_creditDueDate!.toLocal()}'.split(' ').first,
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _pickCreditDueDate,
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Installments', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _addInstallment,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                for (var i = 0; i < _installments.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text('#${_installments[i].number}'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _installments[i].amountController,
                            decoration: const InputDecoration(labelText: 'Amount'),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _pickInstallmentDueDate(_installments[i]),
                          child: Text(
                            _installments[i].dueDate == null
                                ? 'Due date'
                                : '${_installments[i].dueDate!.toLocal()}'.split(' ').first,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeInstallment(i),
                        ),
                      ],
                    ),
                  ),
              ],
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
                  : const Text('Create Sale'),
            ),
          ],
        ),
      ),
    );
  }
}