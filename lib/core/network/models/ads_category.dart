class AdsCategory {
  final int id;
  final String name;
  final String slug;
  final int? sortOrder;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const AdsCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.sortOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdsCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final sortOrder = json['sort_order'];
    final isActive = json['is_active'];

    return AdsCategory(
      id: id is int ? id : int.parse('$id'),
      name: (json['name'] as String? ?? '').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      sortOrder: sortOrder == null ? null : int.tryParse('$sortOrder'),
      isActive: isActive is bool
          ? isActive
          : '$isActive'.toLowerCase() == 'true' || '$isActive' == '1',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
