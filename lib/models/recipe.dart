/// Lightweight recipe model for recipe suggestions and matching.
class Recipe {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final double rating;
  final String prepTime;
  final String calories;
  final String type;
  final List<String> ingredients;
  final List<String> missingIngredients;

  const Recipe({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl,
    this.rating = 0.0,
    this.prepTime = '',
    this.calories = '',
    this.type = '',
    this.ingredients = const [],
    this.missingIngredients = const [],
  });

  // ── Computed ─────────────────────────────────────────────────────

  /// Whether the user has all ingredients for this recipe.
  bool get hasAllIngredients => missingIngredients.isEmpty;

  /// Match percentage: how many ingredients are available.
  double get matchPercentage {
    if (ingredients.isEmpty) return 1.0;
    final available = ingredients.length - missingIngredients.length;
    return available / ingredients.length;
  }

  // ── Serialization ────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'prepTime': prepTime,
      'calories': calories,
      'type': type,
      'ingredients': ingredients,
      'missingIngredients': missingIngredients,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      prepTime: map['prepTime'] as String? ?? '',
      calories: map['calories'] as String? ?? '',
      type: map['type'] as String? ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      missingIngredients: List<String>.from(map['missingIngredients'] ?? []),
    );
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? rating,
    String? prepTime,
    String? calories,
    String? type,
    List<String>? ingredients,
    List<String>? missingIngredients,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      prepTime: prepTime ?? this.prepTime,
      calories: calories ?? this.calories,
      type: type ?? this.type,
      ingredients: ingredients ?? this.ingredients,
      missingIngredients: missingIngredients ?? this.missingIngredients,
    );
  }

  @override
  String toString() =>
      'Recipe(id: $id, title: $title, match: ${(matchPercentage * 100).round()}%)';
}
