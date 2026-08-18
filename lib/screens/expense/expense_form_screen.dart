import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/business_category_model.dart';
import '../../models/expense_model.dart';
import '../../providers/business_category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../repositories/expense_repository.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Local, non-persistent shape for one category row being edited in the
/// form — deliberately distinct from ExpenseCategorySplitModel (no id)
/// and from ExpenseCategoryAllocation (that one is the repository's
/// input shape; this one also carries nothing UI shouldn't own).
class _AllocationRow {
  const _AllocationRow({
    required this.businessCategoryId,
    required this.amountCents,
  });

  final int businessCategoryId;
  final int amountCents;
}

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

  final List<_AllocationRow> _allocations = [];
  int? _supplierId;
  late DateTime _expenseDate;
  bool _prefillingAllocations = false;

  bool get _isEditing => widget.expense != null;

  int get _allocatedTotalCents =>
      _allocations.fold(0, (sum, row) => sum + row.amountCents);

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
    // Only used to refresh the "allocated vs total" comparison as the
    // user types the expense amount.
    _amountController.addListener(() => setState(() {}));
    _supplierId = widget.expense?.supplierId;
    _expenseDate = widget.expense?.expenseDate ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<BusinessCategoryProvider>().loadCategories();
      if (!_isEditing) return;

      setState(() => _prefillingAllocations = true);
      final splits = await context
          .read<ExpenseProvider>()
          .getSplitsByExpense(widget.expense!.idExpense!);
      if (!mounted) return;
      setState(() {
        _allocations
          ..clear()
          ..addAll(splits.map((s) => _AllocationRow(
                businessCategoryId: s.businessCategoryId,
                amountCents: s.amountCents,
              )));
        _prefillingAllocations = false;
      });
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

  Future<void> _openAllocationDialog({
    _AllocationRow? existing,
    int? editIndex,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final categories = context.read<BusinessCategoryProvider>().categories;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCategoriesAvailableYet)),
      );
      return;
    }

    final excludedIds = _allocations
        .asMap()
        .entries
        .where((e) => e.key != editIndex)
        .map((e) => e.value.businessCategoryId)
        .toSet();

    // Suggest the remaining un-allocated amount so the single-category
    // case is a two-tap flow: open dialog, pick category, confirm.
    final totalCents = _parsedAmountCents ?? 0;
    final alreadyAllocated =
        existing != null ? _allocatedTotalCents - existing.amountCents : _allocatedTotalCents;
    final remainingCents = totalCents - alreadyAllocated;

    final result = await showDialog<_AllocationRow>(
      context: context,
      builder: (_) => _CategoryAllocationDialog(
        categories: categories,
        excludedCategoryIds: excludedIds,
        initialCategoryId: existing?.businessCategoryId,
        initialAmountCents:
            existing?.amountCents ?? (remainingCents > 0 ? remainingCents : null),
      ),
    );

    if (result == null) return;
    setState(() {
      if (editIndex != null) {
        _allocations[editIndex] = result;
      } else {
        _allocations.add(result);
      }
    });
  }

  void _removeAllocation(int index) {
    setState(() => _allocations.removeAt(index));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_allocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneCategory)),
      );
      return;
    }

    final amountCents = _parsedAmountCents;
    if (amountCents == null) return;

    // Client-side guard so the user sees the mismatch before submitting,
    // not just after the repository throws.
    if (_allocatedTotalCents != amountCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.categoryAllocationsMismatch(
              (_allocatedTotalCents / 100).toStringAsFixed(2),
              (amountCents / 100).toStringAsFixed(2),
            ),
          ),
        ),
      );
      return;
    }

    final allocations = _allocations
        .map((row) => ExpenseCategoryAllocation(
              businessCategoryId: row.businessCategoryId,
              amountCents: row.amountCents,
            ))
        .toList();

    final expenseProvider = context.read<ExpenseProvider>();
    final success = _isEditing
        ? await expenseProvider.updateExpense(
            idExpense: widget.expense!.idExpense!,
            categoryAllocations: allocations,
            supplierId: _supplierId,
            description: _descriptionController.text,
            amountCents: amountCents,
            expenseDate: _expenseDate,
          )
        : await expenseProvider.createExpense(
            categoryAllocations: allocations,
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
    final businessCategoryProvider = context.watch<BusinessCategoryProvider>();
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final amountCents = _parsedAmountCents;
    final allocatedCents = _allocatedTotalCents;
    final isBalanced = amountCents != null && allocatedCents == amountCents;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.categoriesLabel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        _prefillingAllocations ? null : () => _openAllocationDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addCategoryButton),
                  ),
                ],
              ),
              if (_prefillingAllocations)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_allocations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.noCategoryAddedYet,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < _allocations.length; i++)
                        _AllocationTile(
                          row: _allocations[i],
                          categoryName: businessCategoryProvider.categories
                              .firstWhere(
                                (c) =>
                                    c.idBusinessCategory ==
                                    _allocations[i].businessCategoryId,
                                orElse: () => businessCategoryProvider.categories.first,
                              )
                              .name,
                          onTap: () =>
                              _openAllocationDialog(existing: _allocations[i], editIndex: i),
                          onDelete: () => _removeAllocation(i),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.allocatedAmountLabel((allocatedCents / 100).toStringAsFixed(2)),
                    style: TextStyle(
                      fontSize: 13,
                      color: isBalanced ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                  if (amountCents != null)
                    Text(
                      l10n.totalAmountValueLabel((amountCents / 100).toStringAsFixed(2)),
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                ],
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

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({
    required this.row,
    required this.categoryName,
    required this.onTap,
    required this.onDelete,
  });

  final _AllocationRow row;
  final String categoryName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(categoryName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((row.amountCents / 100).toStringAsFixed(2)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Modal used both to add a new category allocation and to edit an
/// existing one (in which case its own category stays selectable even
/// though it's technically "already allocated").
class _CategoryAllocationDialog extends StatefulWidget {
  const _CategoryAllocationDialog({
    required this.categories,
    required this.excludedCategoryIds,
    this.initialCategoryId,
    this.initialAmountCents,
  });

  final List<BusinessCategoryModel> categories;
  final Set<int> excludedCategoryIds;
  final int? initialCategoryId;
  final int? initialAmountCents;

  @override
  State<_CategoryAllocationDialog> createState() =>
      _CategoryAllocationDialogState();
}

class _CategoryAllocationDialogState extends State<_CategoryAllocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _amountController = TextEditingController(
      text: widget.initialAmountCents != null
          ? (widget.initialAmountCents! / 100).toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    final parsed = double.parse(_amountController.text.trim().replaceAll(',', '.'));
    Navigator.pop(
      context,
      _AllocationRow(
        businessCategoryId: _categoryId!,
        amountCents: (parsed * 100).round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final availableCategories = widget.categories
        .where((c) =>
            !widget.excludedCategoryIds.contains(c.idBusinessCategory) ||
            c.idBusinessCategory == widget.initialCategoryId)
        .toList();

    return AlertDialog(
      title: Text(l10n.categoryAllocationDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: l10n.categoryLabel),
              items: availableCategories
                  .map((c) =>
                      DropdownMenuItem(value: c.idBusinessCategory, child: Text(c.name)))
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
              validator: (value) => value == null ? l10n.selectCategoryValidation : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: l10n.amountFieldLabel),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return l10n.amountRequired;
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return l10n.enterValidAmount;
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(onPressed: _confirm, child: Text(l10n.saveLabel)),
      ],
    );
  }
}