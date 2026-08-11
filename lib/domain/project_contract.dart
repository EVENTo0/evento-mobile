class ProjectContractVersionRecord {
  const ProjectContractVersionRecord({
    required this.id,
    required this.contractCode,
    required this.requestId,
    required this.quoteId,
    required this.versionNumber,
    required this.status,
    required this.termsVersion,
    required this.statementOfWork,
    required this.deliverables,
    required this.acceptanceCriteria,
    required this.renderedTermsAr,
    required this.renderedTermsEn,
    required this.legalReviewStatus,
    required this.validUntil,
    required this.acceptedAt,
  });

  factory ProjectContractVersionRecord.fromJson(Map<String, dynamic> json) =>
      ProjectContractVersionRecord(
        id: json['id'] as String,
        contractCode: json['contract_code'] as String? ?? '',
        requestId: json['request_id'] as String,
        quoteId: json['quote_id'] as String,
        versionNumber: json['version_number'] as int? ?? 1,
        status: json['status'] as String? ?? 'draft',
        termsVersion: json['terms_version'] as String? ?? '',
        statementOfWork: _stringList(json['statement_of_work']),
        deliverables: _stringList(json['deliverables']),
        acceptanceCriteria: _stringList(json['acceptance_criteria']),
        renderedTermsAr: json['rendered_terms_ar'] as String? ?? '',
        renderedTermsEn: json['rendered_terms_en'] as String?,
        legalReviewStatus: json['legal_review_status'] as String? ?? 'required',
        validUntil: json['valid_until'] == null
            ? null
            : DateTime.parse(json['valid_until'] as String),
        acceptedAt: json['accepted_at'] == null
            ? null
            : DateTime.parse(json['accepted_at'] as String),
      );

  final String id;
  final String contractCode;
  final String requestId;
  final String quoteId;
  final int versionNumber;
  final String status;
  final String termsVersion;
  final List<String> statementOfWork;
  final List<String> deliverables;
  final List<String> acceptanceCriteria;
  final String renderedTermsAr;
  final String? renderedTermsEn;
  final String legalReviewStatus;
  final DateTime? validUntil;
  final DateTime? acceptedAt;

  bool get isAcceptable =>
      status == 'sent' &&
      legalReviewStatus == 'approved_for_use' &&
      (validUntil == null || validUntil!.isAfter(DateTime.now()));

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
