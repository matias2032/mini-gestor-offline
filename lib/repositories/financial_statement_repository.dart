import '../core/database/local_database.dart';
import '../daos/financial_statement_dao.dart';
import '../models/financial_statement_model.dart';
import 'package:sqflite/sqflite.dart';

/// All business logic for generating and reading financial statements
/// ("extractos"). Screens and providers must never talk to
/// FinancialStatementDao directly.
///
/// A statement is a snapshot: once generated, its sale/expense items and
/// totals are frozen in their own tables and never recomputed, even if
/// the underlying sale/expense rows change afterwards.
class FinancialStatementRepository {
  FinancialStatementRepository(this._database, this._dao);

  final LocalDatabase _database;
  final FinancialStatementDao _dao;

  /// Generates a new statement for [periodType].
  ///
  /// For every period except [StatementPeriodType.custom], the date range
  /// is derived from "now". For custom, [customStartDate]/[customEndDate]
  /// are required.
  Future<FinancialStatementModel> generateStatement({
    required StatementPeriodType periodType,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? notes,
  }) async {
    final now = DateTime.now();

    late final DateTime startDate;
    late final DateTime endDate;

    if (periodType == StatementPeriodType.custom) {
      if (customStartDate == null || customEndDate == null) {
        throw ArgumentError(
          'A custom statement requires both a start and an end date.',
        );
      }
      if (customEndDate.isBefore(customStartDate)) {
        throw ArgumentError('End date cannot be before start date.');
      }
      startDate = customStartDate;
      endDate = customEndDate;
    } else {
      startDate = periodType.startDateFrom(now);
      endDate = now;
    }

    return _database.runInTransaction((txn) async {
      final saleRows = await _dao.getFinalizedSalesInPeriod(
        startDate: startDate,
        endDate: endDate,
        txn: txn,
      );
      final expenseRows = await _dao.getExpensesInPeriod(
        startDate: startDate,
        endDate: endDate,
        txn: txn,
      );

      final totalSalesCents = saleRows.fold<int>(
        0,
        (sum, row) => sum + (row['total_amount_cents'] as int),
      );
      final totalExpensesCents = expenseRows.fold<int>(
        0,
        (sum, row) => sum + (row['amount_cents'] as int),
      );

      final reference = await _generateStatementReference(txn);

      final statement = FinancialStatementModel(
        reference: reference,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        totalSalesCents: totalSalesCents,
        totalExpensesCents: totalExpensesCents,
        balanceCents: totalSalesCents - totalExpensesCents,
        salesCount: saleRows.length,
        expensesCount: expenseRows.length,
        notes: _cleanOrNull(notes),
        generatedAt: now,
        createdAt: now,
      );

      final statementId = await _dao.insertStatement(statement, txn: txn);

      final saleItems = saleRows
          .map((row) => FinancialStatementSaleItemModel(
                financialStatementId: statementId,
                saleId: row['id_sale'] as int,
                saleReference: row['reference'] as String,
                saleDescription: row['description'] as String,
                saleDate: DateTime.parse(row['sale_date'] as String),
                amountCents: row['total_amount_cents'] as int,
              ))
          .toList();
      if (saleItems.isNotEmpty) {
        await _dao.insertSaleItems(saleItems, txn: txn);
      }

      final expenseItems = expenseRows
          .map((row) => FinancialStatementExpenseItemModel(
                financialStatementId: statementId,
                expenseId: row['id_expense'] as int,
                expenseDescription: row['description'] as String,
                expenseDate: DateTime.parse(row['expense_date'] as String),
                amountCents: row['amount_cents'] as int,
              ))
          .toList();
      if (expenseItems.isNotEmpty) {
        await _dao.insertExpenseItems(expenseItems, txn: txn);
      }

      return statement.copyWith(idFinancialStatement: statementId);
    });
  }

  Future<FinancialStatementModel?> getStatementById(int idFinancialStatement) {
    return _dao.getStatementById(idFinancialStatement);
  }

  Future<List<FinancialStatementModel>> getAllStatements({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dao.getAllStatements(startDate: startDate, endDate: endDate);
  }

  Future<void> deleteStatement(int idFinancialStatement) {
    return _dao.softDeleteStatement(idFinancialStatement);
  }

  /// Full detail for a single statement: header + both snapshot lists.
  /// Backs both the statement detail screen and the PDF generator.
  Future<FinancialStatementDetail> getStatementDetail(
    int idFinancialStatement,
  ) async {
    final statement = await _dao.getStatementById(idFinancialStatement);
    if (statement == null) {
      throw StateError('Financial statement not found.');
    }
    final saleItems = await _dao.getSaleItemsByStatement(idFinancialStatement);
    final expenseItems =
        await _dao.getExpenseItemsByStatement(idFinancialStatement);

    return FinancialStatementDetail(
      statement: statement,
      saleItems: saleItems,
      expenseItems: expenseItems,
    );
  }

Future<String> _generateStatementReference(Transaction txn) async {
    final count = await _dao.countAll(txn: txn);
    return 'EXT-${(count + 1).toString().padLeft(5, '0')}';
  }

  String? _cleanOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Aggregate returned by [FinancialStatementRepository.getStatementDetail] —
/// everything the detail screen and the PDF service need in one call.
class FinancialStatementDetail {
  const FinancialStatementDetail({
    required this.statement,
    required this.saleItems,
    required this.expenseItems,
  });

  final FinancialStatementModel statement;
  final List<FinancialStatementSaleItemModel> saleItems;
  final List<FinancialStatementExpenseItemModel> expenseItems;
}