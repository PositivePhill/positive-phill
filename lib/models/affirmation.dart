class Affirmation {
  final String id;
  final String text;
  final List<AffirmationCategory> categories;

  const Affirmation({
    required this.id,
    required this.text,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'categories': categories.map((e) => e.name).toList(),
  };

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    final categoriesRaw = json['categories'] as List<dynamic>?;
    final categorySingle = json['category'] as String?;
    final List<AffirmationCategory> categories;
    if (categoriesRaw != null && categoriesRaw.isNotEmpty) {
      categories = categoriesRaw
          .map((e) => AffirmationCategory.values.firstWhere((cat) => cat.name == e as String))
          .toList();
    } else if (categorySingle != null) {
      categories = [
        AffirmationCategory.values.firstWhere((cat) => cat.name == categorySingle),
      ];
    } else {
      throw FormatException('Affirmation JSON must include categories or category: $json');
    }
    return Affirmation(
      id: json['id'] as String,
      text: json['text'] as String,
      categories: categories,
    );
  }
}

enum AffirmationCategory {
  confidence,
  calm,
  gratitude,
  discipline,
  healing,
  focus,
  social,
  money;

  String get displayName {
    switch (this) {
      case AffirmationCategory.confidence: return 'Confidence';
      case AffirmationCategory.calm: return 'Calm';
      case AffirmationCategory.gratitude: return 'Gratitude';
      case AffirmationCategory.discipline: return 'Discipline';
      case AffirmationCategory.healing: return 'Healing';
      case AffirmationCategory.focus: return 'Focus';
      case AffirmationCategory.social: return 'Social';
      case AffirmationCategory.money: return 'Money';
    }
  }

  String get emoji {
    switch (this) {
      case AffirmationCategory.confidence: return '💪';
      case AffirmationCategory.calm: return '🧘';
      case AffirmationCategory.gratitude: return '🙏';
      case AffirmationCategory.discipline: return '🎯';
      case AffirmationCategory.healing: return '💚';
      case AffirmationCategory.focus: return '🔥';
      case AffirmationCategory.social: return '🤝';
      case AffirmationCategory.money: return '💰';
    }
  }
}
