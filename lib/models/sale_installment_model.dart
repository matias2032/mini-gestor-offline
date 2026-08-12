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