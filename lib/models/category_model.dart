class CategoryModel {
  final int id;
  final String name;
  final String type; // "income" or "expense"

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"] as int,
      name: json["name"] as String,
      type: json["type"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type,
    };
  }

  // Pre-seeded database categories (synced with MySQL categories table)
  static const List<CategoryModel> categories = [
    // Income Categories
    CategoryModel(id: 1, name: "Salary", type: "income"),
    CategoryModel(id: 2, name: "Other Income", type: "income"),

    // Expense Categories
    CategoryModel(id: 3, name: "Food", type: "expense"),
    CategoryModel(id: 4, name: "Transport", type: "expense"),
    CategoryModel(id: 5, name: "Housing", type: "expense"),
    CategoryModel(id: 6, name: "Utilities", type: "expense"),
    CategoryModel(id: 7, name: "Healthcare", type: "expense"),
    CategoryModel(id: 8, name: "Entertainment", type: "expense"),
    CategoryModel(id: 9, name: "Shopping", type: "expense"),
    CategoryModel(id: 10, name: "Education", type: "expense"),
    CategoryModel(id: 11, name: "Travel", type: "expense"),
    CategoryModel(id: 12, name: "Other Expense", type: "expense"),
  ];

  static List<CategoryModel> getIncomeCategories() {
    return categories.where((c) => c.type == "income").toList();
  }

  static List<CategoryModel> getExpenseCategories() {
    return categories.where((c) => c.type == "expense").toList();
  }

  static String getNameById(int id) {
    final cat = categories.firstWhere(
      (c) => c.id == id,
      orElse: () => const CategoryModel(id: 0, name: "Unknown", type: ""),
    );
    return cat.name;
  }

  static CategoryModel? findById(int? id) {
    if (id == null) return null;
    return categories.where((c) => c.id == id).firstOrNull;
  }

  static CategoryModel? findByName(String? name, {String? type}) {
    if (name == null || name.trim().isEmpty) return null;
    final lower = name.toLowerCase().trim();
    return categories.where((c) {
      final matches = c.name.toLowerCase() == lower;
      return type != null ? matches && c.type == type : matches;
    }).firstOrNull;
  }
}
