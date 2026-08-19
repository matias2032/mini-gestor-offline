// sale_model.dart

// ============================================================
// sale
// ============================================================

/// Pure data class representing a row in the `sale` table.
///
/// `updated_at` is omitted from [toMap] because `trg_sale_updated` sets it
/// automatically on UPDATE — same pattern as `expense`.
///
/// `businessUnitId` is strict scope (matches `sale.business_unit_id
/// NOT NULL` in the schema): every sale belongs to exactly one loja.
class SaleModel {
  const SaleModel({
    this.idSale,
    required this.reference,
    required this.description,
    required this.totalAmountCents,
    this.saleType = 'NORMAL',
    this.creditModality,
    this.saleStatus = 'COMPLETED',
    this.paymentStatus = 'PAID',
    this.paidAmountCents = 0,
    this.customerId,
    this.walkInCustomerName,
    required this.saleDate,
    this.creditDueDate,
    this.completedAt,
    this.notes,
    this.cancellationReason,
    this.deleted = false,
    required this.createdAt,
    this.updatedAt,
    required this.businessUnitId,
  });

  final int? idSale;
  final String reference;
  final String description;
  final int totalAmountCents;
  final String saleType; // 'NORMAL' | 'CREDIT'
  final String? creditModality; // 'SINGLE_PAYMENT' | 'INSTALLMENTS'
  final String saleStatus; // 'OPEN' | 'OUTSTANDING' | 'COMPLETED' | 'CANCELLED'
  final String paymentStatus; // 'PENDING' | 'PARTIAL' | 'PAID'
  final int paidAmountCents;
  final int? customerId;
  final String? walkInCustomerName;
  final DateTime saleDate;
  final DateTime? creditDueDate;
  final DateTime? completedAt;
  final String? notes;
  final String? cancellationReason;
  final bool deleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// The business unit (loja/departamento) this sale was posted to.
  /// Strict scope — always required, never Global.
  final int businessUnitId;

