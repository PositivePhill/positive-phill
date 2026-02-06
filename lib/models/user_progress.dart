class UserProgress {
  final int xp;
  final int level;
  final int streak;
  final DateTime? lastOpenDate;
  final DateTime? lastPackDate;
  final int extraPacksToday;
  final List<String> favorites;

  const UserProgress({
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lastOpenDate,
    this.lastPackDate,
    this.extraPacksToday = 0,
    this.favorites = const [],
  });

  int get xpForNextLevel => level * 200;
  double get progressToNextLevel => xp % 200 / 200;
  
  UserProgress copyWith({
    int? xp,
    int? level,
    int? streak,
    DateTime? lastOpenDate,
    DateTime? lastPackDate,
    int? extraPacksToday,
    List<String>? favorites,
  }) => UserProgress(
    xp: xp ?? this.xp,
    level: level ?? this.level,
    streak: streak ?? this.streak,
    lastOpenDate: lastOpenDate ?? this.lastOpenDate,
    lastPackDate: lastPackDate ?? this.lastPackDate,
    extraPacksToday: extraPacksToday ?? this.extraPacksToday,
    favorites: favorites ?? this.favorites,
  );

  Map<String, dynamic> toJson() => {
    'xp': xp,
    'level': level,
    'streak': streak,
    'lastOpenDate': lastOpenDate?.toIso8601String(),
    'lastPackDate': lastPackDate?.toIso8601String(),
    'extraPacksToday': extraPacksToday,
    'favorites': favorites,
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    xp: json['xp'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    streak: json['streak'] as int? ?? 0,
    lastOpenDate: json['lastOpenDate'] != null 
        ? DateTime.parse(json['lastOpenDate'] as String)
        : null,
    lastPackDate: json['lastPackDate'] != null
        ? DateTime.parse(json['lastPackDate'] as String)
        : null,
    extraPacksToday: json['extraPacksToday'] as int? ?? 0,
    favorites: (json['favorites'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  );
}
