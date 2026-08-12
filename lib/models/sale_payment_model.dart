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