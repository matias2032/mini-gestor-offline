import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

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

  int? _supplierId;
  late DateTime _expenseDate;

  bool get _isEditing => widget.expense != null;

  int? get _parsedAmountCents {
    final parsed =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.expense?.description);
    _amountController = TextEditingController(
      text: widget.expense != null
          ? (widget.expense!.amountCents / 100).toStringAsFixed(2)
          : '',
    );
    _supplierId = widget.expense?.supplierId;
    _expenseDate = widget.expense?.expenseDate ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
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

    final amountCents = _parsedAmountCents;
    if (amountCents == null) return;

    final expenseProvider = context.read<ExpenseProvider>();
    final success = _isEditing
        ? await expenseProvider.updateExpense(
            idExpense: widget.expense!.idExpense!,
            supplierId: _supplierId,
            description: _descriptionController.text,
            amountCents: amountCents,
            expenseDate: _expenseDate,
          )
        : await expenseProvider.createExpense(
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editExpense : l10n.newExpense)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: l10n.descriptionLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.descriptionRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: l10n.amountLabel),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.amountRequired;
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) return l10n.invalidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int?>(
                initialValue: _supplierId,
                decoration: InputDecoration(labelText: l10n.supplierOptionalLabel),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(l10n.noneLabel)),
                  ...suppliers.map(
                    (s) => DropdownMenuItem<int?>(value: s.idSupplier, child: Text(s.name)),
                  ),
                ],
                onChanged: (value) => setState(() => _supplierId = value),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text(l10n.dateLabel(dateFormat.format(_expenseDate))),
              ),
              const SizedBox(height: 20),
              if (expenseProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    expenseProvider.errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ElevatedButton(
                onPressed: expenseProvider.isLoading ? null : _submit,
                child: expenseProvider.isLoading
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? l10n.saveChanges : l10n.createExpense),
              ),
            ],
          ),
        ),
      ),
    );
  }
}