  bool get isCredit => saleType == 'CREDIT';

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      idSale: map['id_sale'] as int?,
      reference: map['reference'] as String,
      description: map['description'] as String,
      totalAmountCents: map['total_amount_cents'] as int,
      saleType: map['sale_type'] as String,
      creditModality: map['credit_modality'] as String?,
      saleStatus: map['sale_status'] as String,
      paymentStatus: map['payment_status'] as String,
      paidAmountCents: map['paid_amount_cents'] as int,
      customerId: map['customer_id'] as int?,
      walkInCustomerName: map['walk_in_customer_name'] as String?,
      saleDate: DateTime.parse(map['sale_date'] as String),
      creditDueDate: map['credit_due_date'] != null
          ? DateTime.parse(map['credit_due_date'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      notes: map['notes'] as String?,
      cancellationReason: map['cancellation_reason'] as String?,
      deleted: (map['deleted'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      businessUnitId: map['business_unit_id'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idSale != null) 'id_sale': idSale,
      'reference': reference,
      'description': description,
      'total_amount_cents': totalAmountCents,
      'sale_type': saleType,
      'credit_modality': creditModality,
      'sale_status': saleStatus,
      'payment_status': paymentStatus,
      'paid_amount_cents': paidAmountCents,
      'customer_id': customerId,
      'walk_in_customer_name': walkInCustomerName,
      'sale_date': saleDate.toIso8601String(),
      'credit_due_date': creditDueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'deleted': deleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      // updated_at is set automatically by trg_sale_updated on UPDATE.
      'business_unit_id': businessUnitId,
    };
  }

  SaleModel copyWith({
    int? idSale,
    String? reference,
    String? description,
    int? totalAmountCents,
    String? saleType,
    String? creditModality,
    bool clearCreditModality = false,
    String? saleStatus,
    String? paymentStatus,
    int? paidAmountCents,
    int? customerId,
    bool clearCustomerId = false,
    String? walkInCustomerName,
    bool clearWalkInCustomerName = false,
    DateTime? saleDate,
    DateTime? creditDueDate,
    bool clearCreditDueDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? notes,
    String? cancellationReason,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? businessUnitId,
  }) {
    return SaleModel(
      idSale: idSale ?? this.idSale,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      saleType: saleType ?? this.saleType,
      creditModality:
          clearCreditModality ? null : (creditModality ?? this.creditModality),
      saleStatus: saleStatus ?? this.saleStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      walkInCustomerName: clearWalkInCustomerName
          ? null
          : (walkInCustomerName ?? this.walkInCustomerName),
      saleDate: saleDate ?? this.saleDate,
      creditDueDate:
          clearCreditDueDate ? null : (creditDueDate ?? this.creditDueDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessUnitId: businessUnitId ?? this.businessUnitId,
    );
  }
}

// ============================================================
// sale_installment
// ============================================================

class SaleInstallmentModel {
  const SaleInstallmentModel({
    this.idSaleInstallment,
    required this.saleId,
    required this.installmentNumber,
    required this.installmentAmountCents,
    this.paidAmountCents = 0,
    required this.dueDate,
    this.paidAt,
    this.installmentStatus = 'PENDING',
    this.cancelledBySaleCancellation = false,
    this.notes,
  });

  final int? idSaleInstallment;
  final int saleId;
  final int installmentNumber;
  final int installmentAmountCents;
  final int paidAmountCents;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String installmentStatus;
  final bool cancelledBySaleCancellation;
  final String? notes;

  int get remainingCents => installmentAmountCents - paidAmountCents;

  factory SaleInstallmentModel.fromMap(Map<String, Object?> map) {
    return SaleInstallmentModel(
      idSaleInstallment: map['id_sale_installment'] as int?,
      saleId: map['sale_id'] as int,
      installmentNumber: map['installment_number'] as int,
      installmentAmountCents: map['installment_amount_cents'] as int,
      paidAmountCents: map['paid_amount_cents'] as int,
      dueDate: DateTime.parse(map['due_date'] as String),
      paidAt: map['paid_at'] != null
          ? DateTime.parse(map['paid_at'] as String)
          : null,
      installmentStatus: map['installment_status'] as String,
      cancelledBySaleCancellation:
          (map['cancelled_by_sale_cancellation'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idSaleInstallment != null) 'id_sale_installment': idSaleInstallment,
      'sale_id': saleId,
      'installment_number': installmentNumber,
      'installment_amount_cents': installmentAmountCents,
      'paid_amount_cents': paidAmountCents,
      'due_date': dueDate.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'installment_status': installmentStatus,
      'cancelled_by_sale_cancellation': cancelledBySaleCancellation ? 1 : 0,
      'notes': notes,
    };
  }

  SaleInstallmentModel copyWith({
    int? idSaleInstallment,
    int? saleId,
    int? installmentNumber,
    int? installmentAmountCents,
    int? paidAmountCents,
    DateTime? dueDate,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? installmentStatus,
    bool? cancelledBySaleCancellation,
    String? notes,
  }) {
    return SaleInstallmentModel(
      idSaleInstallment: idSaleInstallment ?? this.idSaleInstallment,
      saleId: saleId ?? this.saleId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      installmentAmountCents:
          installmentAmountCents ?? this.installmentAmountCents,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      dueDate: dueDate ?? this.dueDate,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      installmentStatus: installmentStatus ?? this.installmentStatus,
      cancelledBySaleCancellation:
          cancelledBySaleCancellation ?? this.cancelledBySaleCancellation,
      notes: notes ?? this.notes,
    );
  }
}

// ============================================================
// sale_payment
// ============================================================

/// Pure data class representing a row in the `sale_payment` table.
class SalePaymentModel {
  const SalePaymentModel({
    this.idSalePayment,
    required this.reference,
    required this.saleId,
    this.installmentId,
    required this.paidAmountCents,
    this.paymentMethod = 'CASH',
    required this.paidAt,
    this.notes,
  });

  final int? idSalePayment;
  final String reference;
  final int saleId;
  final int? installmentId;
  final int paidAmountCents;
  final String paymentMethod; // CASH|BANK_TRANSFER|MPESA|EMOLA|OTHER
  final DateTime paidAt;
  final String? notes;

  factory SalePaymentModel.fromMap(Map<String, Object?> map) {
    return SalePaymentModel(
      idSalePayment: map['id_sale_payment'] as int?,
      reference: map['reference'] as String,
      saleId: map['sale_id'] as int,
      installmentId: map['installment_id'] as int?,
      paidAmountCents: map['paid_amount_cents'] as int,
      paymentMethod: map['payment_method'] as String,
      paidAt: DateTime.parse(map['paid_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (idSalePayment != null) 'id_sale_payment': idSalePayment,
      'reference': reference,
      'sale_id': saleId,
      'installment_id': installmentId,
      'paid_amount_cents': paidAmountCents,
      'payment_method': paymentMethod,
      'paid_at': paidAt.toIso8601String(),
      'notes': notes,
    };
  }

  SalePaymentModel copyWith({
    int? idSalePayment,
    String? reference,
    int? saleId,
    int? installmentId,
    int? paidAmountCents,
    String? paymentMethod,
    DateTime? paidAt,
    String? notes,
  }) {
    return SalePaymentModel(
      idSalePayment: idSalePayment ?? this.idSalePayment,
      reference: reference ?? this.reference,
      saleId: saleId ?? this.saleId,
      installmentId: installmentId ?? this.installmentId,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
    );
  }
}

// ============================================================
// dashboard support types
//
// CategorySalesSummary foi REMOVIDO — dependia de business_category
// (eliminada no Schema v4). DashboardStats foi reconstruído na FASE 5,
// agregado por loja (businessUnitId) em vez de por categoria.
// ============================================================

/// Aggregate stats for one business unit's dashboard, over a given
/// [DashboardPeriod]. Deliberately flat — no per-category breakdown,
/// since business_category no longer exists.
class DashboardStats {
  const DashboardStats({
    required this.businessUnitId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.finalizedSalesCount,
    required this.totalRevenueCents,
    required this.settledCreditSalesCount,
    required this.settledCreditRevenueCents,
  });

  final int businessUnitId;
  final DashboardPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  /// Every COMPLETED sale (NORMAL + CREDIT) in the period.
  final int finalizedSalesCount;

  /// Sum of total_amount_cents for every COMPLETED sale in the period.
  final int totalRevenueCents;

  /// COMPLETED CREDIT sales only — i.e. credit sales fully paid off
  /// within the period.
  final int settledCreditSalesCount;

  /// Sum of total_amount_cents for those settled CREDIT sales.
  final int settledCreditRevenueCents;
}

/// One store's slice of a [ConsolidatedDashboardStats] — how much that
/// loja contributed to the group total in the period.
class DashboardStoreBreakdown {
  const DashboardStoreBreakdown({
    required this.businessUnitId,
    required this.businessUnitName,
    required this.finalizedSalesCount,
    required this.totalRevenueCents,
  });

  final int businessUnitId;
  final String businessUnitName;
  final int finalizedSalesCount;
  final int totalRevenueCents;
}

/// Consolidated ("Super Dashboard") stats across every business unit,
/// for a given period. Same shape as [DashboardStats]' totals, plus a
/// per-loja breakdown so the UI can show each store's contribution —
/// mirrors the pattern FinancialStatementRepository.generateStatement
/// already uses for businessUnitId == null (loop every unit, merge).
class ConsolidatedDashboardStats {
  const ConsolidatedDashboardStats({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.finalizedSalesCount,
    required this.totalRevenueCents,
    required this.settledCreditSalesCount,
    required this.settledCreditRevenueCents,
    required this.perStore,
  });

  final DashboardPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final int finalizedSalesCount;
  final int totalRevenueCents;
  final int settledCreditSalesCount;
  final int settledCreditRevenueCents;

  /// Sorted by totalRevenueCents descending — biggest contributor first.
  final List<DashboardStoreBreakdown> perStore;
}

/// Period filter for the dashboard's aggregate stats.
enum DashboardPeriod { today, last24Hours, oneWeek, oneMonth, threeMonths, sixMonths, oneYear }

extension DashboardPeriodX on DashboardPeriod {
  /// Computes the inclusive start of the range, given "now".
  DateTime startDateFrom(DateTime now) {
    switch (this) {
      case DashboardPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case DashboardPeriod.last24Hours:
        return now.subtract(const Duration(hours: 24));
      case DashboardPeriod.oneWeek:
        return now.subtract(const Duration(days: 7));
      case DashboardPeriod.oneMonth:
        return now.subtract(const Duration(days: 30));
      case DashboardPeriod.threeMonths:
        return now.subtract(const Duration(days: 90));
      case DashboardPeriod.sixMonths:
        return now.subtract(const Duration(days: 180));
      case DashboardPeriod.oneYear:
        return now.subtract(const Duration(days: 365));
    }
  }

  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Today';
      case DashboardPeriod.last24Hours:
        return '1 day';
      case DashboardPeriod.oneWeek:
        return '1 week';
      case DashboardPeriod.oneMonth:
        return '1 month';
      case DashboardPeriod.threeMonths:
        return '3 months';
      case DashboardPeriod.sixMonths:
        return '6 months';
      case DashboardPeriod.oneYear:
        return '1 year';
    }
  }
}