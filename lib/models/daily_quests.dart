enum QuestType {
  completeSession,
  favoriteOne,
  usedVoice,
  enteredFocusMode,
  visitedFavorites;

  String get label {
    switch (this) {
      case QuestType.completeSession:
        return 'Complete today\'s session';
      case QuestType.favoriteOne:
        return 'Favorite an affirmation';
      case QuestType.usedVoice:
        return 'Listen with voice';
      case QuestType.enteredFocusMode:
        return 'Enter Focus Mode';
      case QuestType.visitedFavorites:
        return 'Visit your Favorites';
    }
  }

  String get emoji {
    switch (this) {
      case QuestType.completeSession:
        return '🧘';
      case QuestType.favoriteOne:
        return '❤️';
      case QuestType.usedVoice:
        return '🔊';
      case QuestType.enteredFocusMode:
        return '🎯';
      case QuestType.visitedFavorites:
        return '⭐';
    }
  }
}

class DailyQuests {
  final String? date; // yyyy-MM-dd
  final Set<QuestType> completed;
  final bool bonusPaid;

  const DailyQuests({
    this.date,
    this.completed = const {},
    this.bonusPaid = false,
  });

  bool get allComplete => completed.length == QuestType.values.length;
  bool isCompleted(QuestType t) => completed.contains(t);

  DailyQuests copyWith({
    String? date,
    Set<QuestType>? completed,
    bool? bonusPaid,
  }) =>
      DailyQuests(
        date: date ?? this.date,
        completed: completed ?? this.completed,
        bonusPaid: bonusPaid ?? this.bonusPaid,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'completed': completed.map((e) => e.name).toList(),
        'bonusPaid': bonusPaid,
      };

  factory DailyQuests.fromJson(Map<String, dynamic> json) => DailyQuests(
        date: json['date'] as String?,
        completed: ((json['completed'] as List<dynamic>?)
                    ?.map((e) => QuestType.values.firstWhere(
                          (t) => t.name == e as String,
                          orElse: () => QuestType.completeSession,
                        ))
                    .toSet()) ??
            {},
        bonusPaid: json['bonusPaid'] as bool? ?? false,
      );
}
