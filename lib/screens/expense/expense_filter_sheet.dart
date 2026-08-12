import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';

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
    _categoryId = expenseProvider.filterCategoryId;
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
      categoryId: _categoryId,
      clearCategoryId: _categoryId == null,
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
    final categories = context.watch<ExpenseProvider>().categories;
    final suppliers = context.watch<SupplierProvider>().suppliers;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Filter expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All')),
              ...categories.map(
                (c) => DropdownMenuItem<int?>(value: c.idExpenseCategory, child: Text(c.name)),
              ),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _supplierId,
            decoration: const InputDecoration(labelText: 'Supplier'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All')),
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
                    _startDate == null ? 'Start date' : _startDate!.toIso8601String().split('T').first,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isStart: false),
                  child: Text(
                    _endDate == null ? 'End date' : _endDate!.toIso8601String().split('T').first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: _clear, child: const Text('Clear')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(onPressed: _apply, child: const Text('Apply')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}