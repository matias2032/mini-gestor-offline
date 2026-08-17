import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/business_category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({super.key});

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  int? _categoryId;
  int? _supplierId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final expenseProvider = context.read<ExpenseProvider>();
      _categoryId = expenseProvider.filterBusinessCategoryId;
    _supplierId = expenseProvider.filterSupplierId;
    _startDate = expenseProvider.filterStartDate;
    _endDate = expenseProvider.filterEndDate;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _apply() async {
    await context.read<ExpenseProvider>().applyFilters(
      businessCategoryId: _categoryId,
      clearBusinessCategoryId: _categoryId == null,
      supplierId: _supplierId,
      clearSupplierId: _supplierId == null,
      startDate: _startDate,
      clearStartDate: _startDate == null,
      endDate: _endDate,
      clearEndDate: _endDate == null,
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    setState(() {
      _categoryId = null;
      _supplierId = null;
      _startDate = null;
      _endDate = null;
    });
    await context.read<ExpenseProvider>().clearFilters();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<BusinessCategoryProvider>().categories;
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
Text(
            l10n.filterExpensesTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            decoration: InputDecoration(labelText: l10n.categoryLabel),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l10n.allLabel)),
              ...categories.map(
                (c) => DropdownMenuItem<int?>(value: c.idBusinessCategory, child: Text(c.name)),
              ),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _supplierId,
            decoration: InputDecoration(labelText: l10n.supplierLabel),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(l10n.allLabel)),
              ...suppliers.map(
                (s) => DropdownMenuItem<int?>(value: s.idSupplier, child: Text(s.name)),
              ),
            ],
            onChanged: (value) => setState(() => _supplierId = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isStart: true),
                  child: Text(
                    _startDate == null ? l10n.startDateLabel : _startDate!.toIso8601String().split('T').first,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isStart: false),
                  child: Text(
                    _endDate == null ? l10n.endDateLabel : _endDate!.toIso8601String().split('T').first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: _clear, child: Text(l10n.clearLabel)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(onPressed: _apply, child: Text(l10n.applyLabel)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}