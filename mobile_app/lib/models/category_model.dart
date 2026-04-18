class Category {
  final String id;
  final String name;
  final String icon;
  final String type;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      type: json['type'] ?? 'expense',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'icon': icon,
      'type': type,
      'isDefault': isDefault,
    };
  }
}
