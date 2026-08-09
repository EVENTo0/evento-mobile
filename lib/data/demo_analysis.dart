class DemoAnalysisResult {
  const DemoAnalysisResult({
    required this.complexityAr,
    required this.complexityEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.scopeAr,
    required this.scopeEn,
    required this.risksAr,
    required this.risksEn,
    required this.nextAr,
    required this.nextEn,
  });

  final String complexityAr;
  final String complexityEn;
  final String summaryAr;
  final String summaryEn;
  final List<String> scopeAr;
  final List<String> scopeEn;
  final List<String> risksAr;
  final List<String> risksEn;
  final String nextAr;
  final String nextEn;
}

class DemoOrder {
  const DemoOrder({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.analysis,
    required this.createdAt,
    this.sourceProjectId,
  });

  final String id;
  final String type;
  final String title;
  final String details;
  final DemoAnalysisResult analysis;
  final DateTime createdAt;
  final String? sourceProjectId;
}

bool _containsAny(String text, Iterable<String> values) =>
    values.any((String value) => text.contains(value));

DemoAnalysisResult analyzeDemoIdea({
  required String type,
  required String title,
  required String details,
}) {
  final String text = '$title $details'.toLowerCase();

  final Map<String, List<String>> capabilitySignals = <String, List<String>>{
    'ai': <String>['ai', 'ذكاء', 'agent', 'وكيل', 'assistant', 'مساعد'],
    'payment': <String>['payment', 'دفع', 'stripe', 'tap', 'apple pay', 'اشتراك', 'subscription'],
    'auth': <String>['login', 'sign in', 'تسجيل', 'حساب', 'account', 'auth'],
    'admin': <String>['admin', 'لوحة', 'dashboard', 'إدارة'],
    'notification': <String>['notification', 'push', 'تنبيه', 'إشعار'],
    'marketplace': <String>['marketplace', 'متجر', 'سوق', 'catalog', 'كتالوج'],
    'maps': <String>['map', 'maps', 'خريطة', 'موقع جغرافي', 'gps'],
    'realtime': <String>['realtime', 'real-time', 'مباشر', 'لحظي'],
    'chat': <String>['chat', 'محادثة', 'رسائل', 'messaging', 'whatsapp'],
    'booking': <String>['booking', 'reservation', 'حجز', 'موعد'],
    'analytics': <String>['analytics', 'تحليلات', 'تقارير', 'reports', 'kpi'],
    'files': <String>['upload', 'attachment', 'ملف', 'مرفق', 'صور', 'image'],
    'offline': <String>['offline', 'دون اتصال', 'بدون انترنت'],
    'game': <String>['game', 'لعبة', 'multiplayer', 'vr', 'xr'],
  };

  final Set<String> detected = <String>{};
  for (final MapEntry<String, List<String>> entry in capabilitySignals.entries) {
    if (_containsAny(text, entry.value)) detected.add(entry.key);
  }

  final int detailScore = details.trim().length >= 350
      ? 3
      : details.trim().length >= 180
          ? 2
          : details.trim().length >= 80
              ? 1
              : 0;
  final int score = detected.length + detailScore + (type == 'Game' ? 2 : 0) + (type == 'AI' ? 1 : 0);

  final String complexityAr = score >= 8 ? 'عالٍ' : score >= 4 ? 'متقدم' : score >= 2 ? 'متوسط' : 'مبدئي';
  final String complexityEn = score >= 8 ? 'High' : score >= 4 ? 'Advanced' : score >= 2 ? 'Medium' : 'Starter';

  final List<String> scopeAr = <String>[];
  final List<String> scopeEn = <String>[];
  switch (type) {
    case 'Website':
      scopeAr.addAll(<String>['واجهة متجاوبة للويب', 'صفحات المنتج/الخدمة مع رحلة تحويل واضحة']);
      scopeEn.addAll(<String>['Responsive web experience', 'Product/service pages with a clear conversion journey']);
      break;
    case 'AI':
      scopeAr.addAll(<String>['واجهة للقدرة الذكية', 'تعريف المدخلات والمخرجات والضوابط وسجل التقييم']);
      scopeEn.addAll(<String>['AI capability experience', 'Defined inputs, outputs, guardrails, and evaluation history']);
      break;
    case 'Game':
      scopeAr.addAll(<String>['Vertical Slice قابل للعب', 'حلقة لعب أساسية مع تقدم وتحكم وقياس أداء']);
      scopeEn.addAll(<String>['Playable vertical slice', 'Core loop with progression, controls, and performance validation']);
      break;
    default:
      scopeAr.addAll(<String>['تطبيق Android وiOS من قاعدة واحدة', 'شاشات البداية والتنقل والرحلة الأساسية للعميل']);
      scopeEn.addAll(<String>['Android and iOS from one codebase', 'Core onboarding, navigation, and customer journey']);
  }

  void addCapability(String key, String ar, String en) {
    if (detected.contains(key) && !scopeAr.contains(ar)) {
      scopeAr.add(ar);
      scopeEn.add(en);
    }
  }

  addCapability('auth', 'حسابات مستخدمين وتسجيل دخول وصلاحيات', 'User accounts, authentication, and authorization');
  addCapability('payment', 'دفع واشتراكات ضمن مسار آمن بعد تثبيت النطاق', 'Payments/subscriptions through a secured flow after scope validation');
  addCapability('ai', 'تحليل/مساعد ذكي مع سجل نتائج وتقييمات', 'AI analysis/assistant with reviewable history and evaluations');
  addCapability('admin', 'لوحة إدارة وتشغيل للطلبات والمحتوى', 'Operations/admin dashboard for orders and content');
  addCapability('notification', 'إشعارات حالة الطلب والأحداث المهمة', 'Order-status and important-event notifications');
  addCapability('marketplace', 'كتالوج/متجر مع البحث والتصفية والتفاصيل', 'Catalog/marketplace with search, filters, and detail views');
  addCapability('maps', 'خرائط وموقع جغرافي مع أذونات واضحة', 'Maps/geolocation with explicit permissions');
  addCapability('realtime', 'تحديثات لحظية للحالات والبيانات الحساسة للزمن', 'Realtime updates for time-sensitive state');
  addCapability('chat', 'محادثات أو قناة تواصل مرتبطة بالطلب', 'Request-linked messaging or communication channel');
  addCapability('booking', 'حجوزات/مواعيد مع حالات وتأكيدات', 'Booking/appointments with state and confirmations');
  addCapability('analytics', 'تحليلات مؤشرات وقياس رحلة العميل', 'Analytics and customer-journey measurement');
  addCapability('files', 'رفع مرفقات مع ضوابط نوع/حجم وصلاحيات', 'Attachment uploads with type, size, and access controls');
  addCapability('offline', 'دعم Offline للحالات المناسبة مع مزامنة آمنة', 'Offline support where appropriate with safe synchronization');

  final List<String> risksAr = <String>[];
  final List<String> risksEn = <String>[];
  void addRisk(bool condition, String ar, String en) {
    if (condition) {
      risksAr.add(ar);
      risksEn.add(en);
    }
  }

  addRisk(detected.contains('payment'), 'الدفع يحتاج فصل أسرار الخادم والتحقق من webhooks وحالات الفشل.', 'Payments require server-side secrets, webhook verification, and failure-state handling.');
  addRisk(detected.contains('ai'), 'نتائج الذكاء الاصطناعي يجب أن تكون قابلة للتقييم والمراجعة ولا تُعامل كحقائق غير متحققة.', 'AI outputs need evaluation/review and must not be treated as unverified facts.');
  addRisk(detected.contains('auth'), 'بيانات العملاء تتطلب RLS وصلاحيات أقل امتيازًا وجلسات آمنة.', 'Customer data requires RLS, least privilege, and secure sessions.');
  addRisk(detected.contains('files'), 'المرفقات تحتاج سياسات تخزين وفحص امتدادات وأحجام الملفات.', 'Attachments need storage policies plus file type and size validation.');
  if (risksAr.isEmpty) {
    risksAr.add('أكبر خطر حالي هو توسيع النطاق قبل تثبيت رحلة العميل الأساسية ومعايير القبول.');
    risksEn.add('The main current risk is scope expansion before the core customer journey and acceptance criteria are fixed.');
  }

  final String summaryAr = 'الفكرة مناسبة لمرحلة MVP بدرجة تعقيد $complexityAr، وتم اكتشاف ${detected.length} قدرات إضافية محتملة. يبدأ التنفيذ برحلة العميل الأساسية ثم تُضاف التكاملات حسب المخاطر والأولوية.';
  final String summaryEn = 'The idea is suitable for an MVP with $complexityEn complexity, with ${detected.length} additional capabilities detected. Build the core customer journey first, then add integrations by risk and priority.';

  return DemoAnalysisResult(
    complexityAr: complexityAr,
    complexityEn: complexityEn,
    summaryAr: summaryAr,
    summaryEn: summaryEn,
    scopeAr: scopeAr,
    scopeEn: scopeEn,
    risksAr: risksAr,
    risksEn: risksEn,
    nextAr: 'الخطوة التالية: اعتماد المتطلبات ومعايير القبول والأولوية والميزانية، ثم تحويل التحليل إلى نطاق قابل للتسعير والتنفيذ.',
    nextEn: 'Next: approve requirements, acceptance criteria, priority, and budget, then convert the analysis into an implementation-ready scope and quote.',
  );
}

DemoOrder createDemoOrder({
  required String type,
  required String title,
  required String details,
  String? sourceProjectId,
  DateTime? now,
}) {
  final DateTime timestamp = now ?? DateTime.now();
  final String yy = (timestamp.year % 100).toString().padLeft(2, '0');
  final String mm = timestamp.month.toString().padLeft(2, '0');
  final String dd = timestamp.day.toString().padLeft(2, '0');
  final String suffix = (timestamp.microsecondsSinceEpoch % 100000).toString().padLeft(5, '0');
  return DemoOrder(
    id: 'EVT-$yy$mm$dd-$suffix',
    type: type,
    title: title.trim(),
    details: details.trim(),
    sourceProjectId: sourceProjectId,
    analysis: analyzeDemoIdea(type: type, title: title, details: details),
    createdAt: timestamp,
  );
}
