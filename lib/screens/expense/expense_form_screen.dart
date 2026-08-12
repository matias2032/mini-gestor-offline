import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final ExpenseModel? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  int? _categoryId;
  int? _supplierId;
  late DateTime _expenseDate;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.expense?.description);
    _amountController = TextEditingController(
      text: widget.expense != null ? (widget.expense!.amountCents / 100).toStringAsFixed(2) : '',
    );
    _categoryId = widget.expense?.expenseCategoryId;
    _supplierId = widget.expense?.supplierId;
    _expenseDate = widget.expense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    final amountCents = (double.parse(_amountController.text.replaceAll(',', '.')) * 100).round();

    final expenseProvider = context.read<ExpenseProvider>();
    final success = _isEditing
        ? await expenseProvider.updateExpense(
            idExpense: widget.expense!.idExpense!,
            expenseCategoryId: _categoryId!,
            supplierId: _supplierId,
            description: _descriptionController.text,
            amountCents: amountCents,
            expenseDate: _expenseDate,
          )
        : await expenseProvider.createExpense(
            expenseCategoryId: _categoryId!,
            supplierId: _supplierId,
            description: _descriptionController.text,
            amountCents: amountCents,
            expenseDate: _expenseDate,
          );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit expense' : 'New expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (MZN)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Amount is required';
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: expenseProvider.categories
                    .map((c) => DropdownMenuItem(value: c.idExpenseCategory, child: Text(c.name)))
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _supplierId,
                decoration: const InputDecoration(labelText: 'Supplier (optional)'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('None')),
                  ...suppliers.map(
                    (s) => DropdownMenuItem<int?>(value: s.idSupplier, child: Text(s.name)),
                  ),
                ],
                onChanged: (value) => setState(() => _supplierId = value),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text('Date: ${dateFormat.format(_expenseDate)}'),
              ),
              const SizedBox(height: 20),
              if (expenseProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(expenseProvider.errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: expenseProvider.isLoading ? null : _submit,
                child: expenseProvider.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Save' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}