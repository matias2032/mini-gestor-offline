// financial_statement_repository.dart
import '../core/database/local_database.dart';
import '../daos/business_unit_dao.dart';
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
  FinancialStatementRepository(
    this._database,
    this._dao,
    this._businessUnitDao,
  );

  final LocalDatabase _database;
  final FinancialStatementDao _dao;
  final BusinessUnitDao _businessUnitDao;

  /// Generates a new statement for [periodType].
  ///
  /// [businessUnitId] scopes the statement to one loja. Omit it (leave
  /// null) to generate a consolidated statement for the whole
  /// matriz/grupo — the "Super Extracto": since `sale`/`expense` are
  /// strict scope, there is no single query that returns "every unit" —
  /// instead this loops every active business unit, pulls its finalized
  /// sales/expenses for the period, and merges the rows before
  /// aggregating totals.
  ///
  /// For every period except [StatementPeriodType.custom], the date range
  /// is derived from "now". For custom, [customStartDate]/[customEndDate]
  /// are required.
  Future<FinancialStatementModel> generateStatement({
    required StatementPeriodType periodType,
    int? businessUnitId,
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
      final unitIds = businessUnitId != null
          ? [businessUnitId]
          : (await _businessUnitDao.findAll(txn: txn))
              .map((u) => u.idBusinessUnit!)
              .toList();

      final saleRows = <Map<String, Object?>>[];
      final expenseRows = <Map<String, Object?>>[];
      for (final unitId in unitIds) {
        saleRows.addAll(await _dao.getFinalizedSalesInPeriod(
          businessUnitId: unitId,
          startDate: startDate,
          endDate: endDate,
          txn: txn,
        ));
        expenseRows.addAll(await _dao.getExpensesInPeriod(
          businessUnitId: unitId,
          startDate: startDate,
          endDate: endDate,
          txn: txn,
        ));
      }

      final totalSalesCents = saleRows.fold<int>(
        0,
        (sum, row) => sum + (row['total_amount_cents'] as int),
      );
      final totalExpensesCents = expenseRows.fold<int>(
        0,
        (sum, row) => sum + (row['amount_cents'] as int),
      );
      // With expense_category_split gone, each expense now contributes
      // exactly one row to expenseRows — a plain row count matches the
      // number of distinct expenses.
      final expensesCount = expenseRows.length;

      final reference = await _generateStatementReference(txn);

      final statement = FinancialStatementModel(
        reference: reference,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        businessUnitId: businessUnitId,
        totalSalesCents: totalSalesCents,
        totalExpensesCents: totalExpensesCents,
        balanceCents: totalSalesCents - totalExpensesCents,
        salesCount: saleRows.length,
        expensesCount: expensesCount,
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
    int? activeUnitId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dao.getAllStatements(
      activeUnitId: activeUnitId,
      startDate: startDate,
      endDate: endDate,
    );
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
    final storeBreakdown = statement.isConsolidated
        ? await getStoreBreakdown(idFinancialStatement)
        : const <FinancialStatementStoreBreakdown>[];

    return FinancialStatementDetail(
      statement: statement,
      saleItems: saleItems,
      expenseItems: expenseItems,
      storeBreakdown: storeBreakdown,
    );
  }

  /// Per-loja breakdown for a consolidated statement — how much each
  /// business unit contributed. Empty for a per-loja statement (nothing
  /// to break down).
  Future<List<FinancialStatementStoreBreakdown>> getStoreBreakdown(
    int idFinancialStatement,
  ) async {
    final statement = await _dao.getStatementById(idFinancialStatement);
    if (statement == null) {
      throw StateError('Financial statement not found.');
    }
    if (!statement.isConsolidated) return const [];

    final salesRows = await _dao.getSalesBreakdownByUnit(idFinancialStatement);
    final expenseRows = await _dao.getExpensesBreakdownByUnit(idFinancialStatement);
    final units = await _businessUnitDao.findAll();
    final unitNames = {for (final u in units) u.idBusinessUnit!: u.name};

    final salesByUnit = {
      for (final row in salesRows) row['business_unit_id'] as int: row,
    };
    final expensesByUnit = {
      for (final row in expenseRows) row['business_unit_id'] as int: row,
    };
    final unitIds = {...salesByUnit.keys, ...expensesByUnit.keys};

    final breakdown = unitIds.map((unitId) {
      final saleRow = salesByUnit[unitId];
      final expenseRow = expensesByUnit[unitId];
      return FinancialStatementStoreBreakdown(
        businessUnitId: unitId,
        businessUnitName: unitNames[unitId] ?? '—',
        totalSalesCents: saleRow != null ? saleRow['total_cents'] as int : 0,
        salesCount: saleRow != null ? saleRow['sales_count'] as int : 0,
        totalExpensesCents: expenseRow != null ? expenseRow['total_cents'] as int : 0,
        expensesCount: expenseRow != null ? expenseRow['expenses_count'] as int : 0,
      );
    }).toList();

    breakdown.sort((a, b) => b.totalSalesCents.compareTo(a.totalSalesCents));
    return breakdown;
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
///
/// No more `categoryBreakdown` here — business_category was dropped in
/// Schema v4. The Super Extracto's "diferença/soma das vendas de cada
/// loja" (per-loja breakdown) is a different, business-unit-based
/// aggregation and will be built in FASE 5 as part of the new dashboard
/// module.
class FinancialStatementDetail {
  const FinancialStatementDetail({
    required this.statement,
    required this.saleItems,
    required this.expenseItems,
    required this.storeBreakdown,
  });

  final FinancialStatementModel statement;
  final List<FinancialStatementSaleItemModel> saleItems;
  final List<FinancialStatementExpenseItemModel> expenseItems;

  /// Per-loja breakdown — non-empty only when statement.isConsolidated.
  final List<FinancialStatementStoreBreakdown> storeBreakdown;
}