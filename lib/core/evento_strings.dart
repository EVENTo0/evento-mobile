class EventoStrings {
  const EventoStrings(this.arabic);

  final bool arabic;

  String get appName => 'EVENTO';
  String get tagline => arabic ? 'نحوّل فكرتك إلى منتج جاهز' : 'From idea to ready product';
  String get home => arabic ? 'الرئيسية' : 'Home';
  String get services => arabic ? 'الخدمات' : 'Services';
  String get projects => arabic ? 'المشاريع' : 'Projects';
  String get request => arabic ? 'اطلب' : 'Request';
  String get account => arabic ? 'حسابي' : 'Account';
  String get startProject => arabic ? 'ابدأ مشروعك' : 'Start your project';
  String get browseProjects => arabic ? 'استعرض كل المشاريع' : 'Browse all projects';
  String get featured => arabic ? 'مشاريع من منظومة EVENTO' : 'From the EVENTO portfolio';
  String get howItWorks => arabic ? 'كيف تعمل EVENTO' : 'How EVENTO works';
  String get serviceTitle => arabic ? 'ماذا نبني لك؟' : 'What can we build?';
  String get projectCatalog => arabic ? 'سجل المشاريع والمنتجات' : 'Project & product registry';
  String get requestTitle => arabic ? 'حلّل فكرتك' : 'Analyze your idea';
  String get myOrder => arabic ? 'طلباتي التجريبية' : 'Demo requests';
  String get language => arabic ? 'English' : 'العربية';
}
