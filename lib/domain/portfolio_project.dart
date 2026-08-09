class PortfolioProject {
  const PortfolioProject({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.category,
    required this.status,
    required this.availability,
    required this.summaryEn,
    required this.summaryAr,
    required this.tags,
    this.aliases = const <String>[],
  });

  final String id;
  final String name;
  final String nameAr;
  final String category;
  final String status;
  final String availability;
  final String summaryEn;
  final String summaryAr;
  final List<String> tags;
  final List<String> aliases;

  String label(bool arabic) => arabic ? nameAr : name;
  String summary(bool arabic) => arabic ? summaryAr : summaryEn;

  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String>[name, nameAr, category, status, availability, ...tags, ...aliases]
        .join(' ')
        .toLowerCase()
        .contains(q);
  }
}
