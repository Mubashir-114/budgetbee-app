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

  // Pre-seeded database categories
  static const List<CategoryModel> categories = [
    // Income Categories
    CategoryModel(id: 1, name: "Salary", type: "income"),
    CategoryModel(id: 2, name: "Freelancing", type: "income"),
    CategoryModel(id: 3, name: "Business", type: "income"),
    CategoryModel(id: 4, name: "Investment", type: "income"),
    CategoryModel(id: 5, name: "Bonus", type: "income"),
    CategoryModel(id: 6, name: "Gift", type: "income"),
    
    // Expense Categories
    CategoryModel(id: 7, name: "Food", type: "expense"),
    CategoryModel(id: 8, name: "Transport", type: "expense"),
    CategoryModel(id: 9, name: "Shopping", type: "expense"),
    CategoryModel(id: 10, name: "Medical", type: "expense"),
    CategoryModel(id: 11, name: "Education", type: "expense"),
    CategoryModel(id: 12, name: "Entertainment", type: "expense"),
    CategoryModel(id: 13, name: "Bills", type: "expense"),
    CategoryModel(id: 14, name: "Rent", type: "expense"),
    CategoryModel(id: 15, name: "Travel", type: "expense"),
    CategoryModel(id: 16, name: "Other", type: "expense"),
  ];

  static List<CategoryModel> getIncomeCategories() {
    return categories.where((c) => c.type == "income").toList();
  }

  static List<CategoryModel> getExpenseCategories() {
    return categories.where((c) => c.type == "expense").toList();
  }

  static String getNameById(int id) {
    final cat = categories.firstWhere((c) => c.id == id, orElse: () => const CategoryModel(id: 0, name: "Unknown", type: ""));
    return cat.name;
  }
}
