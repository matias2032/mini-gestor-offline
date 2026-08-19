// screens/sale/financial_statement_generate_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/financial_statement_model.dart';
import '../../providers/business_unit_provider.dart';
import '../../providers/financial_statement_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

class FinancialStatementGenerateScreen extends StatefulWidget {
  const FinancialStatementGenerateScreen({super.key});

  @override
  State<FinancialStatementGenerateScreen> createState() =>
      _FinancialStatementGenerateScreenState();
}

class _FinancialStatementGenerateScreenState
    extends State<FinancialStatementGenerateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  StatementPeriodType _periodType = StatementPeriodType.oneMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _consolidated = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _customStartDate = picked);
  }

  Future<void> _pickCustomEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customEndDate ?? DateTime.now(),
      firstDate: _customStartDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _customEndDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final isCustom = _periodType == StatementPeriodType.custom;
    if (isCustom) {
      if (_customStartDate == null || _customEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.selectBothDatesMessage)),
        );
        return;
      }
      if (_customEndDate!.isBefore(_customStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.endDateBeforeStartDateMessage)),
        );
        return;
      }
    }

    final provider = context.read<FinancialStatementProvider>();
    final statement = await provider.generateStatement(
      periodType: _periodType,
      customStartDate: isCustom ? _customStartDate : null,
      customEndDate: isCustom ? _customEndDate : null,
      notes: _notesController.text,
      consolidated: _consolidated,
    );

    if (statement != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorMessage = context.watch<FinancialStatementProvider>().errorMessage;
    final isGenerating = context.watch<FinancialStatementProvider>().isGenerating;
    final hasMultipleUnits = context.watch<BusinessUnitProvider>().hasMultipleUnits;
    final isCustom = _periodType == StatementPeriodType.custom;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.generateStatementTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DropdownButtonFormField<StatementPeriodType>(
              value: _periodType,
              decoration: InputDecoration(labelText: l10n.periodLabel),
              items: StatementPeriodType.values
                  .map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _periodType = value);
              },
            ),
            if (isCustom) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: _customStartDate == null
                    ? TextButton.icon(
                        onPressed: _pickCustomStartDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(l10n.selectStartDate),
                      )
                    : InputChip(
                        avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(
                          l10n.startDatePrefix(
                            '${_customStartDate!.toLocal()}'.split(' ').first,
                          ),
                        ),
                        onDeleted: () => setState(() => _customStartDate = null),
                      ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _customEndDate == null
                    ? TextButton.icon(
                        onPressed: _pickCustomEndDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(l10n.selectEndDate),
                      )
                    : InputChip(
                        avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(
                          l10n.endDatePrefix(
                            '${_customEndDate!.toLocal()}'.split(' ').first,
                          ),
                        ),
                        onDeleted: () => setState(() => _customEndDate = null),
                      ),
              ),
            ],
            if (hasMultipleUnits) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.consolidatedStatementLabel),
                subtitle: Text(l10n.consolidatedStatementDescription),
                value: _consolidated,
                onChanged: (value) => setState(() => _consolidated = value),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.notesOptionalLabel),
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
              onPressed: isGenerating ? null : _submit,
              child: isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.generateButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}