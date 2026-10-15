import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:mini/l10n/app_localizations.dart';

import '../../repositories/financial_statement_repository.dart';
import '../../services/financial_statement_pdf_service.dart';

class FinancialStatementPdfPreviewScreen extends StatelessWidget {
  const FinancialStatementPdfPreviewScreen({
    super.key,
    required this.detail,
    required this.currency,
    this.businessName,
  });

  final FinancialStatementDetail detail;
  final String currency;
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reference = detail.statement.reference;

    return Scaffold(
      appBar: AppBar(title: Text(reference)),
      body: PdfPreview(
        build: (_) => FinancialStatementPdfService().build(
          detail: detail,
          l10n: l10n,
          currency: currency,
          businessName: businessName,
        ),
        pdfFileName: '$reference.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}