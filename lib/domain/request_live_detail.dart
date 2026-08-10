class RequestAnalysisRecord {
  const RequestAnalysisRecord({
    required this.complexity,
    required this.summary,
    required this.summaryAr,
    required this.proposedScope,
    required this.proposedScopeAr,
    required this.risks,
    required this.risksAr,
    required this.engineVersion,
    required this.updatedAt,
  });

  factory RequestAnalysisRecord.fromJson(Map<String, dynamic> json) => RequestAnalysisRecord(
        complexity: json['complexity'] as String,
        summary: json['summary'] as String? ?? '',
        summaryAr: json['summary_ar'] as String?,
        proposedScope: (json['proposed_scope'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        proposedScopeAr: (json['proposed_scope_ar'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        risks: (json['risks'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        risksAr: (json['risks_ar'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        engineVersion: json['engine_version'] as String? ?? 'unknown',
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  final String complexity;
  final String summary;
  final String? summaryAr;
  final List<String> proposedScope;
  final List<String> proposedScopeAr;
  final List<String> risks;
  final List<String> risksAr;
  final String engineVersion;
  final DateTime updatedAt;

  String localizedSummary(bool arabic) =>
      arabic && (summaryAr?.trim().isNotEmpty ?? false) ? summaryAr! : summary;

  List<String> localizedScope(bool arabic) =>
      arabic && proposedScopeAr.isNotEmpty ? proposedScopeAr : proposedScope;

  List<String> localizedRisks(bool arabic) =>
      arabic && risksAr.isNotEmpty ? risksAr : risks;

  bool get isRc5OrNewer => engineVersion.contains('v1.0-rc5');
}

class RequestEventRecord {
  const RequestEventRecord({
    required this.status,
    required this.note,
    required this.noteAr,
    required this.createdAt,
  });

  factory RequestEventRecord.fromJson(Map<String, dynamic> json) => RequestEventRecord(
        status: json['status'] as String,
        note: json['note'] as String? ?? '',
        noteAr: json['note_ar'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String status;
  final String note;
  final String? noteAr;
  final DateTime createdAt;

  String localizedNote(bool arabic) =>
      arabic && (noteAr?.trim().isNotEmpty ?? false) ? noteAr! : note;

  String localizedStatus(bool arabic) {
    if (!arabic) {
      switch (status) {
        case 'draft':
          return 'Draft';
        case 'analyzed':
          return 'Analyzed';
        case 'awaiting_scope':
          return 'Awaiting scope';
        default:
          return status;
      }
    }
    switch (status) {
      case 'draft':
        return 'تم إنشاء الطلب';
      case 'analyzed':
        return 'تم التحليل';
      case 'awaiting_scope':
        return 'بانتظار تحديد النطاق';
      default:
        return status;
    }
  }
}
