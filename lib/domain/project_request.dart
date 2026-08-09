enum ProjectRequestStatus {
  draft,
  analyzed,
  awaitingScope,
  quoted,
  approved,
  building,
  review,
  delivered,
  cancelled,
}

ProjectRequestStatus projectRequestStatusFromWire(String value) => switch (value) {
      'draft' => ProjectRequestStatus.draft,
      'analyzed' => ProjectRequestStatus.analyzed,
      'awaiting_scope' => ProjectRequestStatus.awaitingScope,
      'quoted' => ProjectRequestStatus.quoted,
      'approved' => ProjectRequestStatus.approved,
      'building' => ProjectRequestStatus.building,
      'review' => ProjectRequestStatus.review,
      'delivered' => ProjectRequestStatus.delivered,
      'cancelled' => ProjectRequestStatus.cancelled,
      _ => throw FormatException('Unknown project request status: $value'),
    };

class ProjectRequestRecord {
  const ProjectRequestRecord({
    required this.id,
    required this.requestCode,
    required this.type,
    required this.title,
    required this.details,
    required this.status,
    required this.createdAt,
    this.sourceProjectId,
  });

  factory ProjectRequestRecord.fromJson(Map<String, dynamic> json) => ProjectRequestRecord(
        id: json['id'] as String,
        requestCode: json['request_code'] as String,
        type: json['project_type'] as String,
        title: json['title'] as String,
        details: json['details'] as String,
        status: projectRequestStatusFromWire(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        sourceProjectId: json['source_project_id'] as String?,
      );

  final String id;
  final String requestCode;
  final String type;
  final String title;
  final String details;
  final ProjectRequestStatus status;
  final DateTime createdAt;
  final String? sourceProjectId;
}
