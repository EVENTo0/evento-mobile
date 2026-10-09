class ProjectQuoteRecord {
  const ProjectQuoteRecord({
    required this.id,
    required this.quoteCode,
    required this.requestId,
    required this.status,
    required this.totalAed,
    this.validUntil,
  });

  factory ProjectQuoteRecord.fromJson(Map<String, dynamic> json) => ProjectQuoteRecord(
        id: json['id'] as String,
        quoteCode: json['quote_code'] as String,
        requestId: json['request_id'] as String,
        status: json['status'] as String,
        totalAed: _money(json['total_aed']),
        validUntil: json['valid_until'] == null
            ? null
            : DateTime.parse(json['valid_until'] as String),
      );

  final String id;
  final String quoteCode;
  final String requestId;
  final String status;
  final double totalAed;
  final DateTime? validUntil;
}

double _money(dynamic value) {
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}
