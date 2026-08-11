class ProjectWorkflowRecord {
  const ProjectWorkflowRecord({
    required this.requestId,
    required this.currentStage,
    required this.progressPercent,
    required this.estimatedPriceAed,
    required this.scopeApprovedAt,
    required this.updatedAt,
  });

  factory ProjectWorkflowRecord.fromJson(Map<String, dynamic> json) =>
      ProjectWorkflowRecord(
        requestId: json['request_id'] as String,
        currentStage: json['current_stage'] as String? ?? 'analysis_complete',
        progressPercent: json['progress_percent'] as int? ?? 0,
        estimatedPriceAed: (json['estimated_price_aed'] as num?)?.toDouble(),
        scopeApprovedAt: json['scope_approved_at'] == null
            ? null
            : DateTime.parse(json['scope_approved_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  final String requestId;
  final String currentStage;
  final int progressPercent;
  final double? estimatedPriceAed;
  final DateTime? scopeApprovedAt;
  final DateTime updatedAt;

  String localizedStage(bool arabic) {
    if (!arabic) {
      switch (currentStage) {
        case 'analysis_complete':
          return 'Analysis complete';
        case 'scope_review':
          return 'Scope review';
        case 'scope_approved':
          return 'Scope approved';
        case 'quote_preparation':
        case 'quote_draft':
          return 'Quote preparation';
        case 'awaiting_quote_approval':
        case 'quote_sent':
          return 'Awaiting quote approval';
        case 'quote_approved':
          return 'Quote approved • contract next';
        case 'contract_sent':
          return 'Awaiting contract acceptance';
        case 'contract_approved':
          return 'Contract accepted • payment next';
        case 'payment_pending':
          return 'Payment pending';
        case 'payment_verified':
          return 'Payment verified • authorization pending';
        case 'build_queue':
          return 'Authorized build queue';
        case 'in_development':
          return 'In development';
        case 'testing':
          return 'Testing';
        case 'ready_to_deliver':
          return 'Ready to deliver';
        default:
          return currentStage;
      }
    }

    switch (currentStage) {
      case 'analysis_complete':
        return 'اكتمل التحليل';
      case 'scope_review':
        return 'مراجعة النطاق';
      case 'scope_approved':
        return 'تم اعتماد النطاق';
      case 'quote_preparation':
      case 'quote_draft':
        return 'إعداد عرض السعر';
      case 'awaiting_quote_approval':
      case 'quote_sent':
        return 'بانتظار اعتماد عرض السعر';
      case 'quote_approved':
        return 'تم اعتماد السعر • العقد هو التالي';
      case 'contract_sent':
        return 'بانتظار قبول العقد';
      case 'contract_approved':
        return 'تم قبول العقد • الدفع هو التالي';
      case 'payment_pending':
        return 'بانتظار الدفع';
      case 'payment_verified':
        return 'تم توثيق الدفع • بانتظار إذن التنفيذ';
      case 'build_queue':
        return 'قائمة البناء المصرّح بها';
      case 'in_development':
        return 'قيد التطوير';
      case 'testing':
        return 'قيد الاختبار';
      case 'ready_to_deliver':
        return 'جاهز للتسليم';
      default:
        return currentStage;
    }
  }
}
