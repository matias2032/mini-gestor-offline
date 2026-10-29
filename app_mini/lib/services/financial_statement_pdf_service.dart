import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/financial_statement_model.dart';
import '../repositories/financial_statement_repository.dart';
import 'package:mini/l10n/app_localizations.dart';
import '../../core/statement_period_l10n.dart';


/* Builds the PDF for a financial statement from its frozen snapshot
(FinancialStatementDetail). Pure rendering: no database access, no
business rules. */
class FinancialStatementPdfService {
  static const _green = PdfColors.green800;
  static const _red = PdfColors.red800;
  static const _grey = PdfColors.grey700;

  Future<Uint8List> build({
    required FinancialStatementDetail detail,
    required AppLocalizations l10n,
    required String currency,
    String? businessName,
  }) async {
    final statement = detail.statement;
    final amountFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd/MM/yyyy');
    String money(int cents) => '${amountFormat.format(cents / 100)} $currency';

    final doc = pw.Document(
      title: statement.reference,
      author: businessName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _grey),
          ),
        ),
        build: (context) => [
          // Header
          if (businessName != null && businessName.isNotEmpty)
            pw.Text(businessName,
                style: pw.TextStyle(fontSize: 12, color: _grey)),
          pw.Text(
            statement.reference,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${statement.periodType.localizedLabel(l10n)}  |  '
            '${dateFormat.format(statement.startDate.toLocal())} - '
            '${dateFormat.format(statement.endDate.toLocal())}',
            style: const pw.TextStyle(fontSize: 11, color: _grey),
          ),
          pw.Divider(height: 24),

          // Summary
          _summaryRow(l10n.salesCountLabel(statement.salesCount),
              money(statement.totalSalesCents), _green),
          pw.SizedBox(height: 4),
          _summaryRow(l10n.expensesCountLabel(statement.expensesCount),
              money(statement.totalExpensesCents), _red),
          pw.Divider(height: 16),
          _summaryRow(
            l10n.balanceLabel,
            money(statement.balanceCents),
            statement.balanceCents >= 0 ? _green : _red,
            bold: true,
          ),
          if (statement.notes != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(statement.notes!,
                style: pw.TextStyle(
                    fontSize: 10, fontStyle: pw.FontStyle.italic)),
          ],

          // Sales
          pw.SizedBox(height: 24),
          _sectionTitle(l10n.salesSectionTitle),
          if (detail.saleItems.isEmpty)
            pw.Text(l10n.noSalesInPeriod)
          else
            _table(
              headers: [
                l10n.referenceColumnLabel,
                l10n.dateColumnLabel,
                l10n.customerLabel,
                l10n.descriptionLabel,
                l10n.amountFieldLabel,
              ],
              rightAlignedFrom: 4,
              rows: [
                for (final item in detail.saleItems)
                  [
                    item.saleReference,
                    dateFormat.format(item.saleDate.toLocal()),
                    item.customerName ?? l10n.noCustomerLabel,
                    item.saleDescription,
                    money(item.amountCents),
                  ],
              ],
            ),

          // Expenses
          pw.SizedBox(height: 24),
          _sectionTitle(l10n.expensesSectionTitle),
          if (detail.expenseItems.isEmpty)
            pw.Text(l10n.noExpensesInPeriod)
          else
            _table(
              headers: [
                l10n.dateColumnLabel,
                l10n.descriptionLabel,
                l10n.amountFieldLabel,
              ],
              rightAlignedFrom: 2,
              rows: [
                for (final item in detail.expenseItems)
                  [
                    dateFormat.format(item.expenseDate.toLocal()),
                    item.expenseDescription,
                    money(item.amountCents),
                  ],
              ],
            ),

          // Per-store breakdown (consolidated statements only)
          if (statement.isConsolidated && detail.storeBreakdown.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _sectionTitle(l10n.perStoreBreakdownTitle),
            _table(
              headers: [
                l10n.storeColumnLabel,
                l10n.salesSectionTitle,
                l10n.expensesSectionTitle,
                l10n.balanceLabel,
              ],
              rightAlignedFrom: 1,
              rows: [
                for (final store in detail.storeBreakdown)
                  [
                    store.businessUnitName,
                    money(store.totalSalesCents),
                    money(store.totalExpensesCents),
                    money(store.balanceCents),
                  ],
              ],
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _summaryRow(String label, String value, PdfColor color,
      {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 14 : 12,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style.copyWith(color: color)),
      ],
    );
  }

  /* Columns from rightAlignedFrom onwards are right-aligned (amounts). */
  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required int rightAlignedFrom,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
      cellAlignments: {
        for (var i = 0; i < headers.length; i++)
          i: i >= rightAlignedFrom
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
      },
    );
  }
}