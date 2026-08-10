class RequestAnalysisRecord {
  const RequestAnalysisRecord({
    required this.complexity,
    required this.summary,
    required this.proposedScope,
    required this.risks,
    required this.engineVersion,
    required this.updatedAt,
  });

  factory RequestAnalysisRecord.fromJson(Map<String, dynamic> json) => RequestAnalysisRecord(
        complexity: json['complexity'] as String,
        summary: json['summary'] as String,
        proposedScope: (json['proposed_scope'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        risks: (json['risks'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        engineVersion: json['engine_version'] as String? ?? 'unknown',
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  final String complexity;
  final String summary;
  final List<String> proposedScope;
  final List<String> risks;
  final String engineVersion;
  final DateTime updatedAt;
}

class RequestEventRecord {
  const RequestEventRecord({
    required this.status,
    required this.note,
    required this.createdAt,
  });

  factory RequestEventRecord.fromJson(Map<String, dynamic> json) => RequestEventRecord(
        status: json['status'] as String,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String status;
  final String note;
  final DateTime createdAt;
}